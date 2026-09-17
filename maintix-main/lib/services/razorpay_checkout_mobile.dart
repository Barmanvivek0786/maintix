// Mobile implementation using razorpay_flutter SDK
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

Future<void> launchRazorpayCheckout({
  required BuildContext context,
  required String keyId,
  required String orderId,
  required int amountInPaise,
  required String email,
  required String contact,
  required Function(String paymentId, String orderId, String signature)
  onSuccess,
  required Function(String errorMsg) onFailure,
}) async {
  final razorpay = Razorpay();

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
    PaymentSuccessResponse response,
  ) {
    razorpay.clear();
    onSuccess(
      response.paymentId ?? '',
      response.orderId ?? orderId,
      response.signature ?? '',
    );
  });

  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    razorpay.clear();
    onFailure(response.message ?? 'Payment failed');
  });

  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (
    ExternalWalletResponse response,
  ) {
    razorpay.clear();
    onFailure('External wallet selected: ${response.walletName}');
  });

  final options = {
    'key': keyId,
    'amount': amountInPaise,
    'currency': 'INR',
    'order_id': orderId,
    'name': 'Maintix',
    'description': 'Water Tank Cleaning Service',
    'prefill': {'email': email, 'contact': contact},
    'theme': {'color': '#072654'},
  };

  try {
    razorpay.open(options);
  } catch (e) {
    razorpay.clear();
    onFailure('Failed to open Razorpay: $e');
  }
}
