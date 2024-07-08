import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:frontend/core/models/concert_category.dart';
import 'package:frontend/core/services/token_services.dart';
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
        // Handle successful response
        print('Réservation réussie');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation réussie.')),
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
              onPressed: () {
                print("Selected category: $selectedCategory");
                proceedToPayment();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text(
                'Procéder au paiement',
                style: TextStyle(
                    fontFamily: 'Readex Pro',
                    color: Colors.white
                ),
              ),
            ),
          ),
        ),
    );
  }
}