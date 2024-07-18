import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:weezemaster/my_tickets/blocs/my_tickets_bloc.dart';
import 'package:weezemaster/conversations/conversations_screen.dart';
import 'package:weezemaster/profile_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:weezemaster/my_tickets/my_tickets_screen.dart';
import 'package:weezemaster/home/home_screen.dart';
import 'package:weezemaster/register_organization_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'widgets/user_list.dart';
import 'widgets/concert_list.dart';
import 'widgets/category_list.dart';
import 'widgets/interest_list.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  // Handle background message
}

Future<String?> simulateLogin() async {
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
      const storage = FlutterSecureStorage();
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  if (!kIsWeb) {
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLIC_KEY']!;
    await Stripe.instance.applySettings();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  initializeDateFormatting('fr_FR', null).then((_) async {
    await simulateLogin();
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: const AdminDashboard(),
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case '/':
              builder = (BuildContext _) => const AdminDashboard();
              break;
            case '/admin/users':
              builder = (BuildContext _) => const UserList();
              break;
            case '/admin/concerts':
              builder = (BuildContext _) => const ConcertList();
              break;
            case '/admin/categories':
              builder = (BuildContext _) => const CategoryList();
              break;
            case '/admin/interests':
              builder = (BuildContext _) => const InterestList();
              break;
            default:
              throw Exception('Invalid route: ${settings.name}');
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      );
    } else {
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
              builder = (BuildContext _) => BlocProvider(
                create: (context) => MyTicketsBloc()..add(MyTicketsDataLoaded()),
                child: const MyTicketsScreen(),
              );
              break;
            case '/conversations':
              builder = (BuildContext _) => const ConversationsScreen();
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
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/users');
              },
              child: const Text('Manage Users'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/concerts');
              },
              child: const Text('Manage Concerts'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/categories');
              },
              child: const Text('Manage Categories'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/interests');
              },
              child: const Text('Manage Interests'),
            ),
          ],
        ),
      ),
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
  final storage = const FlutterSecureStorage();
  String? userRole;

  @override
  void initState() {
    super.initState();
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

  final pages = [
    Navigator(key: GlobalKey<NavigatorState>(), onGenerateRoute: (routeSettings) {
      return MaterialPageRoute(builder: (context) => const HomeScreen());
    }),
    Navigator(key: GlobalKey<NavigatorState>(), onGenerateRoute: (routeSettings) {
      return MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MyTicketsBloc()..add(MyTicketsDataLoaded()),
          child: const MyTicketsScreen(),
        ),
      );
    }),
    Navigator(key: GlobalKey<NavigatorState>(), onGenerateRoute: (routeSettings) {
      return MaterialPageRoute(builder: (context) => const ConversationsScreen());
    }),
    Navigator(key: GlobalKey<NavigatorState>(), onGenerateRoute: (routeSettings) {
      return MaterialPageRoute(builder: (context) => const ProfileScreen());
    }),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: <Widget>[
          const NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: userRole == 'organizer' ? const Icon(Icons.event) : const Icon(Icons.receipt),
            label: userRole == 'organizer' ? 'Mes concerts' : 'Mes billets',
          ),
          const NavigationDestination(
            icon: Icon(Icons.message),
            label: 'Mes messages',
          ),
          const NavigationDestination(
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
