import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.jpg"), // Remplacez par le chemin de votre image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: <Widget>[
              AppBar(
                title: Text(
                  'Bienvenue sur Weezevent !',
                  style: TextStyle(color: Colors.white), // Change la couleur du texte
                ),
                backgroundColor: Colors.transparent, // Rend l'app bar transparente
                elevation: 0, // Supprime l'ombre sous l'app bar
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to the login screen
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                        },
                        child: Text('Se connecter'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to the sign up screen
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
                        },
                        child: Text('Créer un compte'),
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
