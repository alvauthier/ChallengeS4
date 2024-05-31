import 'package:frontend/core/models/interest.dart';
import 'package:frontend/core/models/organization.dart';

class Concert {
  final String id;
  final String name;
  final String description;
  final String date;
  final String location;
  final List<Interest> interests;
  final Organization organization;

  Concert({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    required this.interests,
    required this.organization
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
        interests: interestList,
        organization: json['Organization'] != null ? Organization.fromJson(json['Organization']) : Organization(id: '', name: '')
    );
  }
}