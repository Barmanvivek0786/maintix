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
    // Razorpay's checkout otherwise shows its own internal "Payment could
    // not be completed / Retry payment" screen on a failed or timed-out
    // attempt (common on slow/UPI connections) BEFORE our own
    // EVENT_PAYMENT_ERROR handler ever runs — which is what strands users
    // on a scary-looking screen even when the payment actually went
    // through and our webhook has already reconciled it. Disabling it
    // routes failures straight to EVENT_PAYMENT_ERROR above, so the app's
    // own webhook-status polling (see _handlePaymentFailure) gets a
    // chance to detect a already-succeeded payment and show real success
    // instead.
    'retry': {'enabled': false},
    // Give slow UPI confirmations more time before being treated as a
    // failure at all.
    'timeout': 300,
  };

  try {
    razorpay.open(options);
  } catch (e) {
    razorpay.clear();
    onFailure('Failed to open Razorpay: $e');
  }
}
