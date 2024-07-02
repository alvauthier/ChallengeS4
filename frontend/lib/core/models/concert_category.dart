class ConcertCategory {
  final String id;
  final int availableTickets;
  final int soldTickets;
  final int price;

  ConcertCategory({
    required this.id,
    required this.availableTickets,
    required this.soldTickets,
    required this.price
  });

  factory ConcertCategory.fromJson(Map<String, dynamic> json) {
    return ConcertCategory(
      id: json['ID'],
      availableTickets: json['AvailableTickets'] ?? 0,
      soldTickets: json['SoldTickets'] ?? 0,
      price: json['Price'] ?? 0
    );
  }
}