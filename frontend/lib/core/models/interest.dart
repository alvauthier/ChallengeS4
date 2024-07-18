class Interest {
  final int id;
  final String name;

  Interest({
    required this.id,
    required this.name
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['ID'],
      name: json['Name'],
    );
  }
}