import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:frontend/core/models/concert_category.dart';

class BookingScreen extends StatefulWidget {
  final List<ConcertCategory> concertCategories;
  const BookingScreen({super.key, required this.concertCategories});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final storage = const FlutterSecureStorage();
  String? email;
  int? selectedCategory; // Variable to store the selected category

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
                          child: RadioListTile<int>(
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
                            subtitle: Text('Nombre de tickets: ${concertCategory.numberTickets}'),
                            value: concertCategory.category.id,
                            groupValue: selectedCategory,
                            onChanged: (int? value) {
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
                // TODO: Implement payment logic here
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