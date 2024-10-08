import 'package:flutter/material.dart';
import 'package:weezemaster/admin/users/users.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/admin/organizations/organizations.dart';
import 'package:weezemaster/admin/tickets/tickets.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
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
              Tab(text: 'Organizations'),
              Tab(text: 'Interests'),
              Tab(text: 'Categories'),
              Tab(text: 'Concerts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            UsersScreen(),
            TicketsScreen(),
            TicketListingsScreen(),
            OrganizationsScreen(),
            InterestsScreen(),
            CategoriesScreen(),
            ConcertsScreen(),
          ],
        ),
      ),
    );
  }
}

class TicketListing {
  final int id;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;

  TicketListing({
    required this.id,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });
}

class Interest {
  final int id;
  final String label;

  Interest({
    required this.id,
    required this.label,
  });
}

class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });
}

class Concert {
  final int id;
  final String name;

  Concert({
    required this.id,
    required this.name,
  });
}

class TicketListingsScreen extends StatelessWidget {
  final List<TicketListing> ticketListings = [
    TicketListing(id: 1, price: 50.0, createdAt: DateTime.now(), updatedAt: DateTime.now(), status: 'available'),
    // Add more ticket listings here
  ];

  TicketListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: ticketListings.length,
        itemBuilder: (context, index) {
          final ticketListing = ticketListings[index];
          return ListTile(
            title: Text('Ticket Listing ID: ${ticketListing.id}'),
            subtitle: Text('Price: \$${ticketListing.price}, Status: ${ticketListing.status}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit ticket listing logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Delete ticket listing logic
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

class InterestsScreen extends StatelessWidget {
  final List<Interest> interests = [
    Interest(id: 1, label: 'Music'),
    // Add more interests here
  ];

  InterestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: interests.length,
        itemBuilder: (context, index) {
          final interest = interests[index];
          return ListTile(
            title: Text(interest.label),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit interest logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Delete interest logic
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add interest logic
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  final List<Category> categories = [
    Category(id: 1, name: 'Category 1'),
    // Add more categories here
  ];

  CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            title: Text(category.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit category logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Delete category logic
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add category logic
        },
        child: const Icon(Icons.add),
      ),
    );
  }
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
