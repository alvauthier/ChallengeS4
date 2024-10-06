import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/booking_screen.dart';
import 'package:weezemaster/chat.dart';
import 'package:weezemaster/concert/concert_screen.dart';
import 'package:weezemaster/conversations/conversations_screen.dart';
import 'package:weezemaster/forgot_password_screen.dart';
import 'package:weezemaster/home/home_screen.dart';
import 'package:weezemaster/login_register_screen.dart';
import 'package:weezemaster/login_screen.dart';
import 'package:weezemaster/my_tickets/my_tickets_screen.dart';
import 'package:weezemaster/profile_screen.dart';
import 'package:weezemaster/register_concert_screen.dart';
import 'package:weezemaster/register_screen.dart';
import 'package:weezemaster/reset_password_screen.dart';
import 'package:weezemaster/thank_you_screen.dart';
import 'package:weezemaster/core/models/concert_category.dart';
import 'package:weezemaster/user_interests_screen.dart';
import 'my_tickets/blocs/my_tickets_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        LoginRegisterScreen.routeName: (context) => const LoginRegisterScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        ConversationsScreen.routeName: (context) => const ConversationsScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        ThankYouScreen.routeName: (context) => const ThankYouScreen(),
        RegisterConcertScreen.routeName: (context) => const RegisterConcertScreen(),
        UserInterestsScreen.routeName: (context) => const UserInterestsScreen(),
        ForgotPasswordScreen.routeName: (context) => const ForgotPasswordScreen(),
        ResetPasswordScreen.routeName: (context) => const ResetPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        switch (settings.name) {
          case ConcertScreen.routeName:
            return MaterialPageRoute(builder: (context) => ConcertScreen(id: args as String));
          case ChatScreen.routeName:
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (context) => ChatScreen(
                  id: args['id'] as String,
                  userId: args['userId'] as String?,
                  resellerId: args['resellerId'] as String?,
                  ticketId: args['ticketId'] as String?,
                  concertName: args['concertName'] as String?,
                  price: args['price'] as String?,
                  resellerName: args['resellerName'] as String?,
                  category: args['category'] as String?,
                ),
              );
            }
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case BookingScreen.routeName:
            return MaterialPageRoute(builder: (context) => BookingScreen(concertCategories: args as List<ConcertCategory>));
          case MyTicketsScreen.routeName:
            return MaterialPageRoute(builder: (context) => BlocProvider(
              create: (context) => MyTicketsBloc()..add(MyTicketsDataLoaded()),
              child: const MyTicketsScreen(),
            ));
        }

        return null;
      },
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
}