import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/translation.dart';
import 'components/message_bubble.dart';
import 'components/ticket_details.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;
import 'package:weezemaster/core/services/payment_services.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/core/utils/constants.dart';

import 'controller/navigation_cubit.dart';

class ChatScreen extends StatefulWidget {
  String id;
  final String? userId;
  final String? resellerId;
  final String? ticketId;
  final String? concertName;
  final String? price;
  final String? resellerName;
  final String? category;
  final String? concertImage;

  ChatScreen({super.key, required this.id, this.userId, this.resellerId, this.ticketId, this.concertName, this.price, this.resellerName, this.category, this.concertImage});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  bool _isLoading = true;

  late String otherUser = "";
  late String buyerId = "";
  late List messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final storage = const FlutterSecureStorage();
  String? userId;
  late String concertName;
  late String price;
  late String maxPrice;
  late String concertImage;
  late String resellerName;
  late String buyerName;
  late String category;

  late WebSocketChannel? _channel;

  Future<void> updateTicketListingStatus(BuildContext context, String conversationId) async {
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();

    final body = jsonEncode({
      'conversationId': conversationId,
    });

    try {
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ticket_listing_reservation_conversation/$conversationId';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('Ticket listing purchased');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context)!.ticket_success)),
        );
        context.pushNamed('thank-you');
      } else {
        debugPrint('Failed to update ticket listing status: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context)!.ticket_failed)),
        );
      }
    } catch (e) {
      debugPrint('Error updating ticket listing status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(context)!.generic_error)),
      );
    }
  }

  Future<void> updateConversationPrice(String conversationId, double price) async {
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();

    final body = jsonEncode({
      'price': price,
    });

    try {
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/conversations/$conversationId';
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('Price updated');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context)!.price_success)),
        );
        final priceMessage = {
          "conversation_id": widget.id,
          "new_price": price,
        };
        _channel?.sink.add(jsonEncode(priceMessage));
        debugPrint('Price update message WebSocket sent: $priceMessage');
      } else {
        debugPrint('Failed to update price: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context)!.price_failed)),
        );
        throw Exception('Failed to update price');
      }
    } catch (e) {
      debugPrint('Error updating price: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(context)!.generic_error)),
      );
      throw Exception('Error updating price');
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.id.isEmpty || widget.id == "newchat") {
      widget.id = '';
      concertName = widget.concertName ?? "Unknown Concert";
      price = widget.price ?? "0";
      maxPrice = widget.price ?? "0";
      otherUser = widget.resellerName ?? "Unknown Reseller";
      category = widget.category ?? "Unknown Category";
      buyerId = widget.userId ?? "";
      concertImage = widget.concertImage ?? "https://picsum.photos/seed/picsum/800/400";
      _isLoading = false;
    } else {
      concertName = "";
      price = "0";
      maxPrice = "0";
      otherUser = "";
      category = "";
      buyerId = "";
      concertImage = "";
      _fetchConversation();
    }
    _loadUserId().then((_) {
      _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _connectWebSocket() {
    final protocol = dotenv.env['API_PROTOCOL'] == 'http' ? 'ws' : 'wss';
    final wsUrl = Uri.parse('$protocol://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ws-chat');
    debugPrint('Attempting WebSocket connection to: $wsUrl');

    try {
      _channel = WebSocketChannel.connect(wsUrl);
    } catch (e) {
      debugPrint('Erreur lors de la connexion WebSocket: $e');
      return;
    }

    _channel!.stream.listen((message) {
      final decodedMessage = jsonDecode(message);
      debugPrint('WebSocket message received: $decodedMessage');
      if (decodedMessage.containsKey('conversation_id')) {
        setState(() {
          widget.id = decodedMessage['conversation_id'];
        });
        if (decodedMessage.containsKey('new_price')) {
          setState(() {
            price = decodedMessage['new_price'].toString();
          });
        }
      } else {
        debugPrint(decodedMessage["Content"]);
        setState(() {
          messages.add({
            "authorId": decodedMessage["AuthorId"],
            "content": decodedMessage["Content"],
            "readed": decodedMessage["Readed"],
          });
        });
        _scrollToBottom();
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
        context.read<NavigationCubit>().updateUserRole('');
        GoRouter.of(context).go(Routes.loginRegisterNamedPage);
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
    if (widget.id.isNotEmpty) {
      try {
        final conversation = await ApiServices.getConversation(widget.id);
        setState(() {
          messages = conversation['Messages'].map((message) => {
            "authorId": message['AuthorId'],
            "content": message['Content'],
            "readed": message['Readed'],
          }).toList();
          buyerId = conversation["BuyerId"];
          if (conversation['Concert'] != null) {
            concertName = conversation['Concert']['Name'] ?? "Unknown Concert";
            price = conversation['Price'].toString() ?? "0";
            maxPrice = conversation['TicketListing']['Price'].toString() ?? "0";
            resellerName = conversation['SellerName'] ?? "Unknown Seller";
            buyerName = conversation['BuyerName'] ?? "Unknown Buyer";
            category = conversation['Category'] ?? "Unknown Category";
            concertImage = conversation['Concert']['Image'] != ""
                ? '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/uploads/concerts/${conversation['Concert']['Image']}'
                : "https://picsum.photos/seed/picsum/800/400";
          } else {
            concertName = "Fallback Concert";
            price = "10000000000";
            maxPrice = "10000000000";
            resellerName = "Fallback Reseller";
            buyerName = "Fallback Buyer";
            category = "Fallback Category";
            concertImage = "https://picsum.photos/seed/picsum/800/400";
          }
          if(userId == buyerId) {
            otherUser = resellerName;
          } else {
            otherUser = buyerName;
          }
        });
        _isLoading = false;
        _scrollToBottom();
      } catch (e) {
        if (e is ApiException) {
          debugPrint("Failed to fetch conversation: ${e.toString()}");
        } else {
          debugPrint("Unexpected error: ${e.toString()}");
        }
        setState(() {
          _isLoading = false;
        });
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
        final TextEditingController priceController = TextEditingController(text: price);
        return AlertDialog(
          title: Text(
              translate(context)!.new_price,
              style: const TextStyle(fontFamily: 'Readex Pro', fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                final newPrice = double.tryParse(newValue.text);
                if (newPrice != null && newPrice > double.parse(maxPrice)) {
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
                    child: Text(
                      translate(context)!.cancel,
                      style: const TextStyle(color: Colors.deepOrange, fontFamily: 'Readex Pro'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newPrice = priceController.text;
                      if (newPrice.isNotEmpty) {
                        await updateConversationPrice(widget.id, double.parse(newPrice));
                      }
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    child: Text(
                      translate(context)!.confirm,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Readex Pro'),
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

  // void _handlePriceUpdate(Map<String, dynamic> message) {
  //   if (message.containsKey('new_price')) {
  //     setState(() {
  //       price = message['new_price'].toString();
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${translate(context)!.chat_with} $otherUser',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Readex Pro',
          ),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TicketDetails(
                concertName: concertName,
                category: category,
                price: price,
                concertImage: concertImage,
                showButtons: widget.id.isEmpty || widget.id == 'newchat' ? false : true,
                onCancel: () {
                  // Handle cancel action
                  context.pop();
                },
                secondAction: () async {
                  debugPrint('BuyerId: $buyerId');
                  debugPrint('UserId: $userId');
                  if (buyerId == userId) {
                    debugPrint('Buy');
                    final tokenService = TokenService();
                    String? token = await tokenService.getValidAccessToken();
                    if (token == null) {
                      context.read<NavigationCubit>().updateUserRole('');
                      GoRouter.of(context).go(Routes.loginRegisterNamedPage);
                    } else {
                      final paymentIntentData = await paymentService.createPaymentIntent(widget.id, 'cv_');
                      if (paymentIntentData != null) {
                        try {
                          await paymentService.initAndPresentPaymentSheet(
                            context,
                            paymentIntentData['client_secret'],
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(translate(context)!.payment_success)),
                          );
                          await updateTicketListingStatus(context, widget.id);
                        } catch (e) {
                          debugPrint('Error presenting payment sheet: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(translate(context)!.payment_failed)),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(translate(context)!.payment_error)),
                        );
                      }
                    }
                  } else {
                    _showChangePriceDialog();

                  }
                },
                secondActionText: buyerId == userId ? translate(context)!.buy : translate(context)!.change_price,
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final authorId = message["authorId"] as String? ?? "";
                    final content = message["content"] as String? ?? "";
                    final isCurrentUser = authorId == userId;

                    if (content.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        MessageBubble(
                          authorId: authorId,
                          content: content,
                          isCurrentUser: isCurrentUser,
                          readed: message["readed"] as bool? ?? false,
                        ),
                        const SizedBox(height: 10),
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
                          hintText: translate(context)!.enter_message,
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