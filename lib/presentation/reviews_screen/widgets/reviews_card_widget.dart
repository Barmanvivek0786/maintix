import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/premium_ui.dart';

class ReviewCardWidget extends StatelessWidget {
  final String name;
  final String location;
  final String timeAgo;
  final int rating;
  final String review;
  final String tag;
  final Color avatarColor;
  final String initials;
  final String? photoUrl;

  const ReviewCardWidget({
    required this.name,
    required this.location,
    required this.timeAgo,
    required this.rating,
    required this.review,
    required this.tag,
    required this.avatarColor,
    required this.initials,
    this.photoUrl,
    super.key,
  });

  Widget _buildAvatar() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final bool isNetwork =
          photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://');
      if (isNetwork) {
        return ClipOval(
          child: Image.network(
            photoUrl!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsAvatar(),
          ),
        );
      } else if (!kIsWeb) {
        return ClipOval(
          child: Image.file(
            File(photoUrl!),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsAvatar(),
          ),
        );
      }
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [avatarColor, avatarColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: avatarColor.withOpacity(0.35), blurRadius: 10),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceWhite,
              avatarColor.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border(
            left: BorderSide(color: avatarColor.withOpacity(0.65), width: 3.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '✓ Verified',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.textMuted,
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            location,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppTheme.warning,
                          size: 14,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              review,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.tealLight,
                    AppGradients.teal.withOpacity(0.14),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    color: AppTheme.tealAccent,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      color: AppTheme.tealAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
