import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/services/websocket_service.dart';

class QueueScreen extends StatefulWidget {
  final int initialPosition;
  final  WebSocketService webSocketService;

  const QueueScreen({
    Key? key,
    required this.initialPosition,
    required this.webSocketService,
  }) : super(key: key);

  @override
  _QueueScreenState createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.webSocketService.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = jsonDecode(snapshot.data as String);
          debugPrint('Donnéees reçues Queue Screen: ${snapshot.data}');
          debugPrint('Donnéees reçues Queue Screen: $data');
          if (data['status'] == 'access_granted') {
            context.pushReplacementNamed(
              'concert',
              pathParameters: {'id': data['concertId']},
            );
            return Container();
          } else {
            final position = data['position'];
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text("Votre position dans la file: $position"),
                ],
              ),
            );
          }
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text("Votre position dans la file: ${widget.initialPosition}"),
            ],
          ),
        );
      },
    );
  }
}
