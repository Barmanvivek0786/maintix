import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/premium_ui.dart';

class HomePriceChipsWidget extends StatefulWidget {
  const HomePriceChipsWidget({super.key});

  @override
  State<HomePriceChipsWidget> createState() => _HomePriceChipsWidgetState();
}

class _HomePriceChipsWidgetState extends State<HomePriceChipsWidget> {
  // TODO: Replace with Riverpod/Bloc for production
  int _selectedIndex = 2; // 1000L highlighted by default

  final List<Map<String, dynamic>> _pricingData = [
    {'size': '500L', 'price': 1000},
    {'size': '750L', 'price': 1500},
    {'size': '1000L', 'price': 1800},
    {'size': '1500L', 'price': 2000},
    {'size': '2000L', 'price': 2500},
  ];

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '₹${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)},${price % 1000 == 0 ? '000' : (price % 1000).toString().padLeft(3, '0')}';
    }
    return '₹$price';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppGradients.teal.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.price_check_rounded,
                color: AppTheme.tealAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Price Check',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select your tank size to see pricing',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_pricingData.length, (index) {
                final item = _pricingData[index];
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _pricingData.length - 1 ? 10 : 0,
                  ),
                  child: TapScale(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppTheme.primaryNavy,
                                  AppGradients.midnight2,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : AppTheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppGradients.teal.withOpacity(0.5)
                              : AppTheme.divider,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppGradients.teal.withOpacity(0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            item['size'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatPrice(item['price']),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.tealAccent
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          TapScale(
            onTap: () => context.go(AppRoutes.bookingScreen),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.tealAccent, AppGradients.cyan],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppGradients.teal.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Book Now — ${_formatPrice(_pricingData[_selectedIndex]['price'])}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
