import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/panel_admin.dart';
import 'package:frontend/profile_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:frontend/home/home_screen.dart';
import 'package:frontend/my_tickets/my_tickets_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyScaffold(),
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/':
            builder = (BuildContext _) => const HomeScreen();
            break;
          case '/my-tickets':
            builder = (BuildContext _) => const MyTicketsScreen();
            break;
          case '/profile':
            builder = (BuildContext _) => const ProfileScreen();
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

class MyScaffold extends StatefulWidget {
  const MyScaffold({super.key});

  @override
  _MyScaffoldState createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  int selectedIndex = 0;

  final pages = [
    const HomeScreen(),
    const MyTicketsScreen(),
    const ProfileScreen(), // TODO - Add the missing screen
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
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
        },
      ),
    );
  }
}