import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final buyerId = "68cdbafe-de01-418e-b148-b68015de23b9";
  final ticket = {
    "imageUrl": "https://picsum.photos/250?image=9",
    "concertName": "Eras Tour - Taylor Swift",
    "category": "Category",
    "price": "100",
    "maxPrice": "150",
  };
  final messages = [
    {
      "authorId": "23fe6fff-107c-4fd6-823f-a22c9dc90526",
      "content": "Je vais changer le prix avant que vous ne l'achetiez.",
      "readed": true,
      "sendAt": "2021-10-01T10:00:00Z"
    },
    {
      "authorId": "23fe6fff-107c-4fd6-823f-a22c9dc90526",
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

  void _showChangePriceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _priceController = TextEditingController(text: ticket["price"]);
        return AlertDialog(
          title: const Text(
              'Nouveau prix',
              style: TextStyle(fontFamily: 'Readex Pro', fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                final newPrice = double.tryParse(newValue.text);
                if (newPrice != null && newPrice > double.parse(ticket["maxPrice"]!)) {
                  return oldValue;
                }
                return newValue;
              }),
            ],
            style: const TextStyle(fontFamily: 'Readex Pro', fontSize: 40),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepOrange, width: 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.deepOrange, fontFamily: 'Readex Pro'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final newPrice = _priceController.text;
                      if (newPrice.isNotEmpty) {
                        setState(() {
                          ticket["price"] = newPrice;
                        });
                      }
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    child: const Text(
                      'Changer le prix',
                      style: TextStyle(color: Colors.white, fontFamily: 'Readex Pro'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
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
              imageUrl: ticket["imageUrl"] as String,
              concertName: ticket["concertName"] as String,
              category: ticket["category"] as String,
              price: ticket["price"] as String,
              onCancel: () {
                // Handle cancel action
              },
              secondAction: () {
                if (buyerId == userId) {
                  // Handle buy action
                } else {
                  _showChangePriceDialog();
                }
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
                    icon: const Icon(
                        Icons.send,
                        color: Colors.deepOrange,
                    ),
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