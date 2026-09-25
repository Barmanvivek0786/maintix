import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/premium_ui.dart';

class HomeHeroBannerWidget extends StatelessWidget {
  const HomeHeroBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 184,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppGradients.teal.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withOpacity(0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppGradients.teal.withOpacity(0.1),
            blurRadius: 36,
          ),
        ],
        gradient: LinearGradient(
          colors: [AppTheme.primaryNavy, const Color(0xFF0A5A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background image
            Image.asset(
              'assets/images/Gemini_Generated_Image_8ofg7n8ofg7n8ofg-1787560639197.png',
              width: double.infinity,
              height: 184,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryNavy, const Color(0xFF0A5A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Multi-stop gradient overlay with a subtle glow
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryNavy.withOpacity(0.92),
                    AppTheme.primaryNavy.withOpacity(0.55),
                    AppGradients.teal.withOpacity(0.12),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.tealAccent, AppGradients.cyan],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppGradients.teal.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      '🛡️ TDS Tested & Certified',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Professional Tank\nCleaning — Satna',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                      color: Colors.white,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '500L Overhead Plastic Tank Cleaning',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Starting ₹1,000',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.tealAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• 5-Stage Clean',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withAlpha(179),
                        ),
                      ),
                    ],
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
