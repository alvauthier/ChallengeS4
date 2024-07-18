import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const storage = FlutterSecureStorage();

  static Future<String?> simulateLogin() async {
    try {
      final apiUrl = kIsWeb
          ? 'http://127.0.0.1:${dotenv.env['API_PORT']}/login'
          : 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/login';

      // Log the API URL and credentials being sent
      print('Attempting to login with URL: $apiUrl');
      print('Using credentials - Email: admin@user.fr, Password: Testtest1@');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'email': 'admin@user.fr', // Utilisation de "email" au lieu de "username"
          'password': 'Testtest1@',
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final jwtToken = data['access_token'];
        await storage.write(key: 'access_token', value: jwtToken);
        print('JWT Token saved: $jwtToken');
        return jwtToken;
      } else {
        print('Failed to login: ${response.body}');
        return null;
      }
    } on SocketException catch (error) {
      print('Network error during login: $error');
      return null;
    } catch (error) {
      print('An error occurred during login: $error');
      return null;
    }
  }
}
