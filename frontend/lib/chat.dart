import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'components/message_bubble.dart';
import 'login_register_screen.dart';
import 'components/ticket_details.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final otherUser = "Michelle Obama";
  final buyerId = "2593e40d-1275-4096-a9bb-ff8b8947a929";
  final messages = [
    {
      "authorId": "2593e40d-1275-4096-a9bb-ff8b8947a929",
      "content": "Je vais changer le prix avant que vous ne l'achetiez.",
      "readed": true,
      "sendAt": "2021-10-01T10:00:00Z"
    },
    {
      "authorId": "2593e40d-1275-4096-a9bb-ff8b8947a929",
      "content": "Bonjour, ça me va je souhaite m'en débarraser rapidement !",
      "readed": true,
      "sendAt": "2021-10-01T10:00:00Z"
    },
    {
      "authorId": "68cdbafe-de01-418e-b148-b68015de23b9",
      "content": "Bonjour je souhaiterais acheter le ticket à 100€, est-ce que c'est possible ?",
      "readed": true,
      "sendAt": "2021-10-01T10:01:00Z"
    }
  ];
  final TextEditingController _controller = TextEditingController();
  final storage = const FlutterSecureStorage();
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      setState(() {
        userId = decodedToken['id'] as String;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
      );
    }
  }

  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  void _sendMessage() {
    final content = _controller.text;
    if (content.isEmpty || userId == null) {
      return;
    }

    final Map<String, Object> newMessage = {
      "authorId": userId!,
      "content": content,
      "readed": false,
      "sendAt": DateTime.now().toIso8601String()
    };

    setState(() {
      messages.insert(0, newMessage);
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Négociation avec $otherUser',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Readex Pro',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TicketDetails(
              imageUrl: 'https://picsum.photos/250?image=9',
              concertName: 'Eras Tour - Taylor Swift',
              category: 'Category',
              price: '100€',
              onCancel: () {
                // Handle cancel action
              },
              secondAction: () {
                // Handle change price action
              },
              secondActionText: buyerId == userId ? 'Acheter' : 'Changer le prix',
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final authorId = message["authorId"] as String? ?? "";
                  final content = message["content"] as String? ?? "";
                  final isCurrentUser = authorId == userId;
                  return Column(
                    children: [
                      MessageBubble(
                        authorId: authorId,
                        content: content,
                        isCurrentUser: isCurrentUser,
                        sendAt: formatDate(message["sendAt"] as String? ?? ""),
                        readed: message["readed"] as bool? ?? false,
                      ),
                      const SizedBox(height: 10), // Add space between bubbles
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Saisissez votre message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
      )
    );
  }
}