import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/app.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'controller/navigation_cubit.dart';
import 'firebase_options.dart';
import 'package:weezemaster/routes/app_routes.dart';
import 'package:provider/provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppRouter.initializeRouter();
  await dotenv.load(fileName: '.env');
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLIC_KEY']!;
  await Stripe.instance.applySettings();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final userRole = await AppRouter.getUserRoleFromJwt();

  initializeDateFormatting('fr_FR', null).then((_) => runApp(
    MultiProvider(
      providers: [
        BlocProvider(
          create: (_) => NavigationCubit(userRole),
        ),
      ],
      child: App(),
    ),
  ));

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
}