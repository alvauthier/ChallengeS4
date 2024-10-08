import 'package:weezemaster/core/models/ticket_listing.dart';
import 'package:weezemaster/core/models/seller_buyer.dart';

class Conversation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String buyerId;
  final SellerBuyer buyer;
  final String sellerId;
  final SellerBuyer seller;
  final String ticketListingId;
  final TicketListing ticketListing;
  final List messages;
  final double price;

  Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.buyerId,
    required this.buyer,
    required this.sellerId,
    required this.seller,
    required this.ticketListingId,
    required this.ticketListing,
    required this.messages,
    required this.price,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['ID'],
      createdAt: DateTime.parse(json['CreatedAt']),
      updatedAt: DateTime.parse(json['UpdatedAt']),
      buyerId: json['BuyerId'],
      buyer: SellerBuyer.fromJson(json['Buyer']),
      sellerId: json['SellerId'],
      seller: SellerBuyer.fromJson(json['Seller']),
      ticketListingId: json['TicketListingId'],
      ticketListing: TicketListing.fromJson(json['TicketListing']),
      messages: json['Messages'] ?? [],
      price: (json['Price'] ?? 0).toDouble(),
    );
  }
}