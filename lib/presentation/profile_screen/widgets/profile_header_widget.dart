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
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialLetterAvatar(appState),
            errorWidget: (_, __, ___) => _initialLetterAvatar(appState),
          ),
        );
      } else if (!kIsWeb) {
        return ClipOval(
          child: Image.file(
            File(effectiveUrl),
            width: 72,
            height: 72,
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
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: AppTheme.tealAccent,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF1A3F5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(77),
                    width: 3,
                  ),
                ),
                child: _buildAvatar(appState),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.editProfileScreen),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.tealAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            appState.userName.isNotEmpty ? appState.userName : 'Maintix User',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appState.userEmail,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withAlpha(166),
            ),
          ),
          if (appState.userPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              appState.userPhone,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white.withAlpha(166),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (appState.userCity.isNotEmpty)
            GestureDetector(
              onTap: () => context.push(AppRoutes.editProfileScreen),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.tealLight.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.tealAccent.withAlpha(102)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.tealAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appState.userCity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          // Edit Profile button
          GestureDetector(
            onTap: () => context.push(AppRoutes.editProfileScreen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(77)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
