import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/models/concert.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/core/services/websocket_service.dart';

class ConcertListItem extends StatelessWidget {
  final Concert concert;
  final bool showArtistName;

  ConcertListItem({super.key, required this.concert, this.showArtistName = true});

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  final webSocketService = WebSocketService();
  
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final tokenService = TokenService();
        String? token = await tokenService.getValidAccessToken();
        if (token == null) {
          context.pushNamed(
            'concert',
            pathParameters: {'id': concert.id},
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

          debugPrint('Joining queue or concert page for concert: ${concert.id} and user: $userId');
          await joinQueueOrConcertPage(context, concert.id, userId);
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
                  (concert.image != null && concert.image!.isNotEmpty)
                      ? '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/uploads/concerts/${concert.image}'
                      : 'https://picsum.photos/seed/picsum/800/400',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                child: Text(
                  showArtistName ? '${concert.artist.name} : ${concert.name}' : concert.name,
                  style: const TextStyle(
                    fontFamily: 'Readex Pro',
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 20.0),
                child: Text(
                  formatDate(concert.date),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontFamily: 'Readex Pro',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                child: Text(
                  concert.location,
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