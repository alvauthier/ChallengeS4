import 'package:flutter/material.dart';
import 'package:weezemaster/core/models/interest.dart';

class UserInterestChip extends StatelessWidget {
  final Interest interest;
  final bool isSelected;
  final Function(Interest) onSelected;

  const UserInterestChip({
    required this.interest,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(interest.name),
      selected: isSelected,
      onSelected: (_) => onSelected(interest),
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}
