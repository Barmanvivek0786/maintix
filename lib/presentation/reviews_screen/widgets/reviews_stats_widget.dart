import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ReviewsStatsWidget extends StatelessWidget {
  const ReviewsStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF0A5A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatItem(
            value: '500+',
            label: 'Happy\nCustomers',
            icon: Icons.people_rounded,
          ),
          _Divider(),
          _StatItem(
            value: '5.0',
            label: 'Avg\nRating',
            icon: Icons.star_rounded,
            iconColor: AppTheme.warning,
          ),
          _Divider(),
          _StatItem(
            value: '100%',
            label: 'Satisfaction\nRate',
            icon: Icons.verified_rounded,
            iconColor: AppTheme.success,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? AppTheme.tealAccent, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withAlpha(166),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: Colors.white.withAlpha(38),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
