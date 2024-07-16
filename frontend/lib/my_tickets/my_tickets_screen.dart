import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weezemaster/my_tickets/blocs/my_tickets_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../login_register_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => MyTicketsScreenState();
}

class MyTicketsScreenState extends State<MyTicketsScreen> {
  final storage = const FlutterSecureStorage();
  String? userId;

  @override
  void initState() {
    super.initState();
    getUserIdFromJwt();
  }

  Future<void> getUserIdFromJwt() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      setState(() {
        userId = decodedToken['id'];
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
      );
    }
  }

  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
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

    return utf8.decode(base64Url.decode(output));
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  static const tickets = [
    {
      "concert": {
        "date": "2022-12-31T23:59:59.999Z",
        "location": "Paris La Défense Arena",
        "name": "Eras Tour - Taylor Swift"
      },
      "concertCategory": {
        "category": {
          "name": "Catégorie 1",
        }
      }
    },
    {
      "concert": {
        "date": "2022-12-31T23:59:59.999Z",
        "location": "Paris La Défense Arena",
        "name": "Eras Tour - Taylor Swift"
      },
      "concertCategory": {
        "category": {
          "name": "Catégorie 1",
        }
      }
    }
  ];

  @override
  Widget build(BuildContext context) {
    final localUserId = userId;

    if (localUserId == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      // TODO convert to BlocBuilder
      return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Vos tickets',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Readex Pro'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    final concert = ticket['concert'] as Map<String, dynamic>?;
                    final concertCategory = ticket['concertCategory'] as Map<String, dynamic>?;

                    return Card(
                      child: ListTile(
                        title: Text(concert?['name'] as String? ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${(concertCategory?['category'] as Map<String, dynamic>? ?? {})['name'] as String? ?? ''}'),
                            Text('${concert?['location'] as String? ?? ''} - ${formatDate(concert?['date'] as String? ?? '1970-01-01T00:00:00.000Z')}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {

                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            backgroundColor: Colors.deepOrange,
                          ),
                          child: const Text(
                              'Revendre',
                              style: TextStyle(
                                  fontFamily: 'Readex Pro'
                              )
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}