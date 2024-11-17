import 'package:flutter/material.dart';
import 'package:weezemaster/admin/artists/artists.dart';
import 'package:weezemaster/admin/config_queue/config_queue_screen.dart';
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
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: Text(translate(context)!.admin_panel),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.deepOrange,
            indicatorColor: Colors.deepOrange,
            tabs: [
              Tab(text: translate(context)!.queue),
              Tab(text: translate(context)!.users),
              const Tab(text: 'Tickets'),
              const Tab(text: 'Ticket Listings'),
              Tab(text: translate(context)!.artists),
              Tab(text: translate(context)!.interests),
              Tab(text: translate(context)!.categories),
              const Tab(text: 'Concerts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const ConfigQueueScreen(),
            const UsersScreen(),
            const TicketsScreen(),
            const TicketListingsScreen(),
            ArtistsScreen(),
            InterestsScreen(),
            CategoriesScreen(),
            const ConcertsScreen(),
          ],
        ),
      ),
    );
  }
}
