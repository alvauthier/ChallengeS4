import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:weezemaster/translation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();

  final RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  final RegExp passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');

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
                        Flexible(
                          child: TextFormField(
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
                        ),
                        Flexible(
                          child: TextFormField(
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
                        ),
                        Flexible(
                          child: TextFormField(
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
                        ),
                        Flexible(
                          child: TextFormField(
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
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                        ),
                        Flexible(
                          child: TextFormField(
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
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  // Process data.
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
                                  fontFamily: 'Readex Pro',
                                ),
                              ),
                            ),
                          ),
                        ),
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
