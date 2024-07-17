import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WebSocketDemo(
          channel: WebSocketChannel.connect(
            Uri.parse('ws://192.168.1.10:8080'),
          ),
      ),
    );
  }
}

class WebSocketDemo extends StatefulWidget {
  final WebSocketChannel channel;

  WebSocketDemo({required this.channel});

  @override
  _WebSocketDemoState createState() => _WebSocketDemoState();
}

class _WebSocketDemoState extends State<WebSocketDemo> {
  final TextEditingController _controller = TextEditingController(); // Initialisation du TextEditingController
  final List<Map<String, dynamic>> _messages = [];

  @override
  void dispose() {
    _controller.dispose(); // N'oubliez pas de disposer du contrôleur lorsque le widget est supprimé
    widget.channel.sink.close();
    super.dispose();
  }

  void _sendMessage() {
    print('Attempting to send message'); // Log for debugging
    if (_controller.text.isNotEmpty) {
      final message = {
        'content': _controller.text,
        'authorId': 'user_id', // Remplacez par l'ID réel de l'utilisateur
        'conversationId': 'conversation_id', // Remplacez par l'ID réel de la conversation
        'timestamp': DateTime.now().toIso8601String(),
      };
      try {
        widget.channel.sink.add(json.encode(message));
        _controller.clear();
        print('Message sent: $message'); // Log the sent message
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.channel.stream.listen((message) {
      print('Raw message received: $message'); // Log the received raw message
      setState(() {
        try {
          final decodedMessage = json.decode(message);
          print('Decoded message: $decodedMessage'); // Log the decoded message
          _messages.add(decodedMessage);
          print('Messages list updated: $_messages'); // Log the updated messages list
        } catch (e) {
          print('Error decoding message: $e');
        }
      });
    }, onError: (error) {
      print('WebSocket error: $error'); // Log WebSocket errors
    }, onDone: () {
      print('WebSocket closed'); // Log when WebSocket is closed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ListTile(
                    title: Text('${message['authorId']}: ${message['content']}'),
                    subtitle: Text(message['timestamp']),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller, // Associez le contrôleur au TextField
                      decoration: const InputDecoration(
                        labelText: 'Send a message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
