import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class HomeBeforeAfterWidget extends StatefulWidget {
  const HomeBeforeAfterWidget({super.key});

  @override
  State<HomeBeforeAfterWidget> createState() => _HomeBeforeAfterWidgetState();
}

class _HomeBeforeAfterWidgetState extends State<HomeBeforeAfterWidget> {
  // TODO: Replace with Riverpod/Bloc for production
  double _dividerPosition = 0.5;
  bool _showAfter = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Before & After',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '500L Overhead Plastic Tank Cleaning',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showAfter = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: !_showAfter
                                ? AppTheme.error
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Before',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: !_showAfter
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showAfter = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _showAfter
                                ? AppTheme.success
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'After',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _showAfter
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Image comparison
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  // Before image (full) — now shows the CLEAN tank as the base layer
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/Gemini_Generated_Image_8ofg7n8ofg7n8ofg-1787560639197.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1A5C8A),
                        child: Center(
                          child: Text(
                            'BEFORE\n(Dirty Tank)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // After image (clipped) — now shows the DIRTY tank revealed by slider
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 50),
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width:
                        MediaQuery.of(context).size.width *
                        _dividerPosition *
                        0.85,
                    child: ClipRect(
                      child: Image.asset(
                        'assets/images/Gemini_Generated_Image_1zsd1d1zsd1d1zsd-1787560646330.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 220,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF8B4513),
                          child: Center(
                            child: Text(
                              'AFTER\n(Clean Tank)',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Divider handle
                  Positioned(
                    left:
                        (MediaQuery.of(context).size.width *
                            _dividerPosition *
                            0.85) -
                        20,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final box = context.findRenderObject() as RenderBox;
                        final localPos = box.globalToLocal(
                          details.globalPosition,
                        );
                        setState(() {
                          _dividerPosition =
                              (localPos.dx / (box.size.width * 0.85)).clamp(
                                0.05,
                                0.95,
                              );
                        });
                      },
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.compare_arrows_rounded,
                            color: AppTheme.primaryNavy,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Labels
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(217),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BEFORE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(217),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AFTER ✨',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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
