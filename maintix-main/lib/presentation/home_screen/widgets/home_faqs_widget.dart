import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class HomeFaqsWidget extends StatefulWidget {
  const HomeFaqsWidget({super.key});

  @override
  State<HomeFaqsWidget> createState() => _HomeFaqsWidgetState();
}

class _HomeFaqsWidgetState extends State<HomeFaqsWidget> {
  // TODO: Replace with Riverpod/Bloc for production
  int? _expandedIndex;

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How often should I clean my water tank?',
      'a':
          'We recommend cleaning your water tank at least once every 6 months. In Satna\'s climate, twice a year ensures safe, clean water for your family.',
    },
    {
      'q': 'How long does the cleaning process take?',
      'a':
          'A standard 1000L tank takes approximately 2–3 hours. Larger tanks (1500L–2000L) may take 3–4 hours. Our technician will confirm the time estimate before starting.',
    },
    {
      'q': 'Is the antibacterial spray safe for drinking water?',
      'a':
          'Yes, absolutely. We use WHO-approved, food-grade antibacterial spray that is completely safe for drinking water after a 30-minute settling period.',
    },
    {
      'q': 'Do I need to be present during the cleaning?',
      'a':
          'We recommend being present or having a trusted adult at home. Our technician will call 30 minutes before arrival to confirm.',
    },
    {
      'q': 'What areas in Satna do you service?',
      'a':
          'We service all areas in Satna, MP including Civil Lines, Gandhi Nagar, Bharhut Nagar, Prem Nagar, Rewa Road, and all surrounding colonies.',
    },
    {
      'q': 'Do you provide a cleaning certificate?',
      'a':
          'Yes! We provide a TDS-tested cleaning certificate after every service. This includes before/after TDS readings for your records.',
    },
  ];

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
            'Frequently Asked Questions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Everything you need to know',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(_faqs.length, (index) {
            final faq = _faqs[index];
            final isExpanded = _expandedIndex == index;
            return Column(
              children: [
                InkWell(
                  onTap: () => setState(
                    () => _expandedIndex = isExpanded ? null : index,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppTheme.tealLight
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            faq['q']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isExpanded
                                  ? AppTheme.tealAccent
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: isExpanded
                              ? AppTheme.tealAccent
                              : AppTheme.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Text(
                      faq['a']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                if (index < _faqs.length - 1)
                  Divider(height: 12, color: AppTheme.divider),
              ],
            );
          }),
        ],
      ),
    );
  }
}
