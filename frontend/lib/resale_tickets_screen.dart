import 'package:flutter/material.dart';
import 'package:weezemaster/components/resale_ticket.dart';
import 'package:weezemaster/translation.dart';

class ResaleTicketsScreen extends StatelessWidget {
  final List resaleTickets;

  const ResaleTicketsScreen({super.key, required this.resaleTickets});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate(context)!.all_tickets_resale),
      ),
      body: ListView.builder(
        itemCount: resaleTickets.length,
        itemBuilder: (context, index) {
          var resaleTicket = resaleTickets[index];
          return ResaleTicket(ticket: Ticket.fromMap(resaleTicket));
        },
      ),
    );
  }
}
