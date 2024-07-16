import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'components/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final buyer = "Michelle Obama";
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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    setState(() async {
      userId = await _secureStorage.read(key: 'id');
    });
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
          'Négociation avec $buyer',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Readex Pro',
          ),
        ),
      ),
      body: Column(
        children: [
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
    );
  }
}