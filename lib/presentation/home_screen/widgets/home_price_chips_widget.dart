import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';

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
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_pricingData.length, (index) {
                final item = _pricingData[index];
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _pricingData.length - 1 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryNavy
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryNavy
                              : AppTheme.divider,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            item['size'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.bookingScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealAccent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Book Now — ${_formatPrice(_pricingData[_selectedIndex]['price'])}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
