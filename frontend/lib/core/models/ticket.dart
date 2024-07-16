import 'package:weezemaster/core/models/concert_category.dart';
import 'package:weezemaster/core/models/user.dart';
import 'package:weezemaster/core/models/ticket_listing.dart';

class Ticket {
  final String id;
  final User user;
  final ConcertCategory concertCategory;
  final TicketListing? ticketListing;

  Ticket({
    required this.id,
    required this.user,
    required this.concertCategory,
    this.ticketListing,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['ID'],
      user: User.fromJson(json['User']),
      concertCategory: ConcertCategory.fromJson(json['ConcertCategory']),
      ticketListing: json['TicketListing'] != null ? TicketListing.fromJson(json['TicketListing']) : null,
    );
  }
}
