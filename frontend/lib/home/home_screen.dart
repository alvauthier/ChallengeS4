import 'package:flutter/material.dart';
import 'package:frontend/home/blocs/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:frontend/concert/concert_screen.dart';
import 'package:frontend/components/search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _filteredConcerts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _refreshData(BuildContext context) async {
    context.read<HomeBloc>().add(HomeDataLoaded());
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
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
                return RefreshIndicator(
                  onRefresh: () => _refreshData(context),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset('assets/no_internet.png', width: 100, height: 100),
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                'Une erreur est survenue. Veuillez vérifier votre connexion internet ou réessayer plus tard.',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                context.read<HomeBloc>().add(HomeDataLoaded());
                              },
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (state is HomeDataLoadingSuccess) {
                _filteredConcerts = state.concerts.where((concert) {
                  return concert.name.toLowerCase().contains(_searchController.text.toLowerCase());
                }).toList();

                return RefreshIndicator(
                  onRefresh: () => _refreshData(context),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'Weezemaster',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ReadexProBold',
                          ),
                        ),
                      ),
                      CustomSearchBar(
                        controller: _searchController,
                        onChanged: (text) {
                          setState(() {});
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${_filteredConcerts.length} concerts',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            final concert = _filteredConcerts[index];
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
                                            fontFamily: 'ReadexProBold',
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
                          itemCount: _filteredConcerts.length,
                        ),
                      ),
                    ],
                  ),
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
