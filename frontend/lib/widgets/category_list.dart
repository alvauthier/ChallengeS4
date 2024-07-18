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
    try {
      String? jwtToken = await _getValidToken();
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
            print('Categories: $categories');
          });
        } else {
          print('Failed to load categories: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _editCategory(dynamic category) async {
    final _formKey = GlobalKey<FormState>();
    String updatedName = category['Name'];
    int? categoryId = category['ID'];

    print('Editing category with ID: $categoryId');

    if (categoryId == null) {
      print('Category ID is null');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Category'),
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
                    bool exists = await _checkIfCategoryExists(categoryId);
                    if (exists) {
                      await _updateCategory(categoryId, updatedName);
                      Navigator.of(context).pop();
                    } else {
                      print('Category with ID $categoryId does not exist');
                    }
                  } catch (e) {
                    print('Error updating category: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkIfCategoryExists(int id) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final response = await http.get(
          Uri.parse('http://127.0.0.1:8080/categories/$id'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        );

        print('Check category existence response status: ${response.statusCode}');
        print('Check category existence response body: ${response.body}');

        return response.statusCode == 200;
      } else {
        print('No JWT Token found');
        return false;
      }
    } catch (e) {
      print('Error checking category existence: $e');
      return false;
    }
  }

  Future<void> _updateCategory(int id, String name) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final url = 'http://127.0.0.1:8080/categories/$id';
        print('Updating category at URL: $url with name: $name');
        final response = await http.patch(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({'Name': name, 'UpdatedAt': DateTime.now().toIso8601String()}),
        );

        print('Update response status: ${response.statusCode}');
        print('Update response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() {
            int index = categories.indexWhere((category) => category['ID'] == id);
            if (index != -1) {
              categories[index]['Name'] = name;
            }
          });
        } else {
          print('Failed to update category: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  Future<void> _deleteCategory(dynamic category) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final response = await http.delete(
          Uri.parse('http://127.0.0.1:8080/categories/${category['ID']}'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        );

        print('Delete response status: ${response.statusCode}');
        print('Delete response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() {
            categories.remove(category);
          });
        } else {
          print('Failed to delete category: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  Future<void> _addCategory(String name) async {
    try {
      String? jwtToken = await _getValidToken();
      if (jwtToken != null) {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8080/categories'),
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
            categories.add(json.decode(response.body));
          });
        } else {
          print('Failed to add category: ${response.body}');
        }
      } else {
        print('No JWT Token found');
      }
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  Future<String?> _getValidToken() async {
    String? jwtToken = await storage.read(key: 'access_token');
    if (jwtToken == null || jwtToken.isEmpty) {
      jwtToken = await _renewToken();
    }
    return jwtToken;
  }

  Future<String?> _renewToken() async {
    print('Renewing token...');
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

  void _showAddCategoryDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Category'),
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
                    await _addCategory(name);
                  } catch (e) {
                    print('Error adding category: $e');
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
        title: const Text('Category List'),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          print('Category: $category');
          final name = category['Name'] ?? 'Unknown';
          final id = category['ID'] ?? 'Unknown';
          return ListTile(
            title: Text(name),
            subtitle: Text('ID: $id'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editCategory(category),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteCategory(category),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Category',
      ),
    );
  }
}
