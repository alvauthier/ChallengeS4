import 'package:flutter/material.dart';
import 'package:weezemaster/components/resale_ticket.dart';
import 'package:weezemaster/concert/blocs/concert_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResaleTicketsScreen extends StatelessWidget {
  final List resaleTickets;

  const ResaleTicketsScreen({super.key, required this.resaleTickets});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les tickets à la revente'),
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
