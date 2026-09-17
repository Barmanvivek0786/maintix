import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import '../../../services/razorpay_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/supabase_service.dart';
import '../../../routes/app_routes.dart';
import 'package:go_router/go_router.dart';

// Conditional import: razorpay_flutter only on non-web
import '../../../services/razorpay_checkout_stub.dart'
    if (dart.library.io) '../../../services/razorpay_checkout_mobile.dart'
    if (dart.library.html) '../../../services/razorpay_checkout_web.dart';

class BookingStep4Widget extends StatefulWidget {
  final VoidCallback onNext;
  const BookingStep4Widget({required this.onNext, super.key});

  @override
  State<BookingStep4Widget> createState() => _BookingStep4WidgetState();
}

class _BookingStep4WidgetState extends State<BookingStep4Widget> {
  bool _useCoins = false;
  bool _agreedToTerms = false;
  bool _processingPayment = false;
  int _coinsUsed = 0;

  // Coupon state
  final TextEditingController _couponController = TextEditingController();
  bool _couponLoading = false;
  String _couponMessage = '';
  bool _couponValid = false;
  int _couponDiscount = 0;
  String? _couponId;

  static const Map<String, int> _prices = {
    '500L': 1000,
    '750L': 1500,
    '1000L': 1800,
    '1500L': 2000,
    '2000L': 2500,
  };

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    final str = price.toString();
    if (str.length > 3) {
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$str';
  }

