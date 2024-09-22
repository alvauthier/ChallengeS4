import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/components/user_interest_chip.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/login_register_screen.dart';

import 'components/adaptive_navigation_bar.dart';

class UserInterestsScreen extends StatefulWidget {
  static const String routeName = '/user-interests';

  static navigateTo(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const UserInterestsScreen({super.key});

  @override
  UserInterestsScreenState createState() => UserInterestsScreenState();
}

class UserInterestsScreenState extends State<UserInterestsScreen> {
  List<Interest> allInterests = [];
  List<Interest> userInterests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    verifyJwtAndRedirectIfNecessary();
  }

  Future<void> verifyJwtAndRedirectIfNecessary() async {
    final tokenService = TokenService();
    String? token = await tokenService.getValidAccessToken();
    if (token == null) {
      if (mounted) {
        LoginRegisterScreen.navigateTo(context);
      }
    } else {
      await fetchInterests();
      requestNotificationPermission();
      
      FirebaseMessaging.instance.getToken().then((token) {
        debugPrint("FCM Token: $token");
      });
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground here!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }
      });
    }
  }

  Future<void> fetchInterests() async {
    try {
      final interests = await ApiServices.getAllInterests();
      final userInterests = await ApiServices.getUserInterests();
      if (mounted) {
        setState(() {
          allInterests = interests;
          this.userInterests = userInterests;
          isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'An unknown error occurred';
          isLoading = false;
        });
      }
    }
  }

  bool isInterestSelected(Interest interest) {
    return userInterests.any((userInterest) => userInterest.id == interest.id);
  }

  Future<void> toggleInterest(Interest interest) async {
    bool isSelected = isInterestSelected(interest);

    setState(() {
      if (isSelected) {
        userInterests.removeWhere((userInterest) => userInterest.id == interest.id);
      } else {
        userInterests.add(interest);
      }
    });

    try {
      if (isSelected) {
        await ApiServices.removeUserInterest(interest.id);
        await FirebaseMessaging.instance.unsubscribeFromTopic(sanitizeTopicName(interest.name));
        debugPrint('Unsubscribed from topic: ${sanitizeTopicName(interest.name)}');
      } else {
        await ApiServices.addUserInterest(interest.id);
        await FirebaseMessaging.instance.subscribeToTopic(sanitizeTopicName(interest.name));
        debugPrint('Subscribed from topic: ${sanitizeTopicName(interest.name)}');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'An unknown error occurred';
        });
      }
    }
  }

  void requestNotificationPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  String sanitizeTopicName(String topic) {
    return topic.toLowerCase().replaceAll(' ', '_');
  }

  Future<void> clearTokens() async {
    TokenService tokenService = TokenService();
    await tokenService.clearTokens();
  }

  void _logout() async {
    await clearTokens();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Centres d\'intérêts'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Centres d\'intérêts'),
        ),
        body: Center(child: Text(errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centres d\'intérêts'),
        actions: [
          TextButton(
            onPressed: _logout,
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Wrap(
          spacing: 10.0,
          runSpacing: 5.0,
          alignment: WrapAlignment.start,
          children: allInterests.map((interest) {
            bool isSelected = isInterestSelected(interest);
            return UserInterestChip(
              interest: interest,
              isSelected: isSelected,
              onSelected: toggleInterest,
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: const AdaptiveNavigationBar(),
    );
  }
}
