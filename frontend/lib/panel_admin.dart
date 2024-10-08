import 'package:flutter/material.dart';
import 'package:weezemaster/admin/ticket_listings/ticket_listings.dart';
import 'package:weezemaster/admin/users/users.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/admin/tickets/tickets.dart';
import 'admin/categories/categories.dart';
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

class Concert {
  final int id;
  final String name;

  Concert({
    required this.id,
    required this.name,
  });
}

class ConcertsScreen extends StatelessWidget {
  final List<Concert> concerts = [
    Concert(id: 1, name: 'Concert 1'),
    // Add more concerts here
  ];

  ConcertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: concerts.length,
        itemBuilder: (context, index) {
          final concert = concerts[index];
          return ListTile(
            title: Text(concert.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit concert logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Delete concert logic
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
