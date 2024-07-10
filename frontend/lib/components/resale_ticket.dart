import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/core/services/token_services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

class Ticket {
  final String id;
  final String category;
  final String price;
  final Reseller reseller;

  Ticket({required this.id, required this.category, required this.price, required this.reseller});

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'] as String,
      category: map['category'] as String,
      price: map['price'] as String,
      reseller: Reseller.fromMap(map['reseller'] as Map<String, dynamic>),
    );
  }
}

class Reseller {
  final String avatar;
  final String name;

  Reseller({required this.avatar, required this.name});

  factory Reseller.fromMap(Map<String, dynamic> map) {
    return Reseller(
      avatar: map['avatar'] as String,
      name: map['name'] as String,
    );
  }
}

class ResaleTicket extends StatelessWidget {
  final Ticket ticket;

  Future<Map<String, dynamic>?> createPaymentIntent(String ticketListingId) async {
    const String prefix = "tl_";
    final String prefixedId = "$prefix$ticketListingId";
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

  const ResaleTicket({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ticket.reseller.avatar,
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ticket.reseller.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${ticket.price} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                              color: Colors.deepOrangeAccent
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on),
                          Text(ticket.category),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                            child: const Text(
                              'Négocier',
                              style: TextStyle(
                                fontFamily: 'Readex Pro',
                                color: Colors.black
                              )
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              print(ticket.id);
                              final paymentIntentData = await createPaymentIntent(ticket.id);
                              if (paymentIntentData != null) {
                                await stripe.Stripe.instance.initPaymentSheet(
                                  paymentSheetParameters: stripe.SetupPaymentSheetParameters(
                                    paymentIntentClientSecret: paymentIntentData['client_secret'],
                                    merchantDisplayName: 'Weezemaster',
                                    billingDetails: const stripe.BillingDetails(
                                      address: stripe.Address(
                                        city: '',
                                        country: 'FR',
                                        line1: '',
                                        line2: '',
                                        postalCode: '',
                                        state: '',
                                      )
                                    )
                                  ),
                                );
                                try {
                                  print('Presenting payment sheet');
                                  await stripe.Stripe.instance.presentPaymentSheet();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Paiement réussi')),
                                  );
                                  // missing proceedToReservation function (need to update the userId in ticket and archive the transaction)
                                } catch (e) {
                                  print('Error presenting payment sheet: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Echec du paiement')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to create payment intent')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              backgroundColor: Colors.deepOrange,
                            ),
                            child: const Text(
                              'Acheter',
                              style: TextStyle(
                                  fontFamily: 'Readex Pro'
                              )
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}