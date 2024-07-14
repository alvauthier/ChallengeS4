import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/components/user_interest_chip.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';

class UserInterestsScreen extends StatefulWidget {
  const UserInterestsScreen({super.key});

  @override
  _UserInterestsScreenState createState() => _UserInterestsScreenState();
}

class _UserInterestsScreenState extends State<UserInterestsScreen> {
  List<Interest> allInterests = [];
  List<Interest> userInterests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchInterests();
    requestNotificationPermission();
    
    FirebaseMessaging.instance.getToken().then((token) {
      print("FCM Token: $token");
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground here!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  Future<void> fetchInterests() async {
    try {
      final interests = await ApiServices.getAllInterests();
      final userInterests = await ApiServices.getUserInterests();
      setState(() {
        allInterests = interests;
        this.userInterests = userInterests;
        isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unknown error occurred';
        isLoading = false;
      });
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
        print('Unsubscribed from topic: ${sanitizeTopicName(interest.name)}');
      } else {
        await ApiServices.addUserInterest(interest.id);
        await FirebaseMessaging.instance.subscribeToTopic(sanitizeTopicName(interest.name));
        print('Subscribed from topic: ${sanitizeTopicName(interest.name)}');
      }
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unknown error occurred';
      });
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
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  String sanitizeTopicName(String topic) {
    return topic.toLowerCase().replaceAll(' ', '_');
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
    );
  }
}
