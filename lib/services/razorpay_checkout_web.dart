// Web implementation using Razorpay JS SDK via dart:js
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
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
  try {
    // Check if Razorpay JS SDK is loaded
    final razorpayExists = js.context.hasProperty('Razorpay');
    if (!razorpayExists) {
      onFailure('Razorpay SDK not loaded. Please refresh and try again.');
      return;
    }

    // Register global callbacks that JS can call back into Dart
    js.context['_rzpOnSuccess'] = js.allowInterop((
      String paymentId,
      String rzpOrderId,
      String signature,
    ) {
      onSuccess(paymentId, rzpOrderId, signature);
    });

    js.context['_rzpOnFailure'] = js.allowInterop((String errorMsg) {
      onFailure(errorMsg);
    });

    // Build and open Razorpay checkout via JS eval
    final script =
        '''
      (function() {
        try {
          var options = {
            key: "$keyId",
            amount: $amountInPaise,
            currency: "INR",
            order_id: "$orderId",
            name: "Maintix",
            description: "Water Tank Cleaning Service",
            prefill: {
              email: "$email",
              contact: "$contact"
            },
            theme: { color: "#072654" },
            // Razorpay's checkout otherwise shows its own internal
            // "Payment could not be completed / Retry payment" screen on a
            // failed or timed-out attempt (common on slow/UPI connections)
            // BEFORE our own payment.failed handler below ever runs, which
            // strands users on a scary-looking screen even when the payment
            // actually went through and the webhook has already reconciled
            // it server-side. Disabling it routes failures straight to
            // payment.failed / _rzpOnFailure, so the app's own
            // webhook-status polling (_handlePaymentFailure) gets a chance
            // to detect an already-succeeded payment and show real success
            // instead.
            retry: { enabled: false },
            // Give slow UPI confirmations more time before being treated as
            // a failure at all.
            timeout: 300,
            handler: function(response) {
              if (window._rzpOnSuccess) {
                window._rzpOnSuccess(
                  response.razorpay_payment_id || "",
                  response.razorpay_order_id || "$orderId",
                  response.razorpay_signature || ""
                );
              }
            },
            modal: {
              ondismiss: function() {
                if (window._rzpOnFailure) {
                  window._rzpOnFailure("Payment cancelled by user");
                }
              }
            }
          };
          var rzp = new Razorpay(options);
          rzp.on("payment.failed", function(response) {
            if (window._rzpOnFailure) {
              window._rzpOnFailure(response.error.description || "Payment failed");
            }
          });
          rzp.open();
        } catch(e) {
          if (window._rzpOnFailure) {
            window._rzpOnFailure("Razorpay error: " + e.message);
          }
        }
      })();
    ''';

    js.context.callMethod('eval', [script]);
  } catch (e) {
    onFailure('Failed to launch Razorpay: $e');
  }
}
