import 'package:weezemaster/core/models/ticket.dart';
import 'package:weezemaster/core/models/conversation.dart';

class User {
  final String id;
  final String firstname;
  final String lastname;
  final List<Ticket> tickets;
  final List<Conversation> conversations;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.tickets,
    required this.conversations,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['ID'],
      firstname: json['Firstname'],
      lastname: json['Lastname'],
      tickets: (json['Tickets'] as List<dynamic>?)?.map((e) => Ticket.fromJson(e)).toList() ?? [],
      conversations: (json['Conversations'] as List<dynamic>?)?.map((e) => Conversation.fromJson(e)).toList() ?? [],
    );
  }
}
