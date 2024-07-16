import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/core/services/api_services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frontend/core/models/category.dart';
import 'package:frontend/core/services/token_services.dart';
import 'package:frontend/login_register_screen.dart';



class RegisterConcertScreen extends StatefulWidget {
  const RegisterConcertScreen({super.key});

  @override
  _RegisterConcertScreenState createState() => _RegisterConcertScreenState();
}

class _RegisterConcertScreenState extends State<RegisterConcertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _categoriesController = Map<String, TextEditingController>();

  File? _image;
  String? _base64Image; 
  final picker = ImagePicker();

  Future getImage() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
        _base64Image = base64Encode(_image!.readAsBytesSync());
      }
    });
  }

  List<Category> categories = [];
  Map<String, bool> selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    categories = await ApiServices.getCategories();
    setState(() {
      for (var category in categories) {
        selectedCategories[category.name] = false;
        _categoriesController[category.name] = TextEditingController();
      }
    });
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
                          const Text(
                            'Catégories de billet',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...categories.map((category) {
                            return Column(
                              children: [
                                CheckboxListTile(
                                  title: Text(category.name),
                                  value: selectedCategories[category.name],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      selectedCategories[category.name] = value!;
                                    });
                                  },
                                ),
                                if (selectedCategories[category.name]!)
                                  TextFormField(
                                    controller: _categoriesController[category.name],
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
                              ],
                            );
                          }).toList(),
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Container(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final tokenService = TokenService();
                                  String? token = await tokenService.getValidAccessToken();
                                  if (token == null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginRegisterScreen(),
                                      ),
                                    );
                                  }
                                    List<Map<String, dynamic>> tabCategories = [];
                                    selectedCategories.forEach((category, selected) {
                                        if (selected) {
                                         tabCategories.add(
                                          {
                                            'name': category,
                                            'places': _categoriesController[category]!.text,
                                          }
                                         );
                                        }
                                      });
                                  if (_formKey.currentState!.validate()) {
                                    try { 
                                      var response = await http.post(
                                      Uri.parse('http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/registerorganizer'),
                                      headers: <String, String>{
                                        'Content-Type': 'application/json; charset=UTF-8',
                                      },

                                      body: jsonEncode(<String, dynamic>{
                                        'name': _nameController.text,
                                        'description': _descriptionController.text,
                                        'ville': _cityController.text,
                                        'token': token!,
                                        'categories': tabCategories,
                                        'image': _base64Image,
                                      }),
                                    );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(response.statusCode == 201
                                              ? 'Inscription réussie'
                                              : 'Erreur lors de l\'inscription'),
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                      if (response.statusCode == 201) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Une erreur est survenue. Veuillez vérifier votre connexion internet ou réessayer plus tard.'),
                                          duration: Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('S\'inscrire'),
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
