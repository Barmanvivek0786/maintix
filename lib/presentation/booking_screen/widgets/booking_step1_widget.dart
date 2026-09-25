import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import '../../../widgets/premium_ui.dart';

class BookingStep1Widget extends StatefulWidget {
  final VoidCallback onNext;
  const BookingStep1Widget({required this.onNext, super.key});

  @override
  State<BookingStep1Widget> createState() => _BookingStep1WidgetState();
}

class _BookingStep1WidgetState extends State<BookingStep1Widget> {
  // TODO: Replace with Riverpod/Bloc for production

  static const Map<String, int> _prices = {
    '500L': 1000,
    '750L': 1500,
    '1000L': 1800,
    '1500L': 2000,
    '2000L': 2500,
  };

  final Map<String, int> _quantities = {
    '500L': 0,
    '750L': 0,
    '1000L': 0,
    '1500L': 0,
    '2000L': 0,
  };

  int get _totalTanks => _quantities.values.fold(0, (sum, qty) => sum + qty);

  int get _subtotal {
    int total = 0;
    _quantities.forEach((size, qty) {
      total += (_prices[size] ?? 0) * qty;
    });
    return total;
  }

  bool get _bulkDiscount => _totalTanks >= 3;

  int get _finalTotal => _bulkDiscount ? _subtotal - 500 : _subtotal;

  String _formatPrice(int price) {
    final str = price.toString();
    if (str.length > 3) {
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$str';
  }

  void _updateQuantity(String size, int delta) {
    setState(() {
      _quantities[size] = (_quantities[size]! + delta).clamp(0, 10);
    });
    context.read<AppState>().updateCartTank(size, _quantities[size]!);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Tank Size & Quantity',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You can select multiple tank sizes',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ..._prices.entries.map((entry) {
            final size = entry.key;
            final price = entry.value;
            final qty = _quantities[size]!;
            final isSelected = qty > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppTheme.surfaceWhite,
                            AppGradients.teal.withOpacity(0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppGradients.teal.withOpacity(0.7)
                        : AppTheme.divider,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppGradients.teal.withOpacity(0.25)
                          : AppTheme.cardShadow,
                      blurRadius: isSelected ? 18 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [AppTheme.tealAccent, AppGradients.cyan],
                              )
                            : null,
                        color: isSelected ? null : AppTheme.background,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppGradients.teal.withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            color: isSelected ? Colors.white : AppTheme.textMuted,
                            size: 18,
                          ),
                          Text(
                            size,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$size Tank Cleaning',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPrice(price),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tealAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Counter
                    Row(
                      children: [
                        _CounterButton(
                          icon: Icons.remove_rounded,
                          onTap: qty > 0
                              ? () => _updateQuantity(size, -1)
                              : null,
                        ),
                        SizedBox(
                          width: 36,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: Text(
                                '$qty',
                                key: ValueKey(qty),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: qty > 0
                                      ? AppTheme.tealAccent
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _CounterButton(
                          icon: Icons.add_rounded,
                          onTap: () => _updateQuantity(size, 1),
                          isAdd: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          if (_bulkDiscount) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(20),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.success.withAlpha(77)),
              ),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Discount Applied!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                        Text(
                          '$_totalTanks tanks selected — Bulk Discount -₹500',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-₹500',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Subtotal
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryNavy,
                  AppGradients.midnight2,
                  AppGradients.teal.withOpacity(0.1),
                ],
                stops: const [0.0, 0.65, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryNavy.withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_totalTanks > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal ($_totalTanks tank${_totalTanks > 1 ? 's' : ''})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withAlpha(179),
                        ),
                      ),
                      Text(
                        _formatPrice(_subtotal),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                  if (_bulkDiscount) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bulk Discount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.success,
                          ),
                        ),
                        Text(
                          '-₹500',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(color: Colors.white24, height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _totalTanks > 0 ? _formatPrice(_finalTotal) : '₹0',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.tealAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          TapScale(
            onTap: _totalTanks > 0 ? widget.onNext : () {},
            child: Container(
              width: double.infinity,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _totalTanks > 0
                    ? LinearGradient(colors: [AppTheme.tealAccent, AppGradients.cyan])
                    : null,
                color: _totalTanks > 0 ? null : AppTheme.divider,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _totalTanks > 0
                    ? [
                        BoxShadow(
                          color: AppGradients.teal.withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next — Select Date & Time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: _totalTanks > 0 ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: _totalTanks > 0 ? Colors.white : AppTheme.textMuted,
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

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isAdd;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap ?? () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: onTap != null && isAdd
              ? LinearGradient(colors: [AppTheme.tealAccent, AppGradients.cyan])
              : null,
          color: onTap != null
              ? (isAdd ? null : AppTheme.primaryNavy)
              : AppTheme.divider,
          borderRadius: BorderRadius.circular(10),
          boxShadow: onTap != null && isAdd
              ? [
                  BoxShadow(
                    color: AppGradients.teal.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
