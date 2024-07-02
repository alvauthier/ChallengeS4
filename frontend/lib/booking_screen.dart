import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/login_register_screen.dart';
import 'dart:convert';

class BookingScreen extends StatefulWidget {
  final String concertId;
  const BookingScreen({super.key, required this.concertId});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final storage = const FlutterSecureStorage();
  String? email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Screen'),
      ),
      body: const Center(
        child: Text('Bonjour booking'),
      ),
    );
  }
}