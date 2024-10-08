/*
import 'package:flutter/material.dart';
import 'package:weezemaster/core/models/ticket.dart';

class TicketsScreen extends StatelessWidget {
  final List<Ticket> tickets = [
    Ticket(id: '', user: null, concertCategory: null)
    // Add more tickets here
  ];

  TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return ListTile(
            title: Text('Ticket ID: ${ticket.id}'),
            subtitle: Text('User ID: ${ticket.user.id}, Booked: ${ticket.booked}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit ticket logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Delete ticket logic
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}*/
