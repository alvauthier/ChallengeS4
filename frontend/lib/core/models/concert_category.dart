class ConcertCategory {
  final String id;
  final int numberTickets;
  final int price;

  ConcertCategory({
    required this.id,
    required this.numberTickets,
    required this.price
  });

  factory ConcertCategory.fromJson(Map<String, dynamic> json) {
    return ConcertCategory(
      id: json['ID'],
      numberTickets: json['NumberTickets'] ?? 0,
      price: json['Price'] ?? 0
    );
  }
}