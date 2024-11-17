import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/models/artist.dart';
import 'package:weezemaster/core/models/user.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/components/concert_list_item.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

import 'package:weezemaster/core/utils/constants.dart';
import 'package:weezemaster/translation.dart';

class ArtistScreen extends StatefulWidget {
  final String id;

  const ArtistScreen({super.key, required this.id});

  @override
  _ArtistScreenState createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Artist? artist;
  WebSocketChannel? _channel;
  List<Map<String, String>> messages = [];
  final TextEditingController _messageController = TextEditingController();
  final storage = const FlutterSecureStorage();
  String? userId;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchArtistAndConcerts();
    _loadUserIdAndFetchUser();
  }

  Future<void> _loadUserIdAndFetchUser() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      userId = decodedToken['id'] as String;
      currentUser = await ApiServices.getUser(userId!);
      setState(() {
        _connectWebSocket();
      });
    } else {
      if (mounted) {
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

  Future<void> _fetchArtistAndConcerts() async {
    artist = await ApiServices.getArtist(widget.id);
    setState(() {});
  }

  void _connectWebSocket() {
    final protocol = dotenv.env['API_PROTOCOL'] == 'http' ? 'ws' : 'wss';
    final wsUrl = Uri.parse('$protocol://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ws-community?artistId=${widget.id}');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen((message) {
      final decodedMessage = jsonDecode(message);
      setState(() {
        messages.add({
          "sender": decodedMessage["sender"],
          "content": decodedMessage["content"],
        });
      });
    }, onError: (error) {
      debugPrint('Erreur WebSocket: $error');
    }, onDone: () {
      debugPrint('WebSocket closed');
    });
  }

  void _sendMessage() {
    final content = _messageController.text;
    if (content.isEmpty) {
      return;
    }

    final message = {
      "artist_id": widget.id,
      "sender": '${currentUser!.firstname} ${currentUser!.lastname}',
      "content": content,
    };

    _channel?.sink.add(jsonEncode(message));
    _messageController.clear();
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(artist?.name ?? '${translate(context)!.loading}...'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Concerts'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: artist == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConcertsTab(),
                _buildChatTab(),
              ],
            ),
    );
  }

  Widget _buildConcertsTab() {
    return ListView.builder(
      itemCount: artist!.concerts.length,
      itemBuilder: (context, index) {
        final concert = artist!.concerts[index];
        return ConcertListItem(concert: concert, showArtistName: false);
      },
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ListTile(
                title: Text(message["content"]!),
                subtitle: Text(message["sender"]!),
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
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
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
    );
  }
}