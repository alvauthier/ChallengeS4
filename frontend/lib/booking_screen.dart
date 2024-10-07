import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:weezemaster/core/models/concert_category.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:http/http.dart' as http;
import 'package:weezemaster/core/services/payment_services.dart';
import 'package:weezemaster/translation.dart';

class BookingScreen extends StatefulWidget {
  final List<ConcertCategory> concertCategories;
  const BookingScreen({super.key, required this.concertCategories});

  @override
  BookingScreenState createState() => BookingScreenState();
}

class BookingScreenState extends State<BookingScreen> {
  final storage = const FlutterSecureStorage();
  String? selectedCategory;

  Future<void> proceedToReservation() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(context)!.choose_category_empty)),
      );
      return;
    }

    final body = jsonEncode({
      'concertCategoryId': selectedCategory,
    });

    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/reservation';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('Réservation réussie');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(translate(context)!.booking_success)),
          );
          context.pushNamed('thank-you');
        }
      } else {
        debugPrint('Erreur lors de la réservation: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(translate(context)!.booking_failed)),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la connexion au serveur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context)!.generic_error)),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 80.0, bottom: 20.0),
                child: Text(
                  translate(context)!.choose_category,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Readex Pro',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.concertCategories.length,
                  itemBuilder: (context, index) {
                    var concertCategory = widget.concertCategories[index];
                    int remainingTickets = concertCategory.availableTickets - concertCategory.soldTickets;
                    bool isSoldOut = remainingTickets == 0;
                    return Card(
                      child: RadioListTile<String>(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(concertCategory.category.name.toString()),
                            Text(
                              '${concertCategory.price.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Colors.deepOrangeAccent,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text('${translate(context)!.number_tickets_remaining} $remainingTickets'),
                        value: concertCategory.id,
                        groupValue: selectedCategory,
                        onChanged: isSoldOut ? null : (String? value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        activeColor: isSoldOut ? Colors.grey : Colors.deepOrangeAccent,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: 10.0,
            left: 10.0,
            child: FloatingActionButton(
              child: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: selectedCategory == null
                    ? null
                    : () async {
                  if (selectedCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(translate(context)!.choose_category_empty)),
                    );
                    return;
                  }

                  final paymentIntentData = await paymentService.createPaymentIntent(selectedCategory!, 'cc_');
                  if (paymentIntentData != null) {
                    try {
                      await paymentService.initAndPresentPaymentSheet(
                        context,
                        paymentIntentData['client_secret'],
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(translate(context)!.payment_success)),
                      );
                      await proceedToReservation();
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
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  backgroundColor: selectedCategory == null ? Colors.grey : Colors.deepOrange,
                ),
                child: Text(
                  translate(context)!.proceed_payment,
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    color: selectedCategory == null ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}