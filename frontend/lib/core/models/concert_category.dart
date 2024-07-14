import 'package:weezemaster/core/models/category.dart';
import 'package:weezemaster/core/models/ticket.dart';

class ConcertCategory {
  final String id;
  final int availableTickets;
  final int soldTickets;
  final double price;
  final List<Ticket> tickets;
  final Category category;

  ConcertCategory({
    required this.id,
    required this.availableTickets,
    required this.soldTickets,
    required this.price,
    required this.tickets,
    required this.category 
  });

  factory ConcertCategory.fromJson(Map<String, dynamic> json) {
    var ticketListFromJson = json['Tickets'] as List? ?? [];
    List<Ticket> ticketList = ticketListFromJson.map((i) => Ticket.fromJson(i)).toList();

    return ConcertCategory(
      id: json['ID'],
      availableTickets: json['AvailableTickets'] ?? 0,
      soldTickets: json['SoldTickets'] ?? 0,
      price: (json['Price'] ?? 0).toDouble(),
      tickets: ticketList,
      category: Category.fromJson(json['Category']),
    );
  }
}