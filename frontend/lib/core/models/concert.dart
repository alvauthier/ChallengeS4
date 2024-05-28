class Concert {
  final String id;
  final String name;
  final DateTime date;
  final String location;

  Concert({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
  });

  factory Concert.fromJson(Map<String, dynamic> json) {
    return Concert(
      id: json['ID'],
      name: json['Name'],
      date: json['Date'],
      location: json['Location'],
    );
  }
}