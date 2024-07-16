import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final _categoryController = TextEditingController();

  File? _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if(pickedImage != null) {
        _image = File(pickedImage.path);
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
                          TextFormField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie de billet',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer une catégorie de billet';
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Container(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    // Process data.
                                    try {
                                      var request = http.MultipartRequest(
                                        'POST',
                                        Uri.parse('http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/registerconcert'),
                                      );
                                      if (_image != null) {
                                        request.files.add(await http.MultipartFile.fromPath(
                                          'image',
                                          _image!.path,
                                        ));
                                      }
                                      request.fields['name'] = _nameController.text;
                                      request.fields['description'] = _descriptionController.text;
                                      request.fields['city'] = _cityController.text;
                                      request.fields['category'] = _categoryController.text;
                                      var response = await request.send();
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
                                          content: Text('Une erreur est survenue. Veuillez vérifier votre connexion internet ou réessayer plus tard.'),
                                          duration: Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('S\'inscrire'),
                              ),
                            ),
                          )
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
