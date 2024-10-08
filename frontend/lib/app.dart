import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/booking_screen.dart';
import 'package:weezemaster/chat.dart';
import 'package:weezemaster/components/resale_ticket.dart';
import 'package:weezemaster/concert/concert_screen.dart';
import 'package:weezemaster/conversations/conversations_screen.dart';
import 'package:weezemaster/forgot_password_screen.dart';
import 'package:weezemaster/home/home_screen.dart';
import 'package:weezemaster/login_register_screen.dart';
import 'package:weezemaster/login_screen.dart';
import 'package:weezemaster/my_tickets/my_tickets_screen.dart';
import 'package:weezemaster/profile_screen.dart';
import 'package:weezemaster/register_concert_screen.dart';
import 'package:weezemaster/register_organization_screen.dart';
import 'package:weezemaster/register_screen.dart';
import 'package:weezemaster/resale_tickets_screen.dart';
import 'package:weezemaster/reset_password_screen.dart';
import 'package:weezemaster/thank_you_screen.dart';
import 'package:weezemaster/core/models/concert_category.dart';
import 'package:weezemaster/user_interests_screen.dart';
import 'home_orga/concert_orga_screen.dart';
import 'package:weezemaster/components/adaptive_navigation_bar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'my_tickets/blocs/my_tickets_bloc.dart';

class App extends StatelessWidget {
  App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
      ],
    );
  }

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: HomeScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/login-register',
        name: 'login-register',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: LoginRegisterScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: LoginScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: RegisterScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: ForgotPasswordScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: ResetPasswordScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/concert/:id',
        name: 'concert',
        builder: (BuildContext context, GoRouterState state) {
          return Scaffold(
            body: ConcertScreen(id: state.pathParameters['id'] ?? ''),
            bottomNavigationBar: const AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/conversations',
        name: 'conversations',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: ConversationsScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/organizer-concert',
        name: 'organizer-concert',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: OrganizerConcertScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/register-concert',
        name: 'register-concert',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: RegisterConcertScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/register-organization',
        name: 'register-organization',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: RegisterOrganisationScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/my-tickets',
        name: 'my-tickets',
        builder: (BuildContext context, GoRouterState state) {
          return Scaffold(
            body: BlocProvider(
              create: (context) => MyTicketsBloc()..add(MyTicketsDataLoaded()),
              child: const MyTicketsScreen(),
            ),
            bottomNavigationBar: const AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: ProfileScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (BuildContext context, GoRouterState state) {
          final concertCategories = state.extra as List<ConcertCategory>;

          return Scaffold(
            body: BookingScreen(concertCategories: concertCategories),
            bottomNavigationBar: const AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/resale-tickets',
        name: 'resale-tickets',
        builder: (BuildContext context, GoRouterState state) {
          final resaleTickets = state.extra as List<dynamic>;

          return Scaffold(
            body: ResaleTicketsScreen(resaleTickets: resaleTickets),
            bottomNavigationBar: const AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chat',
        builder: (BuildContext context, GoRouterState state) {
          final extras = state.extra as Map<String, dynamic>?;

          return Scaffold(
            body: ChatScreen(
              id: state.pathParameters['id'] ?? '',
              userId: extras?['userId'] ?? '',
              resellerId: extras?['resellerId'] ?? '',
              ticketId: extras?['ticketId'] ?? '',
              concertName: extras?['concertName'] ?? '',
              price: extras?['price'] ?? '',
              resellerName: extras?['resellerName'] ?? '',
              category: extras?['category'] ?? '',
            ),
            bottomNavigationBar: const AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/user-interests',
        name: 'user-interests',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: UserInterestsScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
      GoRoute(
        path: '/thank-you',
        name: 'thank-you',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: ThankYouScreen(),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        },
      ),
    ],
  );
}
