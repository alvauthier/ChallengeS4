import 'package:flutter/material.dart';
import 'package:weezemaster/login_screen.dart';
import 'package:weezemaster/register_screen.dart';
import 'package:weezemaster/register_organization_screen.dart';
import 'package:weezemaster/translation.dart';

import 'components/adaptive_navigation_bar.dart';


class LoginRegisterScreen extends StatelessWidget {
  static const String routeName = '/login-register';

  static navigateTo(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const LoginRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: <Widget>[
              AppBar(
                title: Text(
                  translate(context)!.welcome,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          LoginScreen.navigateTo(context);
                        },
                        child: Text(translate(context)!.login),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          RegisterScreen.navigateTo(context);
                        },
                        child: Text(translate(context)!.create_account),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                         RegisterOrganisationScreen.navigateTo(context);
                        },
                        child: Text(translate(context)!.create_organization_account),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const AdaptiveNavigationBar(),
    );
  }
}
