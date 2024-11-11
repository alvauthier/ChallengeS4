import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/utils/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/controller/navigation_cubit.dart';

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
                                    var response = await http.post(
                                      Uri.parse('${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/registerorganizer'),
                                      headers: <String, String>{
                                        'Content-Type': 'application/json; charset=UTF-8',
                                      },
                                      body: jsonEncode(<String, String>{
                                        'firstname': _firstnameController.text,
                                        'lastname': _lastnameController.text,
                                        'email': _emailController.text,
                                        'password': _passwordController.text,
                                        'organization': _organameController.text,
                                        'orgadescri': _orgadescriController.text
                                      }),
                                    );
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
                                      GoRouter.of(context).go(Routes.homeNamedPage);
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(translate(context)!.generic_error),
                                        duration: Duration(seconds: 5),
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