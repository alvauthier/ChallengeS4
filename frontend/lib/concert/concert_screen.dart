import 'package:flutter/material.dart';
import 'package:frontend/concert/blocs/concert_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ConcertScreen extends StatelessWidget {
  final String concertId;

  const ConcertScreen({super.key, required this.concertId});

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);

    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    String formattedDate = dateFormat.format(dateTime);

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConcertBloc()..add(ConcertDataLoaded(concertId: concertId)),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              BlocBuilder<ConcertBloc, ConcertState>(
                builder: (context, state) {
                  if (state is ConcertLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is ConcertDataLoadingError) {
                    return Center(
                      child: Text(
                        state.errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (state is ConcertDataLoadingSuccess) {
                    return Column(
                        children: <Widget> [
                          Image.network(
                            'https://picsum.photos/seed/picsum/800/400',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 30.0, right: 10.0, left: 10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatDate(state.concert.date),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'ReadexProRegular'
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0, right: 10.0, left: 10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                state.concert.name,
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontFamily: 'ReadexProBold'
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(
                                state.concert.location,
                                style: const TextStyle(
                                    fontFamily: 'ReadexProRegular'
                                )
                            ),
                          ),
                          const ListTile(
                            leading: Icon(Icons.event_seat),
                            title: Text(
                                '300 restant',
                                style: TextStyle(
                                    fontFamily: 'ReadexProRegular'
                                )
                            ),
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.only(top: 20.0, right: 10.0, left: 10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'A propos de cet événement',
                                style: TextStyle(
                                    fontSize: 25,
                                    fontFamily: 'ReadexProSemiBold'
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10.0, right: 10.0, left: 10.0),
                              child: Chip(
                                label: const Text(
                                    'Pop',
                                    style: TextStyle(
                                        fontFamily: 'ReadexProRegular'
                                    )
                                ),
                                backgroundColor: Colors.deepOrange.shade100,
                                shape: const StadiumBorder(),
                                side: BorderSide.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0, right: 10.0, left: 10.0, bottom: 20.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                state.concert.description,
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontFamily: 'ReadexProRegular'
                                ),
                              ),
                            ),
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.only(top: 20.0, right: 10.0, left: 10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Ticket disponible à la revente',
                                style: TextStyle(
                                    fontSize: 25,
                                    fontFamily: 'ReadexProSemiBold'
                                ),
                              ),
                            ),
                          ),
                        ]
                    );
                  }

                  return const SizedBox();
                },
              ),
              Positioned(
                top: 10.0,
                left: 10.0,
                child: FloatingActionButton(
                  child: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    '100€',
                    style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'ReadexProBold'
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: const Text('Réserver un ticket'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}