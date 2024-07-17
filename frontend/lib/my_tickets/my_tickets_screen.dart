import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/my_tickets/blocs/my_tickets_bloc.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => MyTicketsScreenState();
}

class MyTicketsScreenState extends State<MyTicketsScreen> {
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

                          return Card(
                            child: ListTile(
                              title: Text(concert.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category.name),
                                  Text('${concert.location} - ${formatDate(concert.date)}'),
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
                                  ),
                                ),
                              ),
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