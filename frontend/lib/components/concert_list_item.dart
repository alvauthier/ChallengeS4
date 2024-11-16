import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/models/concert.dart';
import 'package:intl/intl.dart';

class ConcertListItem extends StatelessWidget {
  final Concert concert;
  final bool showArtistName;

  const ConcertListItem({super.key, required this.concert, this.showArtistName = true});

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'concert',
          pathParameters: {'id': concert.id},
        );
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