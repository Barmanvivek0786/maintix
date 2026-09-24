import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import '../../../routes/app_routes.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key});

  static const double _avatarSize = 88;

  Widget _buildAvatar(AppState appState) {
    final effectiveUrl = appState.effectiveProfileImageUrl;

    if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      final bool isNetworkUrl =
          effectiveUrl.startsWith('http://') ||
          effectiveUrl.startsWith('https://') ||
          effectiveUrl.startsWith('blob:');

      if (isNetworkUrl) {
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: effectiveUrl,
            width: _avatarSize,
            height: _avatarSize,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialLetterAvatar(appState),
            errorWidget: (_, __, ___) => _initialLetterAvatar(appState),
          ),
        );
      } else if (!kIsWeb) {
        return ClipOval(
          child: Image.file(
            File(effectiveUrl),
            width: _avatarSize,
            height: _avatarSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialLetterAvatar(appState),
          ),
        );
      }
    }

    return _initialLetterAvatar(appState);
  }

  Widget _initialLetterAvatar(AppState appState) {
    final initial = appState.userName.isNotEmpty
        ? appState.userName[0].toUpperCase()
        : (appState.userEmail.isNotEmpty
              ? appState.userEmail[0].toUpperCase()
              : 'M');
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.tealAccent, Color(0xFF0088A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _decorCircle(double size, int alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(alpha),
      ),
    );
  }

  Widget _buildAvatarWithBadge(BuildContext context, AppState appState) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient ring
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTheme.tealAccent, Color(0xFF9BE7F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryNavy,
            ),
            child: _buildAvatar(appState),
          ),
        ),
        // Edit badge
        Positioned(
          bottom: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.editProfileScreen),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryNavy, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppTheme.tealAccent,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTile(BuildContext context, AppState appState) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white.withAlpha(20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withAlpha(36)),
        ),
        child: InkWell(
          onTap: () => context.push(AppRoutes.editProfileScreen),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.tealAccent.withAlpha(51),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.tealAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SERVICE LOCATION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Colors.white.withAlpha(140),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        appState.userCity,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withAlpha(150),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF1A3F5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Subtle decorative circles for a premium feel
          Positioned(right: -40, top: -40, child: _decorCircle(160, 12)),
          Positioned(left: -50, bottom: -60, child: _decorCircle(150, 8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                _buildAvatarWithBadge(context, appState),
                const SizedBox(height: 14),
                Text(
                  appState.userName.isNotEmpty
                      ? appState.userName
                      : 'Maintix User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appState.userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withAlpha(166),
                  ),
                ),
                if (appState.userPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 12,
                        color: Colors.white.withAlpha(140),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        appState.userPhone,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withAlpha(166),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                if (appState.userCity.isNotEmpty) ...[
                  _buildLocationTile(context, appState),
                  const SizedBox(height: 12),
                ],
                // Edit Profile button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.editProfileScreen),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'Edit Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryNavy,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
