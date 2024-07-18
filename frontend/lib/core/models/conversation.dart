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
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['ID'],
      createdAt: DateTime.parse(json['CreatedAt']),
      updatedAt: DateTime.parse(json['UpdatedAt']),
      buyerId: json['BuyerId'],
      buyer: json['Buyer'] != null ? SellerBuyer.fromJson(json['Buyer']) : SellerBuyer(firstname: '', lastname: ''),
      sellerId: json['SellerId'],
      seller: json['Seller'] != null ? SellerBuyer.fromJson(json['Seller']) : SellerBuyer(firstname: '', lastname: ''),
      ticketListingId: json['TicketListingId'],
      ticketListing: TicketListing.fromJson(json['TicketListing']),
    );
  }
}