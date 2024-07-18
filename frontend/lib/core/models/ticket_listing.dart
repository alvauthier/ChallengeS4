class TicketListing {
  final String id;
  final double price;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketListing({
    required this.id,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketListing.fromJson(Map<String, dynamic> json) {
    return TicketListing(
      id: json['ID'],
      price: json['Price'],
      status: json['Status'],
      createdAt: DateTime.parse(json['CreatedAt']),
      updatedAt: DateTime.parse(json['UpdatedAt']),
    );
  }
}