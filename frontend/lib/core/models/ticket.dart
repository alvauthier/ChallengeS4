import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/models/ticket_listing.dart';

class Ticket {
  final String id;
  final User user;
  final TicketListing? ticketListing;

  Ticket({
    required this.id,
    required this.user,
    this.ticketListing,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['ID'],
      user: User.fromJson(json['User']),
      ticketListing: json['TicketListing'] != null ? TicketListing.fromJson(json['TicketListing']) : null,
    );
  }
}
