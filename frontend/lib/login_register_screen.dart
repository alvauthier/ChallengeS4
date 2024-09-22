import 'package:flutter/material.dart';
import 'package:weezemaster/login_screen.dart';
import 'package:weezemaster/register_screen.dart';
import 'package:weezemaster/register_organization_screen.dart';

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
                title: const Text(
                  'Bienvenue sur Weezemaster !',
                  style: TextStyle(color: Colors.white),
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
                        child: const Text('Se connecter'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          RegisterScreen.navigateTo(context);
                        },
                        child: const Text('Créer un compte'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                         RegisterOrganisationScreen.navigateTo(context);
                        },
                        child: const Text('Créer un compte d\'organisation'),
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
