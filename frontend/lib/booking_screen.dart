import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/login_register_screen.dart';
import 'dart:convert';

class BookingScreen extends StatefulWidget {
  final String concertId;
  const BookingScreen({Key? key, required this.concertId}) : super(key: key);

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
        title: Text('Booking Screen'),
      ),
      body: Center(
        child: Text('Bonjour booking'),
      ),
    );
  }
}