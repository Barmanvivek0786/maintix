import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import '../../../widgets/premium_ui.dart';

class ProfileStatsWidget extends StatefulWidget {
  const ProfileStatsWidget({super.key});

  @override
  State<ProfileStatsWidget> createState() => _ProfileStatsWidgetState();
}

class _ProfileStatsWidgetState extends State<ProfileStatsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshProfileStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bookingsCount = appState.totalBookingsCount;
    final coinBalance = appState.coinBalance;
    final avgRating = appState.avgRating;
    final ratingStr = avgRating > 0 ? avgRating.toStringAsFixed(1) : '—';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppGradients.teal.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            value: '$bookingsCount',
            label: 'Bookings',
            icon: Icons.calendar_today_rounded,
            color: AppTheme.tealAccent,
          ),
          _Divider(),
          _StatItem(
            value: '$coinBalance',
            label: 'Coins',
            icon: Icons.monetization_on_rounded,
            color: AppTheme.warning,
          ),
          _Divider(),
          _StatItem(
            value: ratingStr,
            label: 'Rating',
            icon: Icons.star_rounded,
            color: AppTheme.warning,
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
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TapScale(
        onTap: () {},
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.18), blurRadius: 12),
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                letterSpacing: 0.2,
                color: AppTheme.textSecondary,
              ),
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
      height: 52,
      color: AppTheme.divider,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
