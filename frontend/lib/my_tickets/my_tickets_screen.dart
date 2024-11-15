import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/my_tickets/blocs/my_tickets_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:weezemaster/translation.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

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
    final maxPrice = ticket.maxPrice;

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
                context.pop();
              },
            ),
            TextButton(
              child: const Text('Revendre'),
              onPressed: () async {
                final enteredPrice = double.tryParse(_priceController.text);
                if (enteredPrice != null && enteredPrice <= maxPrice) {
                  await _resellTicket(ticket.id, enteredPrice);
                  context.pop();
                  context.pushNamed('my-tickets');
                } else {
                  context.pop();
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
        '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ticketlisting';

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

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket mis en vente avec succès!'),
          ),
        );
        context.pushNamed('my-tickets');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise en vente du ticket.'),
          ),
        );
      }
    }
  }

  Future<void> cancelTicketListing(String ticketListingId) async {
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();

    final apiUrl =
        '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ticketlisting/$ticketListingId';

    final response = await http.delete(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 204) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annulation de la mise en vente réussie !'),
          ),
        );
        context.pushNamed('my-tickets');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'annulation de la mise en vente.'),
          ),
        );
      }
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
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        translate(context)!.my_tickets,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

                          if (ticket.ticketListings.isNotEmpty) {
                            ticket.ticketListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                          }

                          Widget actionButton;
                          if (ticket.ticketListings.isNotEmpty) {
                            if (ticket.ticketListings.first.status == 'available') {
                              actionButton = ElevatedButton(
                                onPressed: () {
                                  cancelTicketListing(ticket.ticketListings.first.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                                child: Text(
                                  translate(context)!.cancel_resale,
                                  style: const TextStyle(fontFamily: 'Readex Pro'),
                                ),
                              );
                            }
                            else {
                              actionButton = ElevatedButton(
                              onPressed: () {
                                _showResaleDialog(context, ticket);
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                backgroundColor: Colors.deepOrange,
                              ),
                              child: Text(
                                translate(context)!.resell,
                                style: const TextStyle(fontFamily: 'Readex Pro'),
                              ),
                            );
                            }
                          } else {
                            actionButton = ElevatedButton(
                              onPressed: () {
                                _showResaleDialog(context, ticket);
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                backgroundColor: Colors.deepOrange,
                              ),
                              child: Text(
                                translate(context)!.resell,
                                style: const TextStyle(fontFamily: 'Readex Pro'),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                    child: Image.network(
                                      (concert.image != null && concert.image != '')
                                          ? '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/uploads/concerts/${concert.image}'
                                          : 'https://picsum.photos/seed/picsum/800/400',
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  ListTile(
                                    contentPadding: const EdgeInsets.all(10),
                                    title: Text(
                                        concert.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Readex Pro'
                                        ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: Text(
                                            category.name,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontFamily: 'Readex Pro',
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Text(
                                            '${concert.location} - ${formatDate(concert.date)}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontFamily: 'Readex Pro',
                                            ),
                                          ),
                                        ),
                                        if (ticket.ticketListings.isNotEmpty && ticket.ticketListings.first.status == 'available')
                                          Text(
                                            '${translate(context)!.offered_for_resale} ${ticket.ticketListings.first.price.toStringAsFixed(2)} €',
                                            style: const TextStyle(color: Colors.green),
                                          ),
                                      ],
                                    ),
                                    trailing: actionButton,
                                  ),
                                ],
                              ),
                            )
                          );
                        },
                      ),
                    ),
                  ],
                );
              } else if (state is MyTicketsDataLoadingError) {
                return Center(child: Text(state.errorMessage));
              } else {
                return Center(child: Text(translate(context)!.no_tickets));
              }
            },
          ),
        ),
      ),
    );
  }
}