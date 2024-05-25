import 'package:flutter/material.dart';
import 'package:frontend/login_register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginRegisterScreen(),
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}