  Future<void> _applyCoupon(BuildContext context) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _couponLoading = true;
      _couponMessage = '';
      _couponValid = false;
      _couponDiscount = 0;
    });

    final result = await context.read<AppState>().validateCoupon(code);
    final valid = result['valid'] as bool? ?? false;
    final discount = result['discount'] as int? ?? 0;
    final message = result['message'] as String? ?? '';
    final couponId = result['couponId'] as String?;

    setState(() {
      _couponLoading = false;
      _couponValid = valid;
      _couponDiscount = discount;
      _couponMessage = message;
      _couponId = couponId;
    });

    if (valid) {
      context.read<AppState>().updateCartCoupon(code, discount);
    }
  }

  void _removeCoupon(BuildContext context) {
    setState(() {
      _couponValid = false;
      _couponDiscount = 0;
      _couponMessage = '';
      _couponId = null;
      _couponController.clear();
    });
    context.read<AppState>().updateCartCoupon('', 0);
  }

  Future<void> _initiateRazorpayPayment(
    BuildContext context,
    AppState appState,
    int totalAmount,
  ) async {
    if (!_agreedToTerms) return;
    if (RazorpayService.keyId.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Payment is temporarily unavailable. Please try again later.',
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    setState(() => _processingPayment = true);

    try {
      final int amountInPaise = totalAmount * 100;

      final orderId = await RazorpayService.instance.createOrder(
        amountRupees: totalAmount,
        receipt: 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (orderId == null) {
        setState(() => _processingPayment = false);
        Fluttertoast.showToast(
          msg: 'Could not create payment order. Please try again.',
          backgroundColor: AppTheme.error,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      setState(() => _processingPayment = false);

      // Get real user email and phone from Supabase profile
      final supabaseUser = SupabaseService.instance.currentUser;
      final userEmail = appState.userEmail.isNotEmpty
          ? appState.userEmail
          : (supabaseUser?.email ?? '');
      // Phone: prefer profile phone, fallback to user metadata
      final userPhone = appState.userPhone.isNotEmpty
          ? appState.userPhone
          : (supabaseUser?.userMetadata?['phone'] as String? ?? '');

      if (mounted) {
        await launchRazorpayCheckout(
          context: context,
          keyId: RazorpayService.keyId,
          orderId: orderId,
          amountInPaise: amountInPaise,
          email: userEmail,
          contact: userPhone,
              onSuccess:
                  (String paymentId, String rzpOrderId, String signature) async {
                final verified = await RazorpayService.instance.verifyPayment(
                  orderId: rzpOrderId.isNotEmpty ? rzpOrderId : orderId,
                  paymentId: paymentId,
                  signature: signature,
                );
                if (!verified) {
                  Fluttertoast.showToast(
                    msg: 'Payment verification failed. No booking was created.',
                    backgroundColor: AppTheme.error,
                    textColor: Colors.white,
                    toastLength: Toast.LENGTH_LONG,
                  );
                  await RazorpayService.instance.recordPaymentFailure(
                    razorpayOrderId: orderId,
                    amountInPaise: amountInPaise,
                  );
                  return;
                }
                await _handlePaymentSuccess(
                  context,
                  appState,
                  rzpOrderId.isNotEmpty ? rzpOrderId : orderId,
                  paymentId,
                  amountInPaise,
                );
              },
          onFailure: (String errorMsg) {
            Fluttertoast.showToast(
              msg: 'Payment failed. Please try again.',
              backgroundColor: AppTheme.error,
              textColor: Colors.white,
              toastLength: Toast.LENGTH_LONG,
            );
            RazorpayService.instance.recordPaymentFailure(
              razorpayOrderId: orderId,
              amountInPaise: amountInPaise,
            );
          },
        );
      }
    } catch (e) {
      setState(() => _processingPayment = false);
      Fluttertoast.showToast(
        msg: 'Payment Failed. Please try again.',
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _handlePaymentSuccess(
    BuildContext context,
    AppState appState,
    String orderId,
    String paymentId,
    int amountInPaise,
  ) async {
    final cart = appState.cartState;
    final orderItems = cart.tankQuantities.entries
        .where((e) => e.value > 0)
        .toList();
    final serviceLabel = orderItems
        .map((e) => '${e.key} × ${e.value}')
        .join(', ');

    // Deduct coins from Supabase immediately if coins were used
    if (_useCoins && _coinsUsed > 0) {
      await appState.deductCoinsFromSupabase(
        amount: _coinsUsed,
        description: 'Coins redeemed for booking',
      );
    }

    String? bookingId;
    final bookingRecord = await appState.createConfirmedBooking(
      serviceName: '$serviceLabel Tank Cleaning',
      cart: cart,
      totalAmount: amountInPaise ~/ 100,
    );
    bookingId = bookingRecord;

    await RazorpayService.instance.recordPaymentSuccess(
      razorpayOrderId: orderId,
      razorpayPaymentId: paymentId,
      amountInPaise: amountInPaise,
      bookingId: bookingId,
    );

    // Mark coupon as used if applied
    if (_couponValid && _couponId != null) {
      try {
        await SupabaseService.instance.markCouponUsed(_couponId!);
      } catch (_) {}
    }

    // Trigger booking confirmed + payment success notifications
    final userId = appState.currentUserId;
    if (userId != null) {
      await NotificationService.instance.triggerNotification(
        userId: userId,
        title: 'Booking Confirmed! 📅',
        body: 'Your slot is successfully scheduled.',
        type: 'booking',
        localId: 1,
      );
      await NotificationService.instance.triggerNotification(
        userId: userId,
        title: 'Payment Received! 💳',
        body: 'Service payment confirmed.',
        type: 'payment',
        localId: 2,
      );

      // Check if 3-tank offer should be sent
      await appState.scheduleThreeTankOfferIfNeeded(userId);
    }

    appState.resetCart();

    if (mounted) {
      _showPaymentSuccessModal(context, paymentId, orderId);
    }
  }

  void _showPaymentSuccessModal(
    BuildContext context,
    String paymentId,
    String orderId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PaymentSuccessModal(
        paymentId: paymentId,
        orderId: orderId,
        onViewBooking: () {
          Navigator.pop(ctx);
          context.go(AppRoutes.bookingHistoryScreen);
        },
        onBackToHome: () {
          Navigator.pop(ctx);
          context.go(AppRoutes.homeScreen);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cart = appState.cartState;
    final coinBalance = appState.coinBalance;

    final List<MapEntry<String, int>> orderItems = cart.tankQuantities.entries
        .where((e) => e.value > 0)
        .toList();

    int subtotal = 0;
    for (final item in orderItems) {
      subtotal += (_prices[item.key] ?? 0) * item.value;
    }

    final int totalTanks = orderItems.fold(0, (sum, e) => sum + e.value);
    final bool hasBulkDiscount = totalTanks >= 3;
    final int bulkDiscount = hasBulkDiscount ? 500 : 0;
    // Max coin redemption capped at 50 per transaction
    final int coinsDiscount = _useCoins ? coinBalance.clamp(0, 50) : 0;
    final int total =
        (subtotal - bulkDiscount - _couponDiscount - coinsDiscount).clamp(
          0,
          99999,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Billing & Discounts',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review your order before payment',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Order Items
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER ITEMS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ...orderItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              color: AppTheme.tealAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item.key} Tank × ${item.value}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatPrice((_prices[item.key] ?? 0) * item.value),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: AppTheme.divider, height: 16),
                _billRow(
                  'Base Total',
                  _formatPrice(subtotal),
                  valueColor: AppTheme.textPrimary,
                ),
                if (hasBulkDiscount) ...[
                  const SizedBox(height: 6),
                  _billRow(
                    'Bulk Discount (3+ tanks)',
                    '-${_formatPrice(bulkDiscount)}',
                    valueColor: AppTheme.success,
                    prefix: '🎉 ',
                  ),
                ],
                if (_couponValid && _couponDiscount > 0) ...[
                  const SizedBox(height: 6),
                  _billRow(
                    'Coupon (${_couponController.text.trim().toUpperCase()})',
                    '-${_formatPrice(_couponDiscount)}',
                    valueColor: AppTheme.warning,
                    prefix: '🎁 ',
                  ),
                ],

                if (coinBalance > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Wallet Coins',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '$coinBalance coins available (max 50/booking)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: _useCoins,
                          onChanged: (v) {
                            setState(() {
                              _useCoins = v ?? false;
                              _coinsUsed = _useCoins
                                  ? coinBalance.clamp(0, 50)
                                  : 0;
                            });
                            context.read<AppState>().updateCartCoins(_useCoins);
                          },
                          activeColor: AppTheme.tealAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_useCoins) ...[
                    const SizedBox(height: 6),
                    _billRow(
                      'Wallet Coins (-${coinBalance.clamp(0, 50)} coins)',
                      '-${_formatPrice(coinsDiscount)}',
                      valueColor: AppTheme.tealAccent,
                    ),
                  ],
                ],

                Divider(color: AppTheme.divider, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Payable',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _formatPrice(total),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF072654).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔒 Secured by Razorpay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF072654),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Coupon Code Input ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COUPON CODE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        enabled: !_couponValid,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inputTextColor(context),
                          letterSpacing: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            letterSpacing: 0,
                          ),
                          filled: true,
                          fillColor: _couponValid
                              ? AppTheme.success.withAlpha(15)
                               : AppTheme.inputFillColor(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _couponValid
                                  ? AppTheme.success
                                  : AppTheme.divider,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _couponValid
                                  ? AppTheme.success
                                  : AppTheme.divider,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: AppTheme.tealAccent,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.local_offer_rounded,
                            color: _couponValid
                                ? AppTheme.success
                                : AppTheme.textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _couponValid
                        ? IconButton(
                            onPressed: () => _removeCoupon(context),
                            icon: const Icon(Icons.close_rounded),
                            color: AppTheme.error,
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.error.withAlpha(15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _couponLoading
                                ? null
                                : () => _applyCoupon(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _couponLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Apply',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                  ],
                ),
                if (_couponMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _couponValid
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: _couponValid ? AppTheme.success : AppTheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _couponMessage,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _couponValid
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // Tappable coupon hint chips — only WEL100 shown
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _couponHintChip('WEL100', '₹100 off first booking'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Booking details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOOKING DETAILS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _detailRow(
                  Icons.calendar_today_rounded,
                  'Date',
                  cart.selectedDate ?? '—',
                ),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.access_time_rounded,
                  'Time',
                  cart.selectedTimeSlot ?? '—',
                ),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.location_on_rounded,
                  'Address',
                  cart.address.isNotEmpty ? cart.address : '—',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Terms checkbox
          InkWell(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _agreedToTerms
                      ? AppTheme.tealAccent
                      : AppTheme.divider,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (v) =>
                        setState(() => _agreedToTerms = v ?? false),
                    activeColor: AppTheme.tealAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the Terms & Conditions and Cancellation Policy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_agreedToTerms && !_processingPayment)
                  ? () => _initiateRazorpayPayment(
                      context,
                      context.read<AppState>(),
                      total,
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF072654),
                disabledBackgroundColor: AppTheme.divider,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _processingPayment
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💳', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Pay with Razorpay',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _agreedToTerms
                                ? Colors.white
                                : AppTheme.textMuted,
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

  Widget _billRow(
    String label,
    String value, {
    Color? valueColor,
    String prefix = '',
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$prefix$label',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.tealAccent, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Tappable coupon hint chip — tapping auto-fills the coupon code field
  Widget _couponHintChip(String code, String label) {
    return GestureDetector(
      onTap: () {
        if (!_couponValid) {
          _couponController.text = code;
          _couponController.selection = TextSelection.fromPosition(
            TextPosition(offset: code.length),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.tealAccent.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.tealAccent.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_offer_rounded,
              size: 12,
              color: AppTheme.tealAccent,
            ),
            const SizedBox(width: 4),
            Text(
              '$code — $label',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.tealAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Payment Success Modal — shown only after real razorpay_payment_id received
class _PaymentSuccessModal extends StatelessWidget {
  final String paymentId;
  final String orderId;
  final VoidCallback onViewBooking;
  final VoidCallback onBackToHome;

  const _PaymentSuccessModal({
    required this.paymentId,
    required this.orderId,
    required this.onViewBooking,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(26),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.success.withAlpha(77),
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppTheme.success,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Payment Successful!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking has been confirmed.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment ID',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          paymentId,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order ID',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          orderId,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
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
              child: ElevatedButton(
                onPressed: onViewBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text(
                  'View Booking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onBackToHome,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
