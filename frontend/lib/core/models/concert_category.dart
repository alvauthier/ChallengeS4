import 'package:frontend/core/models/ticket.dart';

class ConcertCategory {
  final String id;
  final int availableTickets;
  final int soldTickets;
  final int price;
  final List<Ticket> tickets;

  ConcertCategory({
    required this.id,
    required this.availableTickets,
    required this.soldTickets,
    required this.price,
    required this.tickets,
  });

  factory ConcertCategory.fromJson(Map<String, dynamic> json) {
    var ticketListFromJson = json['Tickets'] as List? ?? [];
    List<Ticket> ticketList = ticketListFromJson.map((i) => Ticket.fromJson(i)).toList();

    return ConcertCategory(
      id: json['ID'],
      availableTickets: json['AvailableTickets'] ?? 0,
      soldTickets: json['SoldTickets'] ?? 0,
      price: json['Price'] ?? 0,
      tickets: ticketList,
    );
  }
}