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
    try {
      String? jwtToken = await _getValidToken();
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
            print('Interests: $interests');
          });
        } else {
          print('Failed to load interests: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error fetching interests: $e');
    }
  }

  Future<void> _editInterest(dynamic interest) async {
    final _formKey = GlobalKey<FormState>();
    String updatedName = interest['Name'];
    int? interestId = interest['ID'];

    print('Editing interest with ID: $interestId');

    if (interestId == null) {
      print('Interest ID is null');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Interest'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              initialValue: updatedName,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              onSaved: (value) {
                updatedName = value!;
              },
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
                    // Vérifiez si la ressource existe avant de la mettre à jour
                    bool exists = await _checkIfInterestExists(interestId);
                    if (exists) {
                      await _updateInterest(interestId, updatedName);
                      Navigator.of(context).pop();
                    } else {
                      print('Interest with ID $interestId does not exist');
                    }
                  } catch (e) {
                    print('Error updating interest: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkIfInterestExists(int id) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final response = await http.get(
          Uri.parse('http://127.0.0.1:8080/interests/$id'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        );

        print('Check interest existence response status: ${response.statusCode}');
        print('Check interest existence response body: ${response.body}');

        return response.statusCode == 200;
      } else {
        print('No JWT Token found');
        return false;
      }
    } catch (e) {
      print('Error checking interest existence: $e');
      return false;
    }
  }

  Future<void> _updateInterest(int id, String name) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final url = 'http://127.0.0.1:8080/interests/$id';
        print('Updating interest at URL: $url with name: $name');
        final response = await http.patch(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({'Name': name}),
        );

        print('Update response status: ${response.statusCode}');
        print('Update response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() {
            // Mettre à jour l'élément dans la liste locale
            int index = interests.indexWhere((interest) => interest['ID'] == id);
            if (index != -1) {
              interests[index]['Name'] = name;
            }
          });
        } else {
          print('Failed to update interest: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error updating interest: $e');
    }
  }

  Future<void> _deleteInterest(dynamic interest) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final response = await http.delete(
          Uri.parse('http://127.0.0.1:8080/interests/${interest['ID']}'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        );

        print('Delete response status: ${response.statusCode}');
        print('Delete response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() {
            interests.remove(interest);
          });
        } else {
          print('Failed to delete interest: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error deleting interest: $e');
    }
  }

  Future<void> _addInterest(String name) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8080/interests'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({'Name': name}),
        );

        print('Add response status: ${response.statusCode}');
        print('Add response body: ${response.body}');

        if (response.statusCode == 201) {
          setState(() {
            interests.add(json.decode(response.body));
          });
        } else {
          print('Failed to add interest: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error adding interest: $e');
    }
  }

  Future<String?> _getValidToken() async {
    // Retrieve the token from storage
    String? jwtToken = await storage.read(key: 'access_token');

    // Check if the token is expired or invalid (this is a placeholder check)
    // In a real application, you might decode the JWT token and check its expiration date
    if (jwtToken == null || jwtToken.isEmpty) {
      // Token is invalid or expired, try to renew it
      jwtToken = await _renewToken();
    }

    return jwtToken;
  }

  Future<String?> _renewToken() async {
    // Placeholder for token renewal logic
    // This could involve making a request to a refresh token endpoint
    // and storing the new token in secure storage
    print('Renewing token...');
    // Example logic to get a new token
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8080/auth/renew'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'refresh_token': 'your_refresh_token_here'}),
    );

    if (response.statusCode == 200) {
      final newToken = json.decode(response.body)['access_token'];
      await storage.write(key: 'access_token', value: newToken);
      return newToken;
    } else {
      print('Failed to renew token: ${response.body}');
      return null;
    }
  }

  void _showAddInterestDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Interest'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              onSaved: (value) {
                name = value!;
              },
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
              child: Text('Add'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    await _addInterest(name);
                  } catch (e) {
                    print('Error adding interest: $e');
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
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
          final id = interest['ID'] ?? 'Unknown';
          return ListTile(
            title: Text(name),
            subtitle: Text('ID: $id'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editInterest(interest),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteInterest(interest),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddInterestDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Interest',
      ),
    );
  }
}
