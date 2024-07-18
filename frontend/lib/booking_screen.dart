import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:weezemaster/core/models/concert_category.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/thank_you_screen.dart';
import 'package:http/http.dart' as http;
import 'package:weezemaster/core/services/payment_services.dart';

class BookingScreen extends StatefulWidget {
  final List<ConcertCategory> concertCategories;
  const BookingScreen({super.key, required this.concertCategories});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final storage = const FlutterSecureStorage();
  String? selectedCategory;

  Future<void> proceedToReservation() async {
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
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/reservation';
      final response = await http.post(
        Uri.parse(apiUrl),
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


  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService();
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
                        subtitle: Text('Nombre de tickets restants: $remainingTickets'),
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: selectedCategory == null
                ? null
                : () async {
                    if (selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez sélectionner une catégorie de billet.')),
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
                          const SnackBar(content: Text('Paiement réussi')),
                        );
                        await proceedToReservation();
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