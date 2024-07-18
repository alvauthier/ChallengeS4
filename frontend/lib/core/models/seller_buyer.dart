class SellerBuyer {
  final String firstname;
  final String lastname;

  SellerBuyer({
    required this.firstname,
    required this.lastname,
  });

  factory SellerBuyer.fromJson(Map<String, dynamic> json) {
    return SellerBuyer(
      firstname: json['Firstname'],
      lastname: json['Lastname'],
    );
  }
}