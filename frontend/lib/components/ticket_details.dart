import 'package:flutter/material.dart';

class TicketDetails extends StatelessWidget {
  final String imageUrl;
  final String concertName;
  final String category;
  final String price;
  final VoidCallback onCancel;
  final String secondActionText;
  final VoidCallback secondAction;

  const TicketDetails({
    super.key,
    required this.imageUrl,
    required this.concertName,
    required this.category,
    required this.price,
    required this.onCancel,
    required this.secondActionText,
    required this.secondAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  'https://picsum.photos/250?image=9',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concertName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        fontFamily: 'Readex Pro',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'Readex Pro',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$price€',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: Colors.deepOrangeAccent,
                          fontFamily: 'Readex Pro'
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.deepOrange, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.deepOrange, fontFamily: 'Readex Pro'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: secondAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                  ),
                  child: Text(
                    secondActionText,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Readex Pro'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}