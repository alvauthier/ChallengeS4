import 'package:weezemaster/core/models/message.dart';
import 'package:weezemaster/core/models/ticket_listing.dart';

class Conversation {
  final int id;
  final String buyer;
  final String buyerId;
  final List<Message> messages;
  final TicketListing ticketListing;

  Conversation({
    required this.id,
    required this.buyer,
    required this.buyerId,
    required this.messages,
    required this.ticketListing
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['ID'],
      buyer: json['Buyer'],
      buyerId: json['BuyerID'],
      messages: json['Messages'],
      ticketListing: json['TicketListing']
    );
  }
}