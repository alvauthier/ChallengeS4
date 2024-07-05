import 'package:frontend/core/models/category.dart';

class ConcertCategory {
  final String id;
  final int numberTickets;
  final int price;
  final Category category;

  ConcertCategory({
    required this.id,
    required this.numberTickets,
    required this.price,
    required this.category
  });

  factory ConcertCategory.fromJson(Map<String, dynamic> json) {
    return ConcertCategory(
      id: json['ID'],
      numberTickets: json['NumberTickets'] ?? 0,
      price: json['Price'] ?? 0,
      category: Category.fromJson(json['Category'])
    );
  }
}