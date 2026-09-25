import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';

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
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.tealAccent : AppTheme.divider,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppTheme.tealAccent.withAlpha(26)
                          : AppTheme.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.tealLight
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            color: isSelected
                                ? AppTheme.tealAccent
                                : AppTheme.textMuted,
                            size: 18,
                          ),
                          Text(
                            size,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.tealAccent
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$size Tank Cleaning',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 36,
                          child: Center(
                            child: Text(
                              '$qty',
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.circular(14),
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

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _totalTanks > 0 ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealAccent,
                disabledBackgroundColor: AppTheme.divider,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next — Select Date & Time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _totalTanks > 0
                          ? Colors.white
                          : AppTheme.textMuted,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? (isAdd ? AppTheme.tealAccent : AppTheme.primaryNavy)
              : AppTheme.divider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
