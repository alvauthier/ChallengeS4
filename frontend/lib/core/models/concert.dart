import 'package:weezemaster/core/models/artist.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/core/models/organization.dart';
import 'package:weezemaster/core/models/concert_category.dart';

class Concert {
  final String id;
  final String name;
  final String description;
  final String date;
  final String location;
  final String? image;
  final List<Interest> interests;
  final Organization organization;
  final List<ConcertCategory> concertCategories;
  final String? createdAt;
  final String artistId;
  final Artist artist;

  Concert({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.image,
    required this.location,
    required this.interests,
    required this.organization,
    required this.concertCategories,
    required this.artistId,
    required this.artist,
    this.createdAt
  });

  factory Concert.fromJson(Map<String, dynamic> json) {
    var interestListFromJson = json['Interests'] as List? ?? [];
    List<Interest> interestList = interestListFromJson.map((i) => Interest.fromJson(i)).toList();

    var organizationFromJson = json['Organization'] != null ? Organization.fromJson(json['Organization']) : Organization(id: '', name: '');

    var concertCategoryListFromJson = json['ConcertCategories'] as List? ?? [];
    List<ConcertCategory> concertCategoryList = concertCategoryListFromJson.map((i) => ConcertCategory.fromJson(i)).toList();

    var artistFromJson = json['Artist'] != null ? Artist.fromJson(json['Artist']) : Artist(id: '', name: '', interestId: 0);

    return Concert(
        id: json['ID'],
        name: json['Name'],
        description: json['Description'],
        date: json['Date'],
        image: json['Image'],
        location: json['Location'],
        interests: interestList,
        organization: organizationFromJson,
        concertCategories: concertCategoryList,
        artistId: json['ArtistId'],
        artist: artistFromJson,
        createdAt: json['CreatedAt'],
    );
  }
}