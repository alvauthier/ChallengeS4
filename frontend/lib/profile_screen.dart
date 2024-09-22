import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weezemaster/login_register_screen.dart';
import 'dart:convert';

import 'components/adaptive_navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';

  static navigateTo(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final storage = const FlutterSecureStorage();
  String? email;

  @override
  void initState() {
    super.initState();
    verifyJwtAndRedirectIfNecessary();
  }

  Future<void> verifyJwtAndRedirectIfNecessary() async {
    String? jwt = await storage.read(key: 'access_token');
    // if (jwt == null || !_isTokenValid(jwt)) {
    if (jwt == null) {
      LoginRegisterScreen.navigateTo(context);
    } else {
      getEmailFromJwt();
    }
  }

  // bool _isTokenValid(String token) {
  //   return false;
  // }

  Future<void> getEmailFromJwt() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      setState(() {
        email = decodedToken['email'];
      });
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
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Screen'),
      ),
      body: Center(
        child: Text('Bonjour $email'),
      ),
      bottomNavigationBar: const AdaptiveNavigationBar(),
    );
  }
}