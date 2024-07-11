import 'package:flutter/material.dart';
import 'package:frontend/core/services/payment_services.dart';

class Ticket {
  final String id;
  final String category;
  final String price;
  final Reseller reseller;

  Ticket({required this.id, required this.category, required this.price, required this.reseller});

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'] as String,
      category: map['category'] as String,
      price: map['price'] as String,
      reseller: Reseller.fromMap(map['reseller'] as Map<String, dynamic>),
    );
  }
}

class Reseller {
  final String avatar;
  final String name;

  Reseller({required this.avatar, required this.name});

  factory Reseller.fromMap(Map<String, dynamic> map) {
    return Reseller(
      avatar: map['avatar'] as String,
      name: map['name'] as String,
    );
  }
}

class ResaleTicket extends StatelessWidget {
  final Ticket ticket;

  const ResaleTicket({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ticket.reseller.avatar,
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ticket.reseller.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${ticket.price} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                              color: Colors.deepOrangeAccent
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on),
                          Text(ticket.category),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                            child: const Text(
                              'Négocier',
                              style: TextStyle(
                                fontFamily: 'Readex Pro',
                                color: Colors.black
                              )
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final paymentIntentData = await paymentService.createPaymentIntent(ticket.id, 'tl_');
                              if (paymentIntentData != null) {
                                try {
                                  await paymentService.initAndPresentPaymentSheet(
                                    context,
                                    paymentIntentData['client_secret'],
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Paiement réussi')),
                                  );
                                  // missing proceedToReservation function (need to update the userId in ticket and archive the transaction)
                                } catch (e) {
                                  print('Error presenting payment sheet: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Echec du paiement')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to create payment intent')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              backgroundColor: Colors.deepOrange,
                            ),
                            child: const Text(
                              'Acheter',
                              style: TextStyle(
                                  fontFamily: 'Readex Pro'
                              )
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}