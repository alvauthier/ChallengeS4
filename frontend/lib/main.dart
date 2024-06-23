import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/login_register_screen.dart';
import 'package:frontend/profile_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:frontend/home/home_screen.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  initializeDateFormatting('fr_FR', null).then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ProfileScreen(),
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}
