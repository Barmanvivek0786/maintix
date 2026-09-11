import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum BadgeStatus {
  confirmed,
  completed,
  cancelled,
  pending,
  verified,
  inProgress,
}

class StatusBadgeWidget extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;

  const StatusBadgeWidget({required this.status, this.customLabel, super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case BadgeStatus.confirmed:
        bg = AppTheme.tealAccent.withAlpha(31);
        text = AppTheme.tealAccent;
        label = 'Confirmed';
        break;
      case BadgeStatus.completed:
        bg = AppTheme.success.withAlpha(31);
        text = AppTheme.success;
        label = 'Completed';
        break;
      case BadgeStatus.cancelled:
        bg = AppTheme.error.withAlpha(31);
        text = AppTheme.error;
        label = 'Cancelled';
        break;
      case BadgeStatus.pending:
        bg = AppTheme.warning.withAlpha(31);
        text = AppTheme.warning;
        label = 'Pending';
        break;
      case BadgeStatus.verified:
        bg = AppTheme.success.withAlpha(31);
        text = AppTheme.success;
        label = '✓ Verified';
        break;
      case BadgeStatus.inProgress:
        bg = AppTheme.warning.withAlpha(31);
        text = AppTheme.warning;
        label = 'In Progress';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        customLabel ?? label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
