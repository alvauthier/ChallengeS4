import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/services/payment_services.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/utils/constants.dart';

import '../controller/navigation_cubit.dart';

class Ticket {
  final String id;
  final String category;
  final String price;
  final String concertName;
  final Reseller reseller;
  final String concertImage;

  Ticket({required this.id, required this.category, required this.price, required this.concertName, required this.reseller, required this.concertImage});

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'] as String,
      category: map['category'] as String,
      price: map['price'] as String,
      concertName: map['concertName'] as String,
      reseller: Reseller.fromMap(map['reseller'] as Map<String, dynamic>),
      concertImage: map['concertImage'] as String,
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
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ticket_listing_reservation/$ticketId';
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
          SnackBar(content: Text(translate(context)!.ticket_success)),
        );
        context.pushNamed('thank-you');
      } else {
        debugPrint('Failed to update ticket listing status: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context)!.ticket_failed)),
        );
      }
    } catch (e) {
      debugPrint('Error updating ticket listing status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(context)!.generic_error)),
      );
    }
  }

  Future<String> getUserRoleFromJwt() async {
    final tokenService = TokenService();
    String? jwt = await tokenService.getValidAccessToken();
    if (jwt != null) {
      final parts = jwt.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload);
      if (payloadMap is! Map<String, dynamic>) {
        throw Exception('Invalid payload');
      }

      return payloadMap['role'];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService();
    final ButtonStyle disabledButtonStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.grey,
      backgroundColor: Colors.grey.shade300,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
      ),
    );

    return FutureBuilder<String>(
      future: getUserRoleFromJwt(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final userRole = snapshot.data ?? '';

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: ticket.reseller.avatar.isNotEmpty
                            ? Image.network(
                          ticket.reseller.avatar,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                            : const Image(
                          image: AssetImage("assets/user-placeholder.jpg"),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 30.0),
                              child: Text(
                                ticket.reseller.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Text(
                              '${ticket.price} €',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                color: Colors.deepOrangeAccent,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                const Icon(Icons.location_on),
                                Text(ticket.category),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'contact') {
                          final tokenService = TokenService();
                          String? token = await tokenService.getValidAccessToken();
                          if (token == null) {
                            context.read<NavigationCubit>().updateUserRole('');
                            GoRouter.of(context).go(Routes.loginRegisterNamedPage);
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

                            final existingConversationId = await ApiServices.checkConversationExists(
                              ticket.id,
                              userId,
                            );
                            debugPrint('existingConversationId: $existingConversationId');
                            debugPrint('concertImage: ${ticket.concertImage}');

                            if (existingConversationId != null && existingConversationId.isNotEmpty) {
                              debugPrint('Conversation found in the database, access it');
                              context.push(
                                '/chat/$existingConversationId',
                              );
                            } else {
                              debugPrint('No conversation found in the database');
                              context.push(
                                '/chat/newchat',
                                extra: {
                                  'userId': userId,
                                  'resellerId': ticket.reseller.id,
                                  'ticketId': ticket.id,
                                  'concertName': ticket.concertName,
                                  'price': ticket.price,
                                  'resellerName': ticket.reseller.name,
                                  'category': ticket.category,
                                  'concertImage': ticket.concertImage,
                                },
                              );
                            }
                          }
                        } else if (value == 'buy') {
                          final tokenService = TokenService();
                          String? token = await tokenService.getValidAccessToken();
                          if (token == null) {
                            context.read<NavigationCubit>().updateUserRole('');
                            GoRouter.of(context).go(Routes.loginRegisterNamedPage);
                          } else {
                            final paymentIntentData = await paymentService.createPaymentIntent(ticket.id, 'tl_');
                            if (paymentIntentData != null) {
                              try {
                                await paymentService.initAndPresentPaymentSheet(
                                  context,
                                  paymentIntentData['client_secret'],
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(translate(context)!.payment_success)),
                                );
                                await updateTicketListingStatus(context, ticket.id);
                              } catch (e) {
                                debugPrint('Error presenting payment sheet: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(translate(context)!.payment_failed)),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(translate(context)!.payment_error)),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<String>(
                            value: 'contact',
                            child: Text(translate(context)!.contact),
                          ),
                          PopupMenuItem<String>(
                            value: 'buy',
                            child: Text(translate(context)!.buy),
                          ),
                        ];
                      },
                      icon: Icon(Icons.more_vert),
                      enabled: userRole == 'user' || userRole == '',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}