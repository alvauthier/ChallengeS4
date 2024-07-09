import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'dart:convert';
import 'package:frontend/core/models/concert_category.dart';
import 'package:frontend/core/services/token_services.dart';
import 'package:frontend/thank_you_screen.dart';
import 'package:http/http.dart' as http;

class BookingScreen extends StatefulWidget {
  final List<ConcertCategory> concertCategories;
  const BookingScreen({super.key, required this.concertCategories});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final storage = const FlutterSecureStorage();
  String? email;
  String? selectedCategory;
  int? selectedAmount;

  Future<void> proceedToPayment() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie de billet.')),
      );
      return;
    }

    final body = jsonEncode({
      'concertCategoryId': selectedCategory,
    });

    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/reservation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('Réservation réussie');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation réussie.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ThankYouScreen()),
        );
      } else {
        print('Erreur lors de la réservation: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Une erreur est survenue lors de la réservation. Veuillez réessayer.')),
        );
      }
    } catch (e) {
      print('Erreur lors de la connexion au serveur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la connexion au serveur. Veuillez réessayer.')),
      );
    }
  }

  Future<Map<String, dynamic>?> createPaymentIntent(int amount) async {
    final url = Uri.parse('http://10.0.2.2:8080/create-payment-intent');
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: json.encode({'amount': amount}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to create payment intent: ${response.body}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
            children: [
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 80.0, bottom: 20.0),
                    child: Text(
                      'Choisissez votre catégorie de billets',
                      style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Readex Pro',
                          fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.concertCategories.length,
                      itemBuilder: (context, index) {
                        var concertCategory = widget.concertCategories[index];
                        return Card(
                          child: RadioListTile<String>(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(concertCategory.category.name.toString()),
                                Text(
                                  '${concertCategory.price} €',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      color: Colors.deepOrangeAccent
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text('Nombre de tickets: ${concertCategory.availableTickets}'),
                            value: concertCategory.id,
                            groupValue: selectedCategory,
                            onChanged: (String? value) {
                              setState(() {
                                selectedCategory = value;
                                selectedAmount = concertCategory.price * 100;
                              });
                            },
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
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ]
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: selectedCategory == null
                ? null
                : () async {
                  if (selectedCategory == null || selectedAmount == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner une catégorie de billet.')),
                    );
                    return;
                  }

                  final paymentIntentData = await createPaymentIntent(selectedAmount!);
                  if (paymentIntentData != null) {
                    await stripe.Stripe.instance.initPaymentSheet(
                      paymentSheetParameters: stripe.SetupPaymentSheetParameters(
                        paymentIntentClientSecret: paymentIntentData['client_secret'],
                        merchantDisplayName: 'Weezemaster',
                      ),
                    );
                    try {
                      print('Presenting payment sheet');
                      await stripe.Stripe.instance.presentPaymentSheet();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Paiement réussi')),
                      );
                      await proceedToPayment();
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
                backgroundColor: selectedCategory == null ? Colors.grey : Colors.deepOrange,
              ),
              child: Text(
                'Procéder au paiement',
                style: TextStyle(
                  fontFamily: 'Readex Pro',
                  color: selectedCategory == null ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ),
    );
  }
}