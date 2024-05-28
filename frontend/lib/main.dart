import 'package:frontend/login_register_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:frontend/home/home_screen.dart';

void main() {
  initializeDateFormatting('fr_FR', null).then((_) => runApp(const MyApp()));
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
