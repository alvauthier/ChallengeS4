import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final storage = const FlutterSecureStorage();
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    String? jwtToken = await storage.read(key: 'access_token');
    print('JWT Token: $jwtToken'); // Log the JWT token
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8080/users'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
      } else {
        print('Failed to load users: ${response.body}');
      }
    } else {
      print('No JWT Token found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final firstName = user['Firstname'] ?? 'Unknown';
          final lastName = user['Lastname'] ?? 'Unknown';
          return ListTile(
            title: Text(firstName),
            subtitle: Text(lastName),
          );
        },
      ),
    );
  }
}
