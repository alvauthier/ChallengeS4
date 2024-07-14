import 'package:weezemaster/core/models/ticket.dart';

class User {
  final String id;
  final String firstname;
  final String lastname;
  final List<Ticket> tickets;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.tickets,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['ID'],
      firstname: json['Firstname'],
      lastname: json['Lastname'],
      tickets: json['Tickets'].mapList((e) => Ticket.fromJson(e)),
    );
  }
}
