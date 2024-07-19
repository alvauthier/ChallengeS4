import 'package:flutter/material.dart';

void main() {
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AdminPanel(),
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Tickets'),
              Tab(text: 'Ticket Listings'),
              Tab(text: 'Organizations'),
              Tab(text: 'Messages'),
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
            MessagesScreen(),
            InterestsScreen(),
            CategoriesScreen(),
            ConcertsScreen(),
          ],
        ),
      ),
    );
  }
}

// Example data models (replace with actual models)
class User {
  final int id;
  final String username;
  final String firstname;
  final String lastname;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.role,
  });
}

class Ticket {
  final int id;
  final int userId;
  final bool booked;

  Ticket({
    required this.id,
    required this.userId,
    required this.booked,
  });
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

class Organization {
  final int id;
  final String name;

  Organization({
    required this.id,
    required this.name,
  });
}

class Message {
  final int id;
  final String content;
  final int conversationId;

  Message({
    required this.id,
    required this.content,
    required this.conversationId,
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

// Screens for each section (implement logic as needed)
class UsersScreen extends StatelessWidget {
  final List<User> users = [
    User(id: 1, username: 'johndoe', firstname: 'John', lastname: 'Doe', role: 'admin'),
    // Add more users here
  ];

  UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            title: Text(user.username),
            subtitle: Text('${user.firstname} ${user.lastname} - ${user.role}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit user logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Delete user logic
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

class TicketsScreen extends StatelessWidget {
  final List<Ticket> tickets = [
    Ticket(id: 1, userId: 1, booked: true),
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
            subtitle: Text('User ID: ${ticket.userId}, Booked: ${ticket.booked}'),
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

class OrganizationsScreen extends StatelessWidget {
  final List<Organization> organizations = [
    Organization(id: 1, name: 'Org 1'),
    // Add more organizations here
  ];

  OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: organizations.length,
        itemBuilder: (context, index) {
          final organization = organizations[index];
          return ListTile(
            title: Text(organization.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit organization logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Delete organization logic
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

class MessagesScreen extends StatelessWidget {
  final List<Message> messages = [
    Message(id: 1, content: 'Hello World', conversationId: 1),
    // Add more messages here
  ];

  MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ListTile(
            title: Text('Message ID: ${message.id}'),
            subtitle: Text(message.content),
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
