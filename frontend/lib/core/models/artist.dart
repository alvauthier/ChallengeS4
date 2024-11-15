import 'package:weezemaster/core/models/concert.dart';

class Artist {
  final String id;
  final String name;
  final int interestId;
  final List<Concert> concerts;

  Artist({
    required this.id,
    required this.name,
    required this.interestId,
    required this.concerts,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    var concertListFromJson = json['Concerts'] as List? ?? [];
    List<Concert> concertList = concertListFromJson.map((i) => Concert.fromJson(i)).toList();

    return Artist(
      id: json['ID'],
      name: json['Name'],
      interestId: json['InterestId'],
      concerts: concertList,
    );
  }
}