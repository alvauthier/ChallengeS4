import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:weezemaster/translation.dart';

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
      items = <NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.home),
          label: translate(context)!.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt),
          label: translate(context)!.my_tickets,
        ),
        NavigationDestination(
          icon: const Icon(Icons.message),
          label: translate(context)!.my_messages,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person),
          label: translate(context)!.my_profile,
        ),
      ];
    } else if(userRole == 'organizer') {
      items = <NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.event),
          label: translate(context)!.my_concerts,
        ),
        NavigationDestination(
          icon: const Icon(Icons.add),
          label: translate(context)!.create_a_concert,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person),
          label: translate(context)!.my_profile,
        ),
      ];
    } else {
      items = <NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.home),
          label: translate(context)!.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.login),
          label: translate(context)!.login,
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
            context.pushNamed('home');
          } else if (index == 1) {
            context.pushNamed('my-tickets');
          } else if (index == 2) {
            context.pushNamed('conversations');
          } else {
            context.pushNamed('profile');
          }
        } else if(userRole == 'organizer') {
          if (index == 0) {
            context.pushNamed('organizer-concert');
          } else if (index == 1) {
            context.pushNamed('register-concert');
          } else {
            context.pushNamed('profile');
          }
        } else {
          if (index == 0) {
            context.pushNamed('home');
          } else {
            context.pushNamed('login-register');
          }
        }
      },
      destinations: items,
    );
  }
}