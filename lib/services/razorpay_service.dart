import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class RazorpayService {
  static RazorpayService? _instance;
  static RazorpayService get instance => _instance ??= RazorpayService._();
  RazorpayService._();

  // Read credentials strictly from environment variables
  static const String _keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );
  static const String _keySecret = String.fromEnvironment(
    'RAZORPAY_KEY_SECRET',
    defaultValue: '',
  );

  static const String _razorpayBaseUrl = 'https://api.razorpay.com';
  static const String _proxyBaseUrl = String.fromEnvironment(
    'PROXY_URL',
    defaultValue: 'https://connector.rocket.new',
  );

  /// Returns the effective base URL — proxy on web to avoid CORS, direct on mobile
  String get _effectiveBaseUrl {
    if (kIsWeb) {
      return '$_proxyBaseUrl/proxy?url=${Uri.encodeComponent(_razorpayBaseUrl)}';
    }
    return _razorpayBaseUrl;
  }

  /// Basic Auth header built from RAZORPAY_KEY_ID:RAZORPAY_KEY_SECRET
  String get _basicAuth {
    final credentials = base64Encode(utf8.encode('$_keyId:$_keySecret'));
    return 'Basic $credentials';
  }

  Dio get _dio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  /// Step 1: Create a Razorpay order via POST /v1/orders with Basic Auth.
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
      final url = '$_effectiveBaseUrl/v1/orders';
      final response = await _dio.post(
        url,
        data: jsonEncode({
          'amount': amountInPaise,
          'currency': currency,
          'receipt': receipt ?? 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        }),
        options: Options(
          headers: {
            'Authorization': _basicAuth,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final Map<String, dynamic> body = data is String
            ? jsonDecode(data) as Map<String, dynamic>
            : data as Map<String, dynamic>;
        final orderId = body['id'] as String?;
        debugPrint('[Razorpay] Order created: $orderId');
        return orderId;
      } else {
        debugPrint(
          '[Razorpay] createOrder failed: ${response.statusCode} ${response.data}',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[Razorpay] createOrder DioException: ${e.message} | response: ${e.response?.data}',
      );
    } catch (e) {
      debugPrint('[Razorpay] createOrder error: $e');
    }
    return null;
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
