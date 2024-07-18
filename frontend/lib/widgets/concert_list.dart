import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConcertList extends StatefulWidget {
  const ConcertList({super.key});

  @override
  _ConcertListState createState() => _ConcertListState();
}

class _ConcertListState extends State<ConcertList> {
  final storage = const FlutterSecureStorage();
  List<dynamic> concerts = [];

  @override
  void initState() {
    super.initState();
    _fetchConcerts();
  }

  Future<void> _fetchConcerts() async {
    String? jwtToken = await storage.read(key: 'access_token');
    print('JWT Token: $jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8080/concerts'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          concerts = json.decode(response.body);
        });
      } else {
        print('Failed to load concerts: ${response.body}');
      }
    } else {
      print('No JWT Token found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Concert List'),
      ),
      body: ListView.builder(
        itemCount: concerts.length,
        itemBuilder: (context, index) {
          final concert = concerts[index];
          print('Concert: $concert'); // Ajout de l'impression
          final name = concert['Name'] ?? 'Unknown';
          final description = concert['Description'] ?? 'Unknown';
          return ListTile(
            title: Text(name),
            subtitle: Text(description),
          );
        },
      ),
    );
  }
}
