import 'package:flutter/material.dart';
import 'package:frontend/home/blocs/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:frontend/concert/concert_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);

    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    String formattedDate = dateFormat.format(dateTime);

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(HomeDataLoaded()),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is HomeDataLoadingError) {
                return Center(
                  child: Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (state is HomeDataLoadingSuccess) {
                return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${state.concerts.length} concerts',
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            final concert = state.concerts[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ConcertScreen(concertId: concert.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
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
                                        'https://picsum.photos/seed/picsum/800/400', // URL de l'image unique
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                                      child: Text(
                                        concert.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 26,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 20.0),
                                      child: Text(
                                        formatDate(concert.date),
                                          style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                                      child: Text(
                                        concert.location,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                              ),
                            );
                          },
                          itemCount: state.concerts.length,
                        ),
                      ),
                    ],
                  );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}