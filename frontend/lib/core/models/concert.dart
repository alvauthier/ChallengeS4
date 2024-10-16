import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/core/models/organization.dart';
import 'package:weezemaster/core/models/concert_category.dart';

class Concert {
  final String id;
  final String name;
  final String description;
  final String date;
  final String location;
  final List<Interest> interests;
  final Organization organization;
  final List<ConcertCategory> concertCategories;
  final String? createdAt;

  Concert({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    required this.interests,
    required this.organization,
    required this.concertCategories,
    this.createdAt
  });

  factory Concert.fromJson(Map<String, dynamic> json) {
    var interestListFromJson = json['Interests'] as List? ?? [];
    List<Interest> interestList = interestListFromJson.map((i) => Interest.fromJson(i)).toList();

    var organizationFromJson = json['Organization'] != null ? Organization.fromJson(json['Organization']) : Organization(id: '', name: '');

    var concertCategoryListFromJson = json['ConcertCategories'] as List? ?? [];
    List<ConcertCategory> concertCategoryList = concertCategoryListFromJson.map((i) => ConcertCategory.fromJson(i)).toList();

    return Concert(
        id: json['ID'],
        name: json['Name'],
        description: json['Description'],
        date: json['Date'],
        location: json['Location'],
        interests: interestList,
        organization: organizationFromJson,
        concertCategories: concertCategoryList,
        createdAt: json['CreatedAt'],
    );
  }
}