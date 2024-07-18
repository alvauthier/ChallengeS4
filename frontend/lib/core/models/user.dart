import 'package:weezemaster/core/models/ticket.dart';
import 'package:weezemaster/core/models/conversation.dart';

class User {
  final String id;
  final String firstname;
  final String lastname;
  final List<Ticket> tickets;
  final List<Conversation> conversationsAsBuyer;
  final List<Conversation> conversationsAsSeller;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.tickets,
    required this.conversationsAsBuyer,
    required this.conversationsAsSeller,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['ID'],
      firstname: json['Firstname'],
      lastname: json['Lastname'],
      tickets: json['Tickets'] != null ? List<Ticket>.from(json['Tickets'].map((e) => Ticket.fromJson(e))) : [],
      conversationsAsBuyer: (json['ConversationsAsBuyer'] as List<dynamic>?)?.map((e) => Conversation.fromJson(e)).toList() ?? [],
      conversationsAsSeller: (json['ConversationsAsSeller'] as List<dynamic>?)?.map((e) => Conversation.fromJson(e)).toList() ?? [],
    );
  }
}
