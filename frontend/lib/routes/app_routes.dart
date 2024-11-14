import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/utils/constants.dart';
import 'package:weezemaster/navigation/main_screen.dart';
import 'package:weezemaster/controller/navigation_cubit.dart';
import 'package:weezemaster/booking_screen.dart';
import 'package:weezemaster/chat.dart';
import 'package:weezemaster/concert/concert_screen.dart';
import 'package:weezemaster/conversations/conversations_screen.dart';
import 'package:weezemaster/core/services/websocket_service.dart';
import 'package:weezemaster/forgot_password_screen.dart';
import 'package:weezemaster/home/home_screen.dart';
import 'package:weezemaster/login_register_screen.dart';
import 'package:weezemaster/login_screen.dart';
import 'package:weezemaster/my_tickets/my_tickets_screen.dart';
import 'package:weezemaster/panel_admin.dart';
import 'package:weezemaster/profile/edit_profile_screen.dart';
import 'package:weezemaster/profile/profile_screen.dart';
import 'package:weezemaster/queue_screen.dart';
import 'package:weezemaster/register_concert_screen.dart';
import 'package:weezemaster/register_organization_screen.dart';
import 'package:weezemaster/register_screen.dart';
import 'package:weezemaster/resale_tickets_screen.dart';
import 'package:weezemaster/reset_password_screen.dart';
import 'package:weezemaster/thank_you_screen.dart';
import 'package:weezemaster/core/models/concert_category.dart';
import 'package:weezemaster/user_interests_screen.dart';
import 'package:weezemaster/home_orga/concert_orga_screen.dart';
import 'package:weezemaster/my_tickets/blocs/my_tickets_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:weezemaster/go_router_observer.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  static late final GoRouter _router;

  static Future<String> getUserRoleFromJwt() async {
    const storage = FlutterSecureStorage();
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      final parts = jwt.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload);
      if (payloadMap is! Map<String, dynamic>) {
        throw Exception('Invalid payload');
      }

      return payloadMap['role'];
    }
    return '';
  }

  static Future<void> initializeRouter() async {
    final userRole = await getUserRoleFromJwt();
    _router = GoRouter(
      initialLocation: Routes.homeNamedPage,
      debugLogDiagnostics: true,
      navigatorKey: _rootNavigatorKey,
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          observers: [routeObserver],
          builder: (context, state, child) {
            return BlocProvider(
              create: (context) => NavigationCubit(userRole),
              child: MainScreen(screen: child),
            );
          },
          routes: [
            GoRoute(
              path: Routes.homeNamedPage,
              name: Routes.homeNamedPage,
              pageBuilder: (context, state) =>
              const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
            GoRoute(
              path: '/concert/:id',
              name: 'concert',
              builder: (BuildContext context, GoRouterState state) => ConcertScreen(id: state.pathParameters['id'] ?? ''),
            ),
            GoRoute(
              path: '/booking',
              name: 'booking',
              builder: (context, state) {
                final concertCategories = state.extra as List<ConcertCategory>;
                return BookingScreen(concertCategories: concertCategories);
              },
            ),
            GoRoute(
              path: '/resale-tickets',
              name: 'resale-tickets',
              builder: (BuildContext context, GoRouterState state) {
                final resaleTickets = state.extra as List<dynamic>;
                return ResaleTicketsScreen(resaleTickets: resaleTickets);
              },
            ),
            GoRoute(
              path: '/thank-you',
              name: 'thank-you',
              builder: (context, state) => const ThankYouScreen(),
            ),
            GoRoute(
              path: '/queue',
              name: 'queue',
              builder: (BuildContext context, GoRouterState state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                final initialPosition = extra['position'] as int;
                final webSocketService = extra['webSocketService'] as WebSocketService;

                debugPrint('Initial Position: $initialPosition, WebTokenService: $webSocketService');

                return Scaffold(
                  body: QueueScreen(
                    initialPosition: initialPosition,
                    webSocketService: webSocketService,
                  ),
                );
              },
            ),
            GoRoute(
              path: Routes.loginRegisterNamedPage,
              name: 'login-register',
              pageBuilder: (context, state) =>
              const NoTransitionPage(
                child: LoginRegisterScreen(),
              ),
            ),
            GoRoute(
              path: '/login',
              name: 'login',
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: '/register',
              name: 'register',
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/forgot-password',
              name: 'forgot-password',
              builder: (context, state) => const ForgotPasswordScreen(),
            ),
            GoRoute(
              path: '/reset-password',
              name: 'reset-password',
              builder: (context, state) => const ResetPasswordScreen(),
            ),
            GoRoute(
              path: '/register-organization',
              name: 'register-organization',
              builder: (context, state) => const RegisterOrganisationScreen(),
            ),
            GoRoute(
              path: Routes.myTicketsNamedPage,
              name: 'my-tickets',
              pageBuilder: (context, state) =>
                  NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => MyTicketsBloc()..add(MyTicketsDataLoaded()),
                      child: const MyTicketsScreen(),
                    ),
                  ),
            ),
            GoRoute(
              path: Routes.conversationsNamedPage,
              name: 'conversations',
              pageBuilder: (context, state) =>
              const NoTransitionPage(
                child: ConversationsScreen(),
              ),
            ),
            GoRoute(
              path: '/chat/:id',
              name: 'chat',
              builder: (context, state) {
                final extras = state.extra as Map<String, dynamic>?;

                return ChatScreen(
                  id: state.pathParameters['id'] ?? '',
                  userId: extras?['userId'] ?? '',
                  resellerId: extras?['resellerId'] ?? '',
                  ticketId: extras?['ticketId'] ?? '',
                  concertName: extras?['concertName'] ?? '',
                  price: extras?['price'] ?? '',
                  resellerName: extras?['resellerName'] ?? '',
                  category: extras?['category'] ?? '',
                );
              },
            ),
            GoRoute(
              path: Routes.userInterestsNamedPage,
              name: 'user-interests',
              pageBuilder: (context, state) =>
              const NoTransitionPage(
                child: UserInterestsScreen(),
              ),
            ),
            GoRoute(
              path: Routes.profileNamedPage,
              name: 'profile',
              pageBuilder: (context, state) =>
              const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
            GoRoute(
              path: '/edit-profile',
              name: 'edit-profile',
              pageBuilder: (context, state) =>
              const NoTransitionPage(
                child: EditProfileScreen(),
              ),
            ),
            GoRoute(
              path: Routes.adminNamedPage,
              name: 'admin',
              pageBuilder: (context, state) =>
              const NoTransitionPage(
                child: AdminPanel(),
              ),
            ),
            GoRoute(
              path: Routes.organizerConcertNamedPage,
              name: 'organizer-concert',
              pageBuilder: (context, state) =>
              const NoTransitionPage(
                child: OrganizerConcertScreen(),
              ),
            ),
            GoRoute(
              path: Routes.registerConcertNamedPage,
              name: 'register-concert',
              pageBuilder: (context, state) =>
              const NoTransitionPage(
                child: RegisterConcertScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static GoRouter get router => _router;
}