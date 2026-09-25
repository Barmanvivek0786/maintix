import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/premium_ui.dart';

class ReviewsStatsWidget extends StatelessWidget {
  const ReviewsStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryNavy,
            const Color(0xFF0A5A8A),
            AppGradients.teal.withOpacity(0.14),
          ],
          stops: const [0.0, 0.65, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppGradients.teal.withOpacity(0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
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
    final color = iconColor ?? AppTheme.tealAccent;
    return Expanded(
      child: TapScale(
        onTap: () {},
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.14),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 10),
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
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
