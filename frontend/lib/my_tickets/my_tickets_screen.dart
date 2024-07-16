import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => MyTicketsScreenState();
}

class MyTicketsScreenState extends State<MyTicketsScreen> {
  final storage = const FlutterSecureStorage();
  String? userId;

  @override
  void initState() {
    super.initState();
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  static const tickets = [
    {
      "ID": "ccfe9840-6809-4743-90bb-17f613a2a38f",
      "CreatedAt": "2024-07-15T10:55:23.639966+02:00",
      "ConcertCategory": {
        "Concert": {
          "Name": "Eras Tour - Taylor Swift",
          "Location": "Paris La Défense Arena",
          "Date": "2024-08-15T10:55:23.624489+02:00"
        },
        "Category": {
          "Name": "Catégorie 4"
        }
      }
    },
    {
      "ID": "a280b260-b063-47bc-87fa-491e8e0c1e8e",
      "CreatedAt": "2024-07-15T11:02:03.11792+02:00",
      "ConcertCategory": {
        "Concert": {
          "Name": "Eras Tour - Taylor Swift",
          "Location": "Paris La Défense Arena",
          "Date": "2024-08-15T10:55:23.624489+02:00"
        },
        "Category": {
          "Name": "Fosse"
        }
      }
    }
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Vos tickets',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  final concertCategory = ticket['ConcertCategory'] as Map<String, dynamic>;
                  final concert = concertCategory['Concert'] as Map<String, dynamic>;
                  final category = concertCategory['Category'] as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      title: Text(concert['Name'] as String? ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category['Name'] as String? ?? ''),
                          Text('${concert['Location'] as String? ?? ''} - ${formatDate(concert['Date'] as String? ?? '1970-01-01T00:00:00.000Z')}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          backgroundColor: Colors.deepOrange,
                        ),
                        child: const Text(
                          'Revendre',
                          style: TextStyle(
                              fontFamily: 'Readex Pro'
                          )
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}