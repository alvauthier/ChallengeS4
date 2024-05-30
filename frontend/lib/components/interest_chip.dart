import 'package:flutter/material.dart';
import 'package:frontend/core/models/interest.dart';

class InterestChip extends StatelessWidget {
  final Interest interest;

  const InterestChip({super.key, required this.interest});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
          interest.name,
          style: const TextStyle(
              fontFamily: 'Readex Pro'
          )
      ),
      backgroundColor: Colors.deepOrange.shade100,
      shape: const StadiumBorder(),
      side: BorderSide.none,
    );
  }
}