import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class BookingProgressWidget extends StatelessWidget {
  final int currentStep;

  const BookingProgressWidget({required this.currentStep, super.key});

  static const List<String> _labels = [
    'Size',
    'Date',
    'Address',
    'Billing',
    'Pay',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryNavy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final isDone = index < currentStep;
          final isActive = index == currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isActive ? 32 : 24,
                        height: isActive ? 32 : 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppTheme.success
                              : isActive
                              ? AppTheme.tealAccent
                              : Colors.white.withAlpha(38),
                          border: Border.all(
                            color: isDone
                                ? AppTheme.success
                                : isActive
                                ? AppTheme.tealAccent
                                : Colors.white.withAlpha(51),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isActive ? 13 : 11,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withAlpha(128),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _labels[index],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? AppTheme.tealAccent
                              : isDone
                              ? Colors.white.withAlpha(179)
                              : Colors.white.withAlpha(89),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < _labels.length - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2,
                      decoration: BoxDecoration(
                        color: index < currentStep
                            ? AppTheme.success
                            : Colors.white.withAlpha(38),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
