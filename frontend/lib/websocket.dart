import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String apiHost = dotenv.env['API_HOST']!;
    final String apiPort = dotenv.env['API_PORT']!;
    final String webSocketUrl = 'ws://$apiHost:$apiPort/ws';

    return MaterialApp(
      title: 'WebSocket Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WebSocketDemo(
        channel: WebSocketChannel.connect(
          Uri.parse(webSocketUrl),
        ),
        conversationId: '', // ConversationId par défaut, peut être remplacé plus tard
      ),
    );
  }
}

class WebSocketDemo extends StatefulWidget {
  final WebSocketChannel channel;
  final String conversationId;

  WebSocketDemo({required this.channel, required this.conversationId});

  @override
  _WebSocketDemoState createState() => _WebSocketDemoState();
}

class _WebSocketDemoState extends State<WebSocketDemo> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final Uuid uuid = Uuid();

  @override
  void dispose() {
    _controller.dispose();
    widget.channel.sink.close();
    super.dispose();
  }

  void _sendMessage() {
    print('Attempting to send message');
    if (_controller.text.isNotEmpty) {
      final message = {
        'content': _controller.text,
        'authorId': uuid.v4(),
        'conversationId': widget.conversationId, // Utilise l'UUID de la conversation
        'timestamp': DateTime.now().toIso8601String(),
      };
      try {
        widget.channel.sink.add(json.encode(message));
        _controller.clear();
        print('Message sent: $message');
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.channel.stream.listen((message) {
      print('Raw message received: $message');
      setState(() {
        try {
          final decodedMessage = json.decode(message);
          print('Decoded message: $decodedMessage');
          _messages.add(decodedMessage);
          print('Messages list updated: $_messages');
        } catch (e) {
          print('Error decoding message: $e');
        }
      });
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocket Chat'),
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
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Send a message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
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
