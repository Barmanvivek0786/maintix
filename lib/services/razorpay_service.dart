import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class RazorpayService {
  static RazorpayService? _instance;
  static RazorpayService get instance => _instance ??= RazorpayService._();
  RazorpayService._();

  /// The public Razorpay key is safe to ship to the checkout widget.
  /// The secret is intentionally kept in the Supabase Edge Function.
  static const String keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  /// Step 1: Create a Razorpay order through the Supabase Edge Function.
  ///
  /// [amountRupees] — amount in rupees (e.g. 499). Converted strictly to paise internally.
  /// Returns the Razorpay order_id string on success, null on failure.
  Future<String?> createOrder({
    required int amountRupees,
    String currency = 'INR',
    String? receipt,
  }) async {
    // Strict paise conversion: multiply rupees by 100
    final int amountInPaise = amountRupees * 100;

    debugPrint(
      '[Razorpay] Creating order: ₹$amountRupees = $amountInPaise paise',
    );

    try {
      final response = await SupabaseService.instance.client.functions.invoke(
        'create-razorpay-order',
        body: {
          'amount': amountInPaise,
          'currency': currency,
          'receipt': receipt ?? 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final data = response.data;
      final body = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      final orderId = body['id'] as String?;
      if (orderId != null && orderId.isNotEmpty) {
        debugPrint('[Razorpay] Order created: $orderId');
        return orderId;
      }
      debugPrint('[Razorpay] Edge Function returned no order id: $data');
    } catch (e) {
      debugPrint('[Razorpay] createOrder error: $e');
    }
    return null;
  }

  /// Verify the checkout signature on the server before confirming a booking.
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) return false;
    try {
      final response = await SupabaseService.instance.client.functions.invoke(
        'verify-razorpay-payment',
        body: {
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
        },
      );
      final data = response.data;
      return data is Map && data['verified'] == true;
    } catch (e) {
      debugPrint('[Razorpay] verifyPayment error: $e');
      return false;
    }
  }

  /// Step 2: Record successful payment in Supabase.
  /// Inserts into payments table and updates booking status to CONFIRMED.
  ///
  /// [amountInPaise] — amount already in paise as stored/returned from createOrder flow.
  Future<bool> recordPaymentSuccess({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required int amountInPaise,
    String? bookingId,
  }) async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) return false;

      final client = SupabaseService.instance.client;

      await client.from('payments').insert({
        'user_id': user.id,
        'booking_id': bookingId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'amount': amountInPaise,
        'currency': 'INR',
        'status': 'SUCCESS',
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (bookingId != null && bookingId.isNotEmpty) {
        await client
            .from('bookings')
            .update({'status': 'CONFIRMED'})
            .eq('id', bookingId);
      }

      return true;
    } catch (e) {
      debugPrint('[Razorpay] recordPaymentSuccess error: $e');
      return false;
    }
  }

  /// Record a failed/pending payment attempt.
  Future<void> recordPaymentFailure({
    required String razorpayOrderId,
    int amountInPaise = 0,
    String? bookingId,
  }) async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) return;

      await SupabaseService.instance.client.from('payments').insert({
        'user_id': user.id,
        'booking_id': bookingId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': null,
        'amount': amountInPaise,
        'currency': 'INR',
        'status': 'FAILED',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Razorpay] recordPaymentFailure error: $e');
    }
  }
}
