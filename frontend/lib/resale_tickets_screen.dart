import 'package:flutter/material.dart';
import 'package:weezemaster/components/resale_ticket.dart';
import 'package:weezemaster/translation.dart';

import 'components/adaptive_navigation_bar.dart';

class ResaleTicketsScreen extends StatelessWidget {
  static const String routeName = '/resale-tickets';

  static Future<dynamic> navigateTo(BuildContext context, {required List resaleTickets}) async {
    return Navigator.of(context).pushNamed(routeName, arguments: resaleTickets);
  }

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
      bottomNavigationBar: const AdaptiveNavigationBar(),
    );
  }
}
