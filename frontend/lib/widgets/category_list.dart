import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key});

  @override
  _CategoryListState createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  final storage = const FlutterSecureStorage();
  List<dynamic> categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    String? jwtToken = await storage.read(key: 'access_token');
    print('JWT Token: $jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8080/categories'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          categories = json.decode(response.body);
        });
      } else {
        print('Failed to load categories: ${response.body}');
      }
    } else {
      print('No JWT Token found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category List'),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          print('Category: $category'); // Ajout de l'impression
          final name = category['Name'] ?? 'Unknown';
          return ListTile(
            title: Text(name),
          );
        },
      ),
    );
  }
}
