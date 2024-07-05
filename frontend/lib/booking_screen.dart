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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
            children: [
              ListView.builder(
                itemCount: widget.concertCategories.length,
                itemBuilder: (context, index) {
                  var concertCategory = widget.concertCategories[index];
                  return Card(
                    child: ListTile(
                      title: Text(concertCategory.category.name.toString()),
                      subtitle: Text('Prix: ${concertCategory.price} €, Nombre de tickets: ${concertCategory.numberTickets}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          backgroundColor: Colors.deepOrange,
                        ),
                        onPressed: () {
                        },
                        child: const Text('Choisir'),
                      ),
                    ),
                  );
                },
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
        )
    );
  }
}