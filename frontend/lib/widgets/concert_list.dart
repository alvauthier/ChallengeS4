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
    String updatedDate = concert['Date'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Concert'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
                  initialValue: updatedDate,
                  decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a date';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    updatedDate = value!;
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

  Future<void> _updateConcert(String id, String name, String description, String location, String date) async {
    try {
      String? jwtToken = await storage.read(key: 'access_token');
      if (jwtToken != null) {
        final url = 'http://127.0.0.1:8080/concerts/$id';
        print('Updating concert at URL: $url with name: $name');
        final response = await http.patch(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'Name': name,
            'Description': description,
            'Location': location,
            'Date': date,
          }),
        );

        print('Update response status: ${response.statusCode}');
        print('Update response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() {
            int index = concerts.indexWhere((concert) => concert['ID'] == id);
            if (index != -1) {
              concerts[index]['Name'] = name;
              concerts[index]['Description'] = description;
              concerts[index]['Location'] = location;
              concerts[index]['Date'] = date;
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
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editConcert(concert),
            ),
          );
        },
      ),
    );
  }
}
