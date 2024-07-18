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

  void _editConcert(dynamic concert) {
    final _formKey = GlobalKey<FormState>();
    String updatedName = concert['Name'];
    String updatedDescription = concert['Description'];
    String updatedLocation = concert['Location'];
    DateTime updatedDate = DateTime.parse(concert['Date']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Concert'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
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
                  TextFormField(
                    initialValue: updatedDescription,
                    decoration: InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      updatedDescription = value!;
                    },
                  ),
                  TextFormField(
                    initialValue: updatedLocation,
                    decoration: InputDecoration(labelText: 'Location'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a location';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      updatedLocation = value!;
                    },
                  ),
                  TextFormField(
                    initialValue: updatedDate.toIso8601String().split('T')[0],
                    decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a date';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      updatedDate = DateTime.parse(value!);
                    },
                  ),
                ],
              ),
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
                    await _updateConcert(concert['ID'], updatedName, updatedDescription, updatedLocation, updatedDate);
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Error updating concert: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateConcert(String id, String name, String description, String location, DateTime date) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final response = await http.patch(
          Uri.parse('http://127.0.0.1:8080/concerts/$id'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'Name': name,
            'Description': description,
            'Location': location,
            'Date': date.toIso8601String(),
          }),
        );

        print('Update response status: ${response.statusCode}');
        print('Update response body: ${response.body}');

        if (response.statusCode == 200) {
          setState(() {
            int index = concerts.indexWhere((concert) => concert['ID'] == id);
            if (index != -1) {
              concerts[index]['Name'] = name;
              concerts[index]['Description'] = description;
              concerts[index]['Location'] = location;
              concerts[index]['Date'] = date.toIso8601String();
            }
          });
        } else {
          print('Failed to update concert: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error updating concert: $e');
    }
  }

  Future<void> _deleteConcert(dynamic concert) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final response = await http.delete(
          Uri.parse('http://127.0.0.1:8080/concerts/${concert['ID']}'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        );

        print('Delete response status: ${response.statusCode}');
        print('Delete response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() {
            concerts.remove(concert);
          });
        } else {
          print('Failed to delete concert: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error deleting concert: $e');
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editConcert(concert),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteConcert(concert),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
