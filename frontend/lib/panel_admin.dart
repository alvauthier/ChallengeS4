import 'package:flutter/material.dart';
import 'package:weezemaster/admin/ticket_listings/ticket_listings.dart';
import 'package:weezemaster/admin/users/users.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/admin/tickets/tickets.dart';
import 'admin/categories/categories.dart';
import 'admin/concerts/concerts.dart';
import 'admin/interests/interests.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(translate(context)!.admin_panel),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.deepOrange,
            indicatorColor: Colors.deepOrange,
            tabs: [
              Tab(text: translate(context)!.users),
              Tab(text: 'Tickets'),
              Tab(text: 'Ticket Listings'),
              Tab(text: 'Interests'),
              Tab(text: 'Categories'),
              Tab(text: 'Concerts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            UsersScreen(),
            const TicketsScreen(),
            const TicketListingsScreen(),
            InterestsScreen(),
            CategoriesScreen(),
            ConcertsScreen(),
          ],
        ),
      ),
    );
  }
}
