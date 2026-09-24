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

  static const double _avatarSize = 92;

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
            fontSize: 38,
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
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.tealAccent, Color(0xFF9BE7F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.tealAccent.withAlpha(90),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
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

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.tealAccent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(220),
              ),
            ),
          ),
        ],
      ),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.tealAccent.withAlpha(51),
                    borderRadius: BorderRadius.circular(11),
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
                          letterSpacing: 1.2,
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
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryNavy, AppTheme.headerAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(46),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -50, top: -50, child: _decorCircle(180, 12)),
          Positioned(left: -60, bottom: -70, child: _decorCircle(170, 8)),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 24),
            child: Column(
              children: [
                _buildAvatarWithBadge(context, appState),
                const SizedBox(height: 16),
                Text(
                  appState.userName.isNotEmpty
                      ? appState.userName
                      : 'Maintix User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.tealAccent.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: AppTheme.tealAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'MAINTIX MEMBER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppTheme.tealAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (appState.userEmail.isNotEmpty)
                  _pill(Icons.mail_rounded, appState.userEmail),
                if (appState.userPhone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _pill(Icons.phone_rounded, appState.userPhone),
                ],
                const SizedBox(height: 20),
                if (appState.userCity.isNotEmpty) ...[
                  _buildLocationTile(context, appState),
                  const SizedBox(height: 14),
                ],
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [AppTheme.tealAccent, Color(0xFF0088A8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.tealAccent.withAlpha(90),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.push(AppRoutes.editProfileScreen),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
