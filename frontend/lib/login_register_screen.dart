import 'package:flutter/material.dart';
import 'package:weezemaster/login_screen.dart';
import 'package:weezemaster/register_screen.dart';
import 'package:weezemaster/register_organization_screen.dart';
import 'package:weezemaster/translation.dart';


class LoginRegisterScreen extends StatelessWidget {
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                        },
                        child: Text(translate(context)!.login),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                        },
                        child: Text(translate(context)!.create_account),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterOrganisationScreen()));
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
    );
  }
}
