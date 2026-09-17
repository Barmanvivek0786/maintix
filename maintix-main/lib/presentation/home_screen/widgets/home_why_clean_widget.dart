import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class HomeWhyCleanWidget extends StatelessWidget {
  const HomeWhyCleanWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Tank Cleaning Matters',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('❌ Dirty Water Risks', AppTheme.error),
                    const SizedBox(height: 8),
                    _riskItem(
                      'Hair Fall & Scalp Damage from minerals & bacteria',
                    ),
                    _riskItem('Skin Allergies & Rashes from dirty water'),
                    _riskItem('Typhoid, Jaundice & stomach illness risk'),
                    _riskItem('Bad Odor & white limescale on taps'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('✓ Clean Water Benefits', AppTheme.success),
                    const SizedBox(height: 8),
                    _benefitItem('Healthy Hair & Skin with purified water'),
                    _benefitItem('100% Safe Drinking Water, bacteria-free'),
                    _benefitItem('Extended Plumbing Life, no clogging'),
                    _benefitItem('Fresh taste & zero foul odor'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _riskItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(Icons.circle, color: AppTheme.error, size: 6),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(Icons.circle, color: AppTheme.success, size: 6),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
