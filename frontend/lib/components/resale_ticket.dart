import 'package:flutter/material.dart';
import 'package:weezemaster/core/services/payment_services.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/login_register_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:weezemaster/thank_you_screen.dart';
import 'package:weezemaster/core/services/api_services.dart';

import '../chat.dart';

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
  final String id;

  Reseller({required this.avatar, required this.name, required this.id});

  factory Reseller.fromMap(Map<String, dynamic> map) {
    return Reseller(
      id: map['id'] as String,
      avatar: map['avatar'] as String,
      name: map['name'] as String,
    );
  }
}

class ResaleTicket extends StatelessWidget {
  final Ticket ticket;

  const ResaleTicket({super.key, required this.ticket});

  Future<void> updateTicketListingStatus(BuildContext context, String ticketId) async {
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();

    final body = jsonEncode({
      'ticketListingId': ticketId,
    });

    try {
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/ticket_listing_reservation/$ticketId';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('Ticket listing purchased');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket purchased.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ThankYouScreen()),
        );
      } else {
        debugPrint('Failed to update ticket listing status: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update ticket listing status.')),
        );
      }
    } catch (e) {
      debugPrint('Error updating ticket listing status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating ticket listing status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService();
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
                            onPressed: () async {
                              final tokenService = TokenService();
                              String? token = await tokenService.getValidAccessToken();
                              if (token == null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginRegisterScreen(),
                                  ),
                                );
                              } else {
                                final parts = token.split('.');
                                if (parts.length != 3) {
                                  throw Exception('Invalid token');
                                }

                                String output = parts[1].replaceAll('-', '+').replaceAll('_', '/');
                                switch (output.length % 4) {
                                  case 0:
                                    break;
                                  case 2:
                                    output += '==';
                                    break;
                                  case 3:
                                    output += '=';
                                    break;
                                  default:
                                    throw Exception('Illegal base64url string!"');
                                }

                                String userId = json.decode(utf8.decode(base64.decode(output)))['id'];

                                String conversationId = await ApiServices.postConversation(
                                  userId,
                                  ticket.reseller.id,
                                  ticket.id
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(conversationId: conversationId),
                                  ),
                                );
                              }
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
                              final tokenService = TokenService();
                              String? token = await tokenService.getValidAccessToken();
                              if (token == null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginRegisterScreen(),
                                  ),
                                );
                              } else {
                                final paymentIntentData = await paymentService.createPaymentIntent(ticket.id, 'tl_');
                                if (paymentIntentData != null) {
                                  try {
                                    await paymentService.initAndPresentPaymentSheet(
                                      context,
                                      paymentIntentData['client_secret'],
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Paiement réussi')),
                                    );
                                    await updateTicketListingStatus(context, ticket.id);
                                  } catch (e) {
                                    debugPrint('Error presenting payment sheet: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Echec du paiement')),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to create payment intent')),
                                  );
                                }
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