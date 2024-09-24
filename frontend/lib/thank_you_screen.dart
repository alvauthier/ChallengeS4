import 'package:flutter/material.dart';
import 'package:weezemaster/translation.dart';

import 'components/adaptive_navigation_bar.dart';

class ThankYouScreen extends StatelessWidget {
  static const String routeName = '/thank-you';

  static navigateTo(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/thanks.gif'),
              const SizedBox(height:70),
              Text(
                translate(context)!.thanks,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                translate(context)!.thanks_message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(translate(context)!.back_home),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdaptiveNavigationBar(),
    );
  }
}
