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
    print('JWT Token: $jwtToken');
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
    final _formKey = GlobalKey<FormState>();
    String updatedFirstName = user['Firstname'];
    String updatedLastName = user['Lastname'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit User'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  initialValue: updatedFirstName,
                  decoration: InputDecoration(labelText: 'First Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a first name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    updatedFirstName = value!;
                  },
                ),
                TextFormField(
                  initialValue: updatedLastName,
                  decoration: InputDecoration(labelText: 'Last Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a last name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    updatedLastName = value!;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    await _updateUser(user['ID'], updatedFirstName, updatedLastName);
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Error updating user: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUser(String id, String firstName, String lastName) async {
    try {
      String? jwtToken = await storage.read(key: 'access_token');
      if (jwtToken != null) {
        final url = 'http://127.0.0.1:8080/users/$id';
        print('Updating user at URL: $url with first name: $firstName and last name: $lastName');
        final response = await http.patch(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'Firstname': firstName,
            'Lastname': lastName,
            'updatedAt': DateTime.now().toIso8601String(), // Automatically update updatedAt
          }),
        );

        print('Update response status: ${response.statusCode}');
        print('Update response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() {
            int index = users.indexWhere((user) => user['ID'] == id);
            if (index != -1) {
              users[index]['Firstname'] = firstName;
              users[index]['Lastname'] = lastName;
              users[index]['updatedAt'] = DateTime.now().toIso8601String();
            }
          });
        } else {
          print('Failed to update user: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error updating user: $e');
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editUser(user),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
