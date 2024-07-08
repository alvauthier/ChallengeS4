class User {
  final String id;
  final String firstname;
  final String lastname;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['ID'],
      firstname: json['Firstname'],
      lastname: json['Lastname'],
    );
  }
}
