import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'components/adaptive_navigation_bar.dart';
import 'components/message_bubble.dart';
import 'components/ticket_details.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ChatScreen extends StatefulWidget {
  static const String routeName = '/chat';

  String id;
  final String? userId;
  final String? resellerId;
  final String? ticketId;
  final String? concertName;
  final String? price;
  final String? resellerName;
  final String? category;

  ChatScreen({super.key, required this.id, this.userId, this.resellerId, this.ticketId, this.concertName, this.price, this.resellerName, this.category});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  // final otherUser = "Michelle Obama";
  late String buyerId = "";
  late Map<String, String> ticket = {
    "imageUrl": "https://picsum.photos/250?image=9",
    // "concertName": "Eras Tour - Taylor Swift",
    // "category": "Category",
    // "price": "100",
    "maxPrice": "150",
  };
  late List messages = [];
  final TextEditingController _controller = TextEditingController();
  final storage = const FlutterSecureStorage();
  String? userId;
  late String concertName;
  late String price;
  late String resellerName;
  late String category;

  late WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();

    if (widget.id.isEmpty) {
      concertName = widget.concertName!;
      price = widget.price!;
      resellerName = widget.resellerName!;
      category = widget.category!;
    } else {
      concertName = "";
      price = "";
      resellerName = "";
      category = "";
      _fetchConversation();
    }
    _loadUserId().then((_) {
      _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }

  void _connectWebSocket() {
    // final protocol = dotenv.env['API_PROTOCOL'] == 'http' ? 'ws' : 'wss';
    final protocol = 'wss';
    final wsUrl = Uri.parse('$protocol://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ws');
    debugPrint('Attempting WebSocket connection to: $wsUrl');

    try {
      _channel = WebSocketChannel.connect(wsUrl);
    } catch (e) {
      debugPrint('Erreur lors de la connexion WebSocket: $e');
      return;
    }

    _channel!.stream.listen((message) {
      final decodedMessage = jsonDecode(message);

      if (decodedMessage.containsKey('conversation_id')) {
        setState(() {
          widget.id = decodedMessage['conversation_id'];
        });
      } else {
        setState(() {
          messages.add({
            "authorId": decodedMessage["AuthorId"],
            "content": decodedMessage["Content"],
            "readed": decodedMessage["Readed"],
          });
        });
      }
    }, onError: (error) {
      debugPrint('Erreur WebSocket: $error');
    }, onDone: () {
      debugPrint('WebSocket closed');
    });

    _initializeWebSocketConnection();
  }

  void _initializeWebSocketConnection() {
    final payload = {
      "conversation_id": widget.id.isNotEmpty ? widget.id : "",
      "sender_id": userId,
      "receiver_id": widget.resellerId,
    };

    _channel?.sink.add(jsonEncode(payload));
    debugPrint('Initial WebSocket payload sent: $payload');
  }

  Future<void> _loadUserId() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      setState(() {
        userId = decodedToken['id'] as String;
      });
    } else {
      if (mounted) {
        context.pushNamed('login-register');
      }
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

  Future<void> _fetchConversation() async {
    debugPrint("Fetching conversation with id: ${widget.id}");
    if (widget.id.isNotEmpty) {
      try {
        debugPrint("In try Fetching conversation with id: ${widget.id}");
        final conversation = await ApiServices.getConversation(widget.id);
        debugPrint("Conversation: $conversation");
        setState(() {
          messages = conversation['Messages'].map((message) => {
            "authorId": message['AuthorId'],
            "content": message['Content'],
            "readed": message['Readed'],
          }).toList();
          debugPrint("Messages: $messages");
          buyerId = conversation["BuyerId"];
          if (conversation['Concert'] != null) {
            concertName = conversation['Concert']['Name'] ?? "Unknown Concert";
            price = conversation['Price'].toString();
            resellerName = conversation['SellerName'] ?? "Unknown Seller";
            category = conversation['Category'] ?? "Unknown Category";
          } else {
            concertName = "Fallback Concert";
            price = "10000000000";
            resellerName = "Fallback Reseller";
            category = "Fallback Category";
          }
        });
      } catch (e) {
        if (e is ApiException) {
          debugPrint("Failed to fetch conversation: ${e.toString()}");
        } else {
          debugPrint("Unexpected error: ${e.toString()}");
        }
      }
    }
  }

  void _sendMessage() async {
    final content = _controller.text;
    if (content.isEmpty || userId == null) {
      return;
    }

    if (widget.id.isEmpty) {
      try {
        final newConversation = await ApiServices.postConversation(widget.userId!, widget.resellerId!, widget.ticketId!);
        setState(() {
          widget.id = newConversation;
        });

        _channel?.sink.close(status.goingAway);
        _connectWebSocket();
      } catch (e) {
        debugPrint("Erreur lors de la création de la conversation: $e");
        return;
      }
    }

    final message = {
      "AuthorId": userId,
      "Content": content,
      "ConversationId": widget.id,
    };

    _channel?.sink.add(jsonEncode(message));
    debugPrint('Message sent via WebSocket: $message');

    _controller.clear();
  }

  void _showChangePriceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController priceController = TextEditingController(text: ticket["price"]);
        return AlertDialog(
          title: const Text(
              'Nouveau prix',
              style: TextStyle(fontFamily: 'Readex Pro', fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: priceController,
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
                      context.pop();
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
                      final newPrice = priceController.text;
                      if (newPrice.isNotEmpty) {
                        setState(() {
                          ticket["price"] = newPrice;
                        });
                      }
                      context.pop();
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
          'Chat avec $resellerName',
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
              concertName: concertName,
              category: category,
              price: price,
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
      ),
    );
  }
}