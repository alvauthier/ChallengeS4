import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class QueueScreen extends StatefulWidget {
  final int initialPosition;
  final Stream webSocketStream; // Utilisez le Stream en broadcast
  final WebSocketChannel webSocketChannel; // Si besoin pour la gestion

  const QueueScreen({
    Key? key,
    required this.initialPosition,
    required this.webSocketStream,
    required this.webSocketChannel,
  }) : super(key: key);

  @override
  _QueueScreenState createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.webSocketStream, // Utilise le Stream broadcast ici
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = jsonDecode(snapshot.data as String);

          if (data['status'] == 'access_granted') {
            context.pushReplacementNamed(
              'concert',
              pathParameters: {'id': data['concertId']},
            );
            widget.webSocketChannel.sink.close(); // Fermez ici si nécessaire
            return Container();
          } else {
            final position = data['position'];
            return Center(
              child: Text("Votre position dans la file: $position"),
            );
          }
        }

        return Center(
          child: Text("Votre position dans la file: ${widget.initialPosition}"),
        );
      },
    );
  }
}
