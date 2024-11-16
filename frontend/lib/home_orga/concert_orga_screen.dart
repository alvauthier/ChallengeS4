import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/home_orga/blocs/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/components/search_bar.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/utils/constants.dart';

import '../controller/navigation_cubit.dart';

class OrganizerConcertScreen extends StatefulWidget {
  const OrganizerConcertScreen({super.key});

  @override
  OrganizerConcertScreenState createState() => OrganizerConcertScreenState();
}


class OrganizerConcertScreenState extends State<OrganizerConcertScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _filteredConcerts = [];
    final storage = const FlutterSecureStorage();


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

  Future<String> getUserIdFromJwt() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      return decodedToken['id'] as String;
    } else {
      context.read<NavigationCubit>().updateUserRole('');
      GoRouter.of(context).go(Routes.loginRegisterNamedPage);
      return '';
    }
  }

  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!');
    }

    return utf8.decode(base64Url.decode(output));
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
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                translate(context)!.generic_error,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                context.read<HomeBloc>().add(HomeDataLoaded());
                              },
                              child: Text(translate(context)!.retry),
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
                            ' ${_filteredConcerts.length == 1 ? translate(context)!.my_concert : translate(context)!.my_concerts} (${_filteredConcerts.length})',
                            style: const TextStyle(
                              fontSize: 30,
                              fontFamily: 'Readex Pro',
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            final concert = _filteredConcerts[index];
                            return GestureDetector(
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
                                            fontFamily: 'Readex Pro',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 26,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 20.0),
                                        child: Text(
                                          formatDate(concert.date),
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontFamily: 'Readex Pro',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                                        child: Text(
                                          concert.location,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'Readex Pro',
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