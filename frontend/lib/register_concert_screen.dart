import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:weezemaster/core/models/category.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/utils/constants.dart';

class RegisterConcertScreen extends StatefulWidget {
  const RegisterConcertScreen({super.key});

  @override
  RegisterConcertScreenState createState() => RegisterConcertScreenState();
}

class RegisterConcertScreenState extends State<RegisterConcertScreen> {
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
    DateTime? dateTime = await showOmniDateTimePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(
        const Duration(days: 3652),
      ),
      is24HourMode: true,
    );
    if (dateTime != null) {
      setState(() {
        _selectedDate = dateTime;
      });
    }
  }

  Future<String> getUserIdFromJwt() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      return decodedToken['id'] as String;
    } else {
      if (mounted) {
        GoRouter.of(context).go(Routes.loginRegisterNamedPage);
      }
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
                title: Text(
                  translate(context)!.create_a_concert,
                  style: const TextStyle(
                    fontFamily: 'Readex Pro',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
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
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.camera_alt),
                                  )
                                : Image.file(
                                    File(_image!.path),
                                    width: double.infinity,
                                    height: 200,
                                  ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: translate(context)!.concert_name,
                              errorMaxLines: 3,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return translate(context)!.concert_name_empty;
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: translate(context)!.concert_description,
                              errorMaxLines: 3,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return translate(context)!.concert_description_empty;
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: translate(context)!.location,
                              errorMaxLines: 3,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return translate(context)!.location_empty;
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
                                      ? translate(context)!.select_date_empty
                                      : '${translate(context)!.selected_date} ${_selectedDate!.toLocal().toIso8601String().split('T')[0]} ${_selectedDate!.toLocal().toIso8601String().split('T')[1].split(':').sublist(0, 2).join(':')}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Readex Pro',
                                      fontSize: 16
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _selectDate(context),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  backgroundColor: Colors.deepOrange,
                                ),
                                child: Text(
                                    translate(context)!.select_date,
                                    style: const TextStyle(fontFamily: 'Readex Pro'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Text(
                            translate(context)!.ticket_categories,
                            style: const TextStyle(
                              fontFamily: 'Readex Pro',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...categories.map((category) {
                            return Column(
                              children: [
                                CheckboxListTile(
                                  title: Text(
                                    category.name,
                                    style: const TextStyle(fontFamily: 'Readex Pro'),
                                  ),
                                  value: selectedCategories[category.id],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      selectedCategories[category.id] = value!;
                                    });
                                  },
                                  activeColor: Colors.deepOrange,
                                ),
                                if (selectedCategories[category.id]!)
                                  Column(
                                    children: [
                                      TextFormField(
                                        controller: _categoriesController[category.id],
                                        decoration: InputDecoration(
                                          labelText: '${translate(context)!.number_of_tickets_for} ${category.name}',
                                          errorMaxLines: 3,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '${translate(context)!.number_of_tickets_for_empty} ${category.name}';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return translate(context)!.number_invalid;
                                          }
                                          return null;
                                        },
                                        keyboardType: TextInputType.number,
                                      ),
                                      TextFormField(
                                        controller: _pricesController[category.id],
                                        decoration: InputDecoration(
                                          labelText: '${translate(context)!.tickets_prices_for} ${category.name}',
                                          errorMaxLines: 3,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '${translate(context)!.tickets_prices_for_empty} ${category.name}';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return translate(context)!.price_invalid;
                                          }
                                          return null;
                                        },
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                              ],
                            );
                          }),

                          const SizedBox(height: 30),
                          Text(
                            translate(context)!.interests,
                            style: const TextStyle(
                              fontFamily: 'Readex Pro',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: interests.map((interest) {
                              return ChoiceChip(
                                label: Text(
                                  interest.name,
                                  style: const TextStyle(
                                    fontFamily: 'Readex Pro',
                                  ),
                                ),
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
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  List<Map<String, dynamic>> tabCategories = [];
                                  selectedCategories.forEach((id, selected) {
                                    if (selected) {
                                      tabCategories.add({
                                        'id': id,
                                        'places': int.parse(_categoriesController[id]!.text),
                                        'price': double.parse(_pricesController[id]!.text),
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
                                      final tokenService = TokenService();
                                      String? jwtToken = await tokenService.getValidAccessToken();

                                      var request = http.MultipartRequest(
                                        'POST',
                                        Uri.parse('${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/concerts'),
                                      );

                                      request.headers['Authorization'] = 'Bearer $jwtToken';

                                      request.fields['name'] = _nameController.text;
                                      request.fields['description'] = _descriptionController.text;
                                      request.fields['location'] = _cityController.text;
                                      request.fields['date'] = '${_selectedDate!.toLocal().toIso8601String().split('T')[0]} ${_selectedDate!.toLocal().toIso8601String().split('T')[1].split(':').sublist(0, 2).join(':')}';
                                      request.fields['InterestIDs'] = selectedInterestsList.join(',');
                                      request.fields['CategoriesIDs'] = jsonEncode(tabCategories);

                                      if (_image != null) {
                                        request.files.add(
                                          await http.MultipartFile.fromPath(
                                            'image',
                                            _image!.path,
                                            contentType: MediaType('image', _image!.path.split('.').last),
                                          ),
                                        );
                                      }

                                      var response = await request.send();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(response.statusCode == 200
                                              ? translate(context)!.create_concert_success
                                              : translate(context)!.create_concert_failed),
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );

                                      if (response.statusCode == 200) {
                                        GoRouter.of(context).go(Routes.homeNamedPage);
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString()),
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  backgroundColor: Colors.deepOrange,
                                ),
                                child: Text(
                                    translate(context)!.create_the_concert,
                                    style: const TextStyle(fontFamily: 'Readex Pro'),
                                ),
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
