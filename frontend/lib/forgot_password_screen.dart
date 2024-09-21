import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:weezemaster/reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/forgot-password';
        var response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'email': _emailController.text,
          }),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.statusCode == 200
                ? 'Si votre adresse email existe, code de réinitialisation envoyé'
                : 'Erreur lors de l\'envoi, veuillez réessayer ultérieurement'),
            duration: const Duration(seconds: 2),
          ),
        );

        if (response.statusCode == 200) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue. Veuillez réessayer plus tard.'),
            duration: Duration(seconds: 2),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre adresse email';
                  } else if (!emailRegExp.hasMatch(value)) {
                    return 'Veuillez entrer une adresse email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : sendResetCode,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Envoyer un code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
