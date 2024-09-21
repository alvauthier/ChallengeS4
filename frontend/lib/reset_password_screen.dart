import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ResetPasswordScreenState createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  final RegExp passwordRegExp = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');

  @override
  void dispose() {
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/reset-password';
        var response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'reset_code': _resetCodeController.text,
            'new_password': _newPasswordController.text,
          }),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.statusCode == 200
                ? 'Mot de passe réinitialisé avec succès'
                : 'Code de réinitialisation invalide ou expiré'),
            duration: const Duration(seconds: 2),
          ),
        );

        if (response.statusCode == 200) {
          // Redirige vers la page de connexion après succès
          Navigator.pushReplacementNamed(context, '/login');
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
        title: const Text('Réinitialiser le mot de passe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _resetCodeController,
                decoration: const InputDecoration(
                  labelText: 'Code de réinitialisation',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le code de réinitialisation';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nouveau mot de passe';
                  } else if (!passwordRegExp.hasMatch(value)) {
                    return 'Le mot de passe doit contenir au moins 8 caractères, dont une majuscule, une minuscule, un chiffre et un caractère spécial';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : resetPassword,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Réinitialiser le mot de passe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
