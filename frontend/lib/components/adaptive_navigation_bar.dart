import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AdaptiveNavigationBar extends StatefulWidget {
  const AdaptiveNavigationBar({super.key});

  @override
  _AdaptiveNavigationBarState createState() => _AdaptiveNavigationBarState();
}

class _AdaptiveNavigationBarState extends State<AdaptiveNavigationBar> {
  int selectedIndex = 0;
  final storage = const FlutterSecureStorage();
  String? userRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getUserRoleFromJwt();
  }

  Future<void> getUserRoleFromJwt() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      setState(() {
        userRole = decodedToken['role'];
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
    List<NavigationDestination> items;

    if (userRole == 'user') {
      items = const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt),
          label: 'Mes billets',
        ),
        NavigationDestination(
          icon: Icon(Icons.message),
          label: 'Mes messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.person),
          label: 'Mon profil',
        ),
      ];
    } else if(userRole == 'organizer') {
      items = const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.event),
          label: 'Mes concerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.add),
          label: 'Créer un concert',
        ),
        NavigationDestination(
          icon: Icon(Icons.person),
          label: 'Mon profil',
        ),
      ];
    } else {
      items = const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.login),
          label: 'Se connecter',
        ),
      ];
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          selectedIndex = index;
        });

        if (userRole == 'user') {
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/my-tickets');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/conversations');
          } else {
            Navigator.pushNamed(context, '/profile');
          }
        } else if(userRole == 'organizer') {
          if (index == 0) {
            Navigator.pushNamed(context, '/concerts');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/create-concert');
          } else {
            Navigator.pushNamed(context, '/profile');
          }
        } else {
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          } else {
            Navigator.pushNamed(context, '/login-register');
          }
        }
      },
      destinations: items,
    );
  }
}