import 'package:flutter/material.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Billets'),
      ),
      body: Center(
        child: Text('Voici la page de mes billets'),
      ),
    );
  }
}
