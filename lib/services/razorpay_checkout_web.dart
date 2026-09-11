// Web implementation using Razorpay JS SDK via dart:js
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:js_util' show allowInterop;
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
    js.context['_rzpOnSuccess'] = allowInterop((
      String paymentId,
      String rzpOrderId,
      String signature,
    ) {
      onSuccess(paymentId, rzpOrderId, signature);
    });

    js.context['_rzpOnFailure'] = allowInterop((String errorMsg) {
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