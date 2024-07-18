import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/my_tickets/blocs/my_tickets_bloc.dart';
import 'package:http/http.dart' as http;

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({Key? key}) : super(key: key);

  @override
  State<MyTicketsScreen> createState() => MyTicketsScreenState();
}

class MyTicketsScreenState extends State<MyTicketsScreen> {
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MyTicketsBloc>().add(MyTicketsDataLoaded());
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  void _showResaleDialog(BuildContext context, ticket) {
    _priceController.text = '';
    final maxPrice = ticket.concertCategory.price;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Revendre le ticket'),
          content: TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Entrez le prix (max ${maxPrice.toStringAsFixed(2)} €)',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Revendre'),
              onPressed: () async {
                final enteredPrice = double.tryParse(_priceController.text);
                if (enteredPrice != null && enteredPrice <= maxPrice) {
                  await _resellTicket(ticket.id, enteredPrice);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le prix de revente ne peut pas dépasser le prix d\'achat.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resellTicket(String ticketId, double price) async {
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();

    final apiUrl =
        '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/ticketlisting';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({
        'ticketId': ticketId,
        'price': price,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket mis en vente avec succès!'),
        ),
      );
      context.read<MyTicketsBloc>().add(MyTicketsDataLoaded());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise en vente du ticket.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyTicketsBloc()..add(MyTicketsDataLoaded()),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: BlocBuilder<MyTicketsBloc, MyTicketsState>(
            builder: (context, state) {
              if (state is MyTicketsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is MyTicketsDataLoadingSuccess) {
                return Column(
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
                        itemCount: state.myTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = state.myTickets[index];
                          final concertCategory = ticket.concertCategory;
                          final concert = concertCategory.concert;
                          final category = concertCategory.category;

                          Widget actionButton;
                          if (ticket.ticketListing != null) {
                              actionButton = ElevatedButton(
                                onPressed: () {
                                  // Implement cancellation logic
                                  // _cancelResale(ticket.ticketListing.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text(
                                  'Annuler revente',
                                  style: TextStyle(fontFamily: 'Readex Pro'),
                                ),
                              );
                          } else {
                            actionButton = ElevatedButton(
                              onPressed: () {
                                // Handle action for tickets with TicketListing null
                                _showResaleDialog(context, ticket);
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                backgroundColor: Colors.deepOrange,
                              ),
                              child: const Text(
                                'Revendre',
                                style: TextStyle(fontFamily: 'Readex Pro'),
                              ),
                            );
                          }

                          return Card(
                            child: ListTile(
                              title: Text(concert.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category.name),
                                  Text('${concert.location} - ${formatDate(concert.date)}'),
                                  if (ticket.ticketListing != null)
                                    const Text(
                                      'Proposé à la revente',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                ],
                              ),
                              trailing: actionButton,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              } else if (state is MyTicketsDataLoadingError) {
                return Center(child: Text(state.errorMessage));
              } else {
                return const Center(child: Text('Aucun ticket disponible.'));
              }
            },
          ),
        ),
      ),
    );
  }
}