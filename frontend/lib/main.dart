import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:frontend/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLIC_KEY']!;
  await Stripe.instance.applySettings();
  initializeDateFormatting('fr_FR', null).then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}
