import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InterestList extends StatefulWidget {
  const InterestList({super.key});

  @override
  _InterestListState createState() => _InterestListState();
}

class _InterestListState extends State<InterestList> {
  final storage = const FlutterSecureStorage();
  List<dynamic> interests = [];

  @override
  void initState() {
    super.initState();
    _fetchInterests();
  }

  Future<void> _fetchInterests() async {
    String? jwtToken = await storage.read(key: 'access_token');
    print('JWT Token: $jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8080/interests'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          interests = json.decode(response.body);
        });
      } else {
        print('Failed to load interests: ${response.body}');
      }
    } else {
      print('No JWT Token found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interest List'),
      ),
      body: ListView.builder(
        itemCount: interests.length,
        itemBuilder: (context, index) {
          final interest = interests[index];
          print('Interest: $interest'); // Ajout de l'impression
          final name = interest['Name'] ?? 'Unknown';
          return ListTile(
            title: Text(name),
          );
        },
      ),
    );
  }
}
