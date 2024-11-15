class Artist {
  final String id;
  final String name;
  final int interestId;

  Artist({
    required this.id,
    required this.name,
    required this.interestId
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['ID'],
      name: json['Name'],
      interestId: json['InterestId'],
    );
  }
}