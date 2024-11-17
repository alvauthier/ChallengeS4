import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
              const Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        translate(context)!.welcome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontFamily: 'Readex Pro',
                          fontWeight: FontWeight.bold,
                          height: 0.9,
                        ),
                      ),
                      const SizedBox(height: 50),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            context.pushNamed('login');
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            backgroundColor: Colors.deepOrange,
                          ),
                          child: Text(
                            translate(context)!.login,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Readex Pro',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            context.pushNamed('register');
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              side: const BorderSide(color: Colors.white),
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                          child: Text(
                            translate(context)!.create_account,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Readex Pro',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            context.pushNamed('register-organization');
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              side: const BorderSide(color: Colors.white),
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                          child: Text(
                            translate(context)!.create_organization_account,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Readex Pro',
                              fontSize: 16,
                            ),
                          ),
                        ),
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