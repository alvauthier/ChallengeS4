import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/models/concert.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/core/services/websocket_service.dart';
import 'package:weezemaster/core/services/api_services.dart';

class ConcertListItem extends StatefulWidget {
  final Concert concert;
  final bool showArtistName;

  ConcertListItem({super.key, required this.concert, this.showArtistName = true});

  @override
  _ConcertListItemState createState() => _ConcertListItemState();
}

class _ConcertListItemState extends State<ConcertListItem> {
  final webSocketService = WebSocketService();
  String userRole = '';

  @override
  void initState() {
    super.initState();
    getUserRole();
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  Future<void> joinQueueOrConcertPage(BuildContext context, String concertId, String userId) async {
    webSocketService.connect(concertId, userId);

    // Accès au flux de diffusion
    final broadcastStream = webSocketService.stream;
    
    if (broadcastStream == null) {
      debugPrint('Failed to get WebSocket broadcast stream.');
      return;
    }

    broadcastStream.listen(
      (event) {
        final data = jsonDecode(event);

        if (data['isFirstMessage'] == true && data['status'] == 'access_granted') {
          context.pushNamed(
            'concert',
            pathParameters: {'id': concertId},
            extra: {
              'webSocketService': webSocketService,
            },
          );
        } else if (data['isFirstMessage'] == true && data['status'] == 'in_queue') {
          context.pushNamed(
            'queue',
            extra: {
              'position': data['position'],
              'webSocketService': webSocketService,
            },
          );
        }
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
      },
      onDone: () {
        debugPrint('WebSocket connection closed.');
      },
    );
  }

  Future<void> getUserRole() async {
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();

    if (jwtToken != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwtToken);

      final user = await ApiServices.getUser(decodedToken['id'] as String);
      setState(() {
        userRole = user.role;
      });
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final tokenService = TokenService();
        String? token = await tokenService.getValidAccessToken();
        if (token == null || userRole == 'organizer' || userRole == 'admin') {
          context.pushNamed(
            'concert',
            pathParameters: {'id': widget.concert.id},
          );
        } else {
          final parts = token.split('.');
          if (parts.length != 3) {
            throw Exception('Invalid token');
          }

          String output = parts[1].replaceAll('-', '+').replaceAll('_', '/');
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

          String userId = json.decode(utf8.decode(base64.decode(output)))['id'];

          debugPrint('Joining queue or concert page for concert: ${widget.concert.id} and user: $userId');
          await joinQueueOrConcertPage(context, widget.concert.id, userId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Image.network(
                  (widget.concert.image != null && widget.concert.image!.isNotEmpty)
                      ? '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/uploads/concerts/${widget.concert.image}'
                      : 'https://picsum.photos/seed/picsum/800/400',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                child: Text(
                  widget.showArtistName ? '${widget.concert.artist.name} : ${widget.concert.name}' : widget.concert.name,
                  style: const TextStyle(
                    fontFamily: 'Readex Pro',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 20.0),
                child: Text(
                  formatDate(widget.concert.date),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontFamily: 'Readex Pro',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                child: Text(
                  widget.concert.location,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Readex Pro',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}