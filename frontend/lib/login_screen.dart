import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weezemaster/forgot_password_screen.dart';
import 'package:weezemaster/home/home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'components/adaptive_navigation_bar.dart';

import 'package:weezemaster/translation.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  static navigateTo(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  final storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              AppBar(
                title: Text(
                  translate(context)!.login,
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
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: translate(context)!.email,
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
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate(context)!.password_empty;
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
                                    final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/login';
                                    var response = await http.post(
                                      Uri.parse(apiUrl),
                                      headers: <String, String>{
                                        'Content-Type': 'application/json; charset=UTF-8',
                                      },
                                      body: jsonEncode(<String, String>{
                                        'email': _emailController.text,
                                        'password': _passwordController.text,
                                      }),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(response.statusCode == 200
                                            ? translate(context)!.login_success
                                            : translate(context)!.login_failed),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    if (response.statusCode == 200) {
                                      final Map<String, dynamic> responseData = jsonDecode(response.body);
                                      final String accessToken = responseData['access_token'];
                                      final String refreshToken = responseData['refresh_token'];
                                      await storage.write(key: 'access_token', value: accessToken);
                                      await storage.write(key: 'refresh_token', value: refreshToken);
                                      Navigator.pushNamed(context, '/');
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(translate(context)!.generic_error),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(translate(context)!.login),
                            ),
                          ),
                        ),
                        TextButton(onPressed: ()
                        {
                          ForgotPasswordScreen.navigateTo(context);
                        }, child: Text(translate(context)!.forgot_password)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const AdaptiveNavigationBar(),
    );
  }
}