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

  void _editUser(dynamic user) {
    // Implémentation de la fonction d'édition
    print('Edit user: $user');
  }

  void _deleteUser(dynamic user) async {
    String? jwtToken = await storage.read(key: 'access_token');
    if (jwtToken != null) {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:8080/users/${user['id']}'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          users.remove(user);
        });
      } else {
        print('Failed to delete user: ${response.body}');
      }
    } else {
      print('No JWT Token found');
    }
  }

  void _addUser() {
    // Implémentation de la fonction d'ajout d'un nouvel utilisateur
    print('Add new user');
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editUser(user),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteUser(user),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        child: Icon(Icons.add),
        tooltip: 'Add User',
      ),
    );
  }
}
