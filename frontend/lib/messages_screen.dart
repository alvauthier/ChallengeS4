import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Messages'),
      ),
      body: Center(
        child: Text('Voici la page de mes messages'),
      ),
    );
  }
}
