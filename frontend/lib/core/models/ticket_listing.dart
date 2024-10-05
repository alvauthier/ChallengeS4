import 'package:weezemaster/core/models/ticket.dart';

class TicketListing {
  final String id;
  final double price;
  final String status;
  final Ticket ticket;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketListing({
    required this.id,
    required this.price,
    required this.status,
    required this.ticket,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketListing.fromJson(Map<String, dynamic> json) {
    return TicketListing(
      id: json['ID'],
      price: (json['Price'] as num).toDouble(),
      status: json['Status'],
      ticket: Ticket.fromJson(json['Ticket']),
      createdAt: DateTime.parse(json['CreatedAt']),
      updatedAt: DateTime.parse(json['UpdatedAt']),
    );
  }
}