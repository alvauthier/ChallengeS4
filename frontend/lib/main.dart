import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:weezemaster/my_tickets/blocs/my_tickets_bloc.dart';
import 'package:weezemaster/conversations/conversations_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:weezemaster/my_tickets/my_tickets_screen.dart';
import 'package:weezemaster/home/home_screen.dart';
import 'package:weezemaster/register_concert_screen.dart';
import 'package:weezemaster/home_orga/concert_orga_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:weezemaster/user_interests_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLIC_KEY']!;
  await Stripe.instance.applySettings();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  initializeDateFormatting('fr_FR', null).then((_) => runApp(const MyApp()));

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
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
            builder = (BuildContext _) => BlocProvider(
              create: (context) => MyTicketsBloc()..add(MyTicketsDataLoaded()),
              child: const MyTicketsScreen(),
            );
            break;
          case '/conversations':
            builder = (BuildContext _) => const ConversationsScreen();
            break;
          case '/profile':
            builder = (BuildContext _) => const UserInterestsScreen();
            break;
          case '/register-concert':
            builder = (BuildContext _) => const RegisterConcertScreen();
            break;
          case '/concert-organization':
            builder = (BuildContext _) => const OrganizerConcertScreen();
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
  MyScaffoldState createState() => MyScaffoldState();
}

class MyScaffoldState extends State<MyScaffold> {
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
    Navigator(
      key: GlobalKey<NavigatorState>(),
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      },
    ),
    Navigator(
      key: GlobalKey<NavigatorState>(),
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => MyTicketsBloc()..add(MyTicketsDataLoaded()),
            child: const MyTicketsScreen(),
          ),
        );
      },
    ),
    Navigator(
      key: GlobalKey<NavigatorState>(),
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => const ConversationsScreen());
      },
    ),
    Navigator(
      key: GlobalKey<NavigatorState>(),
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => const UserInterestsScreen());
      },
    ),
    Navigator(
      key: GlobalKey<NavigatorState>(),
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => const RegisterConcertScreen());
      },
    ),
    Navigator(
      key: GlobalKey<NavigatorState>(),
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => const OrganizerConcertScreen());
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: userRole == null
            ? [pages[0],pages[3]]
            : (userRole == 'user'
                ? pages.sublist(0, 3)
                : [pages[5],pages[4],pages[3]]),
      ),
      bottomNavigationBar: userRole == null
        ? _buildNavBarUnauthenticated()
        : (userRole == 'user' ? _buildNavBarUser() : _buildNavBarOrganizer()),
    );
  }

  Widget _buildNavBarUnauthenticated() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      destinations: const <Widget>[
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.login),
          label: 'Se connecter',
        ),
      ],
      onDestinationSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }

  Widget _buildNavBarUser() {
    return NavigationBar(
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
    );
  }

  Widget _buildNavBarOrganizer() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      destinations: const <Widget>[
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
      ],
      onDestinationSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}