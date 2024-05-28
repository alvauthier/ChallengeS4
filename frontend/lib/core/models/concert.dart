class Concert {
  final String id;
  final String name;
  final String description;
  final String date;
  final String location;

  Concert({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
  });

  factory Concert.fromJson(Map<String, dynamic> json) {
    return Concert(
      id: json['ID'],
      name: json['Name'],
      description: json['Description'],
      date: json['Date'],
      location: json['Location'],
    );
  }
}