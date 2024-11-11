import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/utils/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/controller/navigation_cubit.dart';

class LoginScreen extends StatefulWidget {
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

  Future<String> getUserRoleFromJwt(accessToken) async {
    Map<String, dynamic> decodedToken = _decodeToken(accessToken);

    return decodedToken['role'];
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
        throw Exception('Illegal base64url string!"');
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
                                      final String userRole = await getUserRoleFromJwt(accessToken);
                                      context.read<NavigationCubit>().updateUserRole(userRole);
                                      GoRouter.of(context).go(Routes.homeNamedPage);
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
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                backgroundColor: Colors.deepOrange,
                              ),
                              child: Text(
                                translate(context)!.login,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Readex Pro',
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.pushNamed('forgot-password');
                          },
                          child: Text(
                            translate(context)!.forgot_password,
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontFamily: 'Readex Pro',
                            ),
                          )
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