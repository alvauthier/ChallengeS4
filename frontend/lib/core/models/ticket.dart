import 'dart:ffi';

import 'package:weezemaster/core/models/concert_category.dart';
import 'package:weezemaster/core/models/user.dart';
import 'package:weezemaster/core/models/ticket_listing.dart';

class Ticket {
  final String id;
  final User user;
  final ConcertCategory concertCategory;
  final List<TicketListing> ticketListings;
  final double maxPrice;

  Ticket({
    required this.id,
    required this.user,
    required this.concertCategory,
    required this.ticketListings,
    required this.maxPrice,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['ID'],
      user: User.fromJson(json['User']),
      concertCategory: ConcertCategory.fromJson(json['ConcertCategory']),
      ticketListings: (json['TicketListings'] as List? ?? []).map((i) => TicketListing.fromJson(i)).toList(),
      maxPrice: (json['MaxPrice'] ?? 0).toDouble(),
    );
  }
}
