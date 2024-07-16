import 'dart:ffi';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/concert/concert_screen.dart';
import 'package:frontend/core/models/concert_category.dart';
import 'package:frontend/login_register_screen.dart';
import 'package:frontend/login_screen.dart';
import 'package:frontend/profile_screen.dart';
import 'package:frontend/register_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:frontend/home/home_screen.dart';
import 'package:frontend/register_organization_screen.dart';
import 'package:frontend/concert_screen.dart';
import 'booking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLIC_KEY']!;
  await Stripe.instance.applySettings();
  initializeDateFormatting('fr_FR', null).then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  final String concertId;
  final List<ConcertCategory> concertCategories;

  const MyApp({super.key, this.concertId = '', this.concertCategories = const []});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: MyScaffold(
        body: Navigator(
          initialRoute: '/register-concert',
          onGenerateRoute: (RouteSettings settings) {
            WidgetBuilder builder;
            switch (settings.name) {
              case '/':
                builder = (BuildContext _) => const HomeScreen();
                break;
              case '/login-register':
                builder = (BuildContext _) => const LoginRegisterScreen();
                break;
              case '/login':
                builder = (BuildContext _) => const LoginScreen();
                break;
              case '/register':
                builder = (BuildContext _) => const RegisterScreen();
                break;
              case '/concert':
                builder = (BuildContext _) => ConcertScreen(concertId: concertId);
                break;
              case '/booking':
                builder = (BuildContext _) => BookingScreen(concertCategories: concertCategories);
                break;
              case '/profile':
                builder = (BuildContext _) => const ProfileScreen();
                break;
              case '/register-organization':
                builder = (BuildContext _) => const RegisterOrganisationScreen();
                break;
              case '/register-concert':
                builder = (BuildContext _) => const RegisterConcertScreen();
                break;
              default:
                throw Exception('Invalid route: ${settings.name}');
            }
            return MaterialPageRoute(builder: builder, settings: settings);
          },
        ),
      ),
    );
  }
}

class MyScaffold extends StatefulWidget {
  final Widget body;

  const MyScaffold({super.key, required this.body});

  @override
  _MyScaffoldState createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: const <Widget>[
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
        ],
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/');
              break;
            case 1:
              Navigator.pushNamed(context, '/my-tickets');
              break;
            case 2:
              Navigator.pushNamed(context, '/messages');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}