import 'package:frontend/core/models/interest.dart';

class Concert {
  final String id;
  final String name;
  final String description;
  final String date;
  final String location;
  final List<Interest> interests;

  Concert({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    required this.interests
  });

  factory Concert.fromJson(Map<String, dynamic> json) {
    var interestListFromJson = json['Interests'] as List? ?? [];
    List<Interest> interestList = interestListFromJson.map((i) => Interest.fromJson(i)).toList();

    return Concert(
        id: json['ID'],
        name: json['Name'],
        description: json['Description'],
        date: json['Date'],
        location: json['Location'],
        interests: interestList
    );
  }
}