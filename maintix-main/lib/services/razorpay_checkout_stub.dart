// Stub file — used when neither dart.library.io nor dart.library.html is available
// This should never be reached in practice.
import 'package:flutter/material.dart';

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
  onFailure('Razorpay checkout is not supported on this platform.');
}
