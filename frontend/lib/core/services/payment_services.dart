import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/services/token_services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

class PaymentService {
  Future<Map<String, dynamic>?> createPaymentIntent(String id, String prefix) async {
    final String prefixedId = "$prefix$id";
    final url = Uri.parse('http://10.0.2.2:8080/create-payment-intent');
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: json.encode({'id': prefixedId}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to create payment intent: ${response.body}');
      return null;
    }
  }

  Future<void> initAndPresentPaymentSheet(BuildContext context, String clientSecret) async {
    await stripe.Stripe.instance.initPaymentSheet(
      paymentSheetParameters: stripe.SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Weezemaster',
        billingDetails: const stripe.BillingDetails(
          address: stripe.Address(
            city: '',
            country: 'FR',
            line1: '',
            line2: '',
            postalCode: '',
            state: '',
          ),
        ),
      ),
    );
    await stripe.Stripe.instance.presentPaymentSheet();
  }
}