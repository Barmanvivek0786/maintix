import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class HomeCleaningProcessWidget extends StatelessWidget {
  const HomeCleaningProcessWidget({super.key});

  static const List<Map<String, String>> _steps = [
    {
      'step': 'STEP 01',
      'title': 'Complete Draining',
      'desc':
          'Full water drainage using submersible pump to empty the tank completely.',
      'icon': 'water_drop',
    },
    {
      'step': 'STEP 02',
      'title': 'Sludge Extraction',
      'desc':
          'Manual removal of accumulated sludge, sediment, and debris from tank floor.',
      'icon': 'cleaning_services',
    },
    {
      'step': 'STEP 03',
      'title': 'High-Pressure Washing',
      'desc':
          'Industrial-grade high-pressure jet wash to remove stubborn stains and biofilm.',
      'icon': 'shower',
    },
    {
      'step': 'STEP 04',
      'title': 'Vacuum Cleaning',
      'desc':
          'Industrial vacuum extraction of all loosened particles and dirty water.',
      'icon': 'air',
    },
    {
      'step': 'STEP 05',
      'title': 'Antibacterial Spray',
      'desc':
          'WHO-approved food-grade antibacterial spray applied on all inner surfaces.',
      'icon': 'verified_user',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Cleaning Process',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '5-Stage professional tank cleaning',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withAlpha(153),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isLast = index == _steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.tealAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.tealAccent.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: AppTheme.tealAccent.withAlpha(77),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['step']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.tealAccent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['title']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step['desc']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withAlpha(166),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
