class TicketListing {
  final String id;
  final double price;
  final String status;

  TicketListing({
    required this.id,
    required this.price,
    required this.status,
  });

  factory TicketListing.fromJson(Map<String, dynamic> json) {
    return TicketListing(
      id: json['ID'],
      price: json['Price'].toDouble(),
      status: json['Status'],
    );
  }
}
