import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/utils/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/controller/navigation_cubit.dart';
import 'core/services/token_services.dart';
import 'package:http_parser/http_parser.dart';

class RegisterOrganisationScreen extends StatefulWidget {
  const RegisterOrganisationScreen({super.key});

  @override
  RegisterOrganisationScreenState createState() => RegisterOrganisationScreenState();
}

class RegisterOrganisationScreenState extends State<RegisterOrganisationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _organameController = TextEditingController();
  final _orgadescriController = TextEditingController();

  final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  final RegExp passwordRegExp = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');

  File? _image;
  String? _base64Image;
  final picker = ImagePicker();

  Future<void> getImage() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
        _base64Image = base64Encode(_image!.readAsBytesSync());
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
                title: Text(
                  translate(context)!.register,
                ),
                elevation: 0,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        GestureDetector(
                          onTap: getImage,
                          child: ClipOval(
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
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _organameController,
                          decoration: InputDecoration(
                            labelText: translate(context)!.organization_name,
                            errorMaxLines: 3,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context)!.organization_name_empty;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _orgadescriController,
                          decoration: InputDecoration(
                            labelText: translate(context)!.organization_description,
                            errorMaxLines: 3,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context)!.organization_description_empty;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _firstnameController,
                          decoration: InputDecoration(
                            labelText: translate(context)!.firstname,
                            errorMaxLines: 3,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context)!.firstname_empty;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _lastnameController,
                          decoration: InputDecoration(
                            labelText: translate(context)!.lastname,
                            errorMaxLines: 3,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context)!.lastname_empty;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: translate(context)!.email,
                            errorMaxLines: 3,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context)!.email_empty;
                            } else if (!emailRegExp.hasMatch(value)) {
                              return translate(context)!.email_invalid;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: translate(context)!.password,
                            errorMaxLines: 3,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context)!.password_empty;
                            } else if (!passwordRegExp.hasMatch(value)) {
                              return translate(context)!.password_invalid;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: translate(context)!.confirm_password,
                            errorMaxLines: 3,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context)!.confirm_password_empty;
                            }
                            if (value != _passwordController.text) {
                              return translate(context)!.password_no_match;
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  // Process data.
                                  try {
                                    final tokenService = TokenService();
                                    String? jwtToken = await tokenService.getValidAccessToken();

                                    var request = http.MultipartRequest(
                                      'POST',
                                      Uri.parse('${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/registerorganizer'),
                                    );

                                    request.headers['Authorization'] = 'Bearer $jwtToken';

                                    request.fields['firstname'] = _firstnameController.text;
                                    request.fields['lastname'] = _lastnameController.text;
                                    request.fields['email'] = _emailController.text;
                                    request.fields['password'] = _passwordController.text;
                                    request.fields['organization'] = _organameController.text;
                                    request.fields['orgadescri'] = _orgadescriController.text;

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
                                        content: Text(response.statusCode == 201
                                            ? translate(context)!.register_success
                                            : translate(context)!.register_failed),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                    if (response.statusCode == 201) {
                                      context.read<NavigationCubit>().updateUserRole('organizer');
                                      context.pushNamed('login');
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(translate(context)!.generic_error),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                backgroundColor: Colors.deepOrange,
                              ),
                              child: Text(
                                translate(context)!.register,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
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