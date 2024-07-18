import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:weezemaster/core/models/category.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/login_register_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegisterConcertScreen extends StatefulWidget {
  const RegisterConcertScreen({Key? key}) : super(key: key);

  @override
  _RegisterConcertScreenState createState() => _RegisterConcertScreenState();
}

class _RegisterConcertScreenState extends State<RegisterConcertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final Map<int, TextEditingController> _categoriesController = {};
  final Map<String, TextEditingController> _interestsController = {};
  final Map<int, TextEditingController> _pricesController = {};
  final storage = const FlutterSecureStorage();

  File? _image;
  String? _base64Image;
  final picker = ImagePicker();
  DateTime? _selectedDate;

  Future<void> getImage() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
        _base64Image = base64Encode(_image!.readAsBytesSync());
      }
    });
  }

  List<Category> categories = [];
  final Map<int, bool> selectedCategories = {};
  List<Interest> interests = [];
  final Map<int, bool> selectedInterests = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchInterests();
  }

Future<void> _fetchCategories() async {
  categories = await ApiServices.getCategories();
  setState(() {
    for (var category in categories) {
      selectedCategories[category.id] = false;
      _categoriesController[category.id] = TextEditingController();
      _pricesController[category.id] = TextEditingController();
    }
  });
}


  Future<void> _fetchInterests() async {
    interests = await ApiServices.getAllInterests();
    setState(() {
      for (var interest in interests) {
        selectedInterests[interest.id] = false;
        _interestsController[interest.name] = TextEditingController();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<String> getUserIdFromJwt() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      return decodedToken['id'] as String;
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
      );
      return '';
    }
  }

  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!');
    }

    return utf8.decode(base64Url.decode(output));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              AppBar(
                title: const Text('Créer un concert'),
                elevation: 0,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          GestureDetector(
                            onTap: getImage,
                            child: _image == null
                                ? Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.camera_alt),
                                  )
                                : Image.file(
                                    File(_image!.path),
                                    width: 100,
                                    height: 100,
                                  ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom du concert',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le nom du concert';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description du concert',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer la description du concert';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'Ville',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer la ville';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'Pas de date sélectionnée'
                                      : 'Date: ${_selectedDate!.toLocal().toIso8601String().split('T')[0]}',
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _selectDate(context),
                                child: const Text('Sélectionner date'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Catégories de billet',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...categories.map((category) {
                          return Column(
                            children: [
                              CheckboxListTile(
                                title: Text(category.name),
                                value: selectedCategories[category.id],
                                onChanged: (bool? value) {
                                  setState(() {
                                    selectedCategories[category.id] = value!;
                                  });
                                },
                              ),
                              if (selectedCategories[category.id]!)
                                Column(
                                  children: [
                                    TextFormField(
                                      controller: _categoriesController[category.id],
                                      decoration: InputDecoration(
                                        labelText: 'Nombre de places pour ${category.name}',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer le nombre de places pour ${category.name}';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Veuillez entrer un nombre valide';
                                        }
                                        return null;
                                      },
                                      keyboardType: TextInputType.number,
                                    ),
                                    TextFormField(
                                      controller: _pricesController[category.id],
                                      decoration: InputDecoration(
                                        labelText: 'Prix des places pour ${category.name}',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer le prix des places pour ${category.name}';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Veuillez entrer un prix valide';
                                        }
                                        return null;
                                      },
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                            ],
                          );
                        }).toList(),
                          const SizedBox(height: 20),
                          const Text(
                            'Intérêts',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 10,
                            children: interests.map((interest) {
                              return ChoiceChip(
                                label: Text(interest.name),
                                selected: selectedInterests[interest.id]!,
                                selectedColor: Colors.deepOrangeAccent,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedInterests[interest.id] = selected;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Container(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  List<Map<String, dynamic>> tabCategories = [];
                                  selectedCategories.forEach((id, selected) {
                                    if (selected) {
                                      tabCategories.add({
                                        'id': id,
                                        'places': int.parse(_categoriesController[id]!.text),
                                      });
                                    }
                                  });
                                  List<int> selectedInterestsList = [];
                                  selectedInterests.forEach((id, selected) {
                                    if (selected) {
                                      selectedInterestsList.add(id);
                                    }
                                  });
                                  if (_formKey.currentState!.validate()) {
                                    try {
                                      String userId = await getUserIdFromJwt();
                                      var response = await http.post(
                                        Uri.parse('http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/concerts'),
                                        headers: <String, String>{
                                          'Content-Type': 'application/json; charset=UTF-8',
                                        },
                                        body: jsonEncode(<String, dynamic>{
                                          'name': _nameController.text,
                                          'image': _base64Image,
                                          'description': _descriptionController.text,
                                          'location': _cityController.text,
                                          'date': _selectedDate!.toIso8601String().split('T')[0],
                                          'userId': userId,
                                          'InterestIDs': selectedInterestsList,
                                          'CategoriesIDs': tabCategories,
                                        }),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(response.statusCode == 200
                                              ? 'Création réussie'
                                              : 'Erreur lors de la création'),
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                      if (response.statusCode == 200) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Une erreur est survenue. Veuillez vérifier votre connexion internet ou réessayer plus tard.'),
                                          duration: Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Créer le concert'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
