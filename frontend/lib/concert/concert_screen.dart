import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/concert/blocs/concert_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/components/resale_ticket.dart';
import 'package:weezemaster/components/interest_chip.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/utils/constants.dart';

import '../controller/navigation_cubit.dart';

class ConcertScreen extends StatelessWidget {
  final String id;

  const ConcertScreen({super.key, required this.id});

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  static Future<String> getUserRoleFromJwt() async {
    const storage = FlutterSecureStorage();
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      final parts = jwt.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload);
      if (payloadMap is! Map<String, dynamic>) {
        throw Exception('Invalid payload');
      }

      return payloadMap['role'];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConcertBloc()..add(ConcertDataLoaded(concertId: id)),
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
                    final concert = state.concert;

                    // Calcul des tickets restants
                    int totalRemainingTickets = concert.concertCategories
                        .map((category) => category.availableTickets - category.soldTickets)
                        .reduce((value, element) => value + element);

                    // Filtrer les tickets pour la revente
                    List resaleTickets = [];
                    for (var concertCategory in concert.concertCategories) {
                      if (concertCategory.tickets.isNotEmpty) {
                        for (var ticket in concertCategory.tickets) {
                          if (ticket.ticketListings.isNotEmpty) {
                            ticket.ticketListings.sort((a, b) =>
                                b.createdAt.compareTo(a.createdAt));
                            if (ticket.ticketListings.first.status ==
                                'available') {
                              resaleTickets.add(
                                  {
                                    'reseller': {
                                      'id': ticket.user.id,
                                      'name': '${ticket.user.firstname} ${ticket
                                          .user.lastname}',
                                      'avatar': ticket.user.image != ''
                                          ? '${dotenv
                                          .env['API_PROTOCOL']}://${dotenv
                                          .env['API_HOST']}${dotenv
                                          .env['API_PORT']}/uploads/users/${ticket
                                          .user.image}'
                                          : '',
                                    },
                                    'category': concertCategory.category.name,
                                    'price': ticket.ticketListings.first.price
                                        .toStringAsFixed(2),
                                    'id': ticket.ticketListings.first.id.toString(),
                                    'concertName': concert.name,
                                    'concertImage': concert.image != ''
                                        ? '${dotenv
                                        .env['API_PROTOCOL']}://${dotenv
                                        .env['API_HOST']}${dotenv
                                        .env['API_PORT']}/uploads/concerts/${concert
                                        .image}'
                                        : 'https://picsum.photos/seed/picsum/800/400',
                                  }
                              );
                            }
                          }
                        }
                      }
                    }

                    List selectedResaleTickets = resaleTickets.length > 2
                        ? (resaleTickets..shuffle()).take(2).toList()
                        : resaleTickets;

                    // Filtrer les catégories avec des tickets restants
                    var remainingCategories = state.concert.concertCategories
                        .where((category) => category.availableTickets > category.soldTickets)
                        .toList();

                    String priceText;

                    if (remainingCategories.isEmpty) {
                      priceText = translate(context)!.sold_out;
                    } else {
                      // Récupérer les prix des catégories restantes
                      var prices = remainingCategories.map((concertCategory) => concertCategory.price).toList();
                      var minPrice = prices.reduce((value, element) => value < element ? value : element);
                      var maxPrice = prices.reduce((value, element) => value > element ? value : element);

                      if (prices.length > 1) {
                        priceText = '${minPrice.toStringAsFixed(2)} € - ${maxPrice.toStringAsFixed(2)} €';
                      } else {
                        priceText = '${minPrice.toStringAsFixed(2)} €';
                      }
                    }

                    return Stack(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              Image.network(
                                concert.image != ''
                                    ? '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/uploads/concerts/${concert.image}'
                                    : 'https://picsum.photos/seed/picsum/800/400',
                                width: double.infinity,
                                height: 250,
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
                                      fontFamily: 'Readex Pro',
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15.0, right: 10.0, left: 10.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final tokenService = TokenService();
                                      String? token = await tokenService.getValidAccessToken();
                                      if (token == null) {
                                        GoRouter.of(context).go(Routes.loginRegisterNamedPage);
                                      } else {
                                        context.pushNamed(
                                          'artist',
                                          pathParameters: {'id': concert.artist.id},
                                          extra: concert.artist,
                                        );
                                      }
                                    },
                                    child: Text(
                                      '${state.concert.artist.name} : ${state.concert.name}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontFamily: 'Readex Pro',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(
                                  state.concert.location,
                                  style: const TextStyle(
                                    fontFamily: 'Readex Pro',
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.event_seat),
                                title: Text(
                                  '$totalRemainingTickets ${translate(context)!.remaining_tickets}',
                                  style: const TextStyle(
                                    fontFamily: 'Readex Pro',
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.event),
                                title: Text(
                                  '${translate(context)!.organized_by} ${state.concert.organization.name}',
                                  style: const TextStyle(
                                    fontFamily: 'Readex Pro',
                                  ),
                                ),
                              ),
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0, right: 10.0, left: 10.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    translate(context)!.about_event,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontFamily: 'Readex Pro',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0, right: 10.0, left: 10.0),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Wrap(
                                    spacing: 10.0,
                                    runSpacing: 5.0,
                                    alignment: WrapAlignment.start,
                                    children: state.concert.interests
                                        .map((interest) => InterestChip(interest: interest))
                                        .toList(),
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
                                      fontFamily: 'Readex Pro',
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0, right: 10.0, left: 10.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    translate(context)!.tickets_available_resale,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontFamily: 'Readex Pro',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              if (resaleTickets.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      translate(context)!.no_tickets_resale,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        fontFamily: 'Readex Pro',
                                      ),
                                    ),
                                  ),
                                ),
                              if (resaleTickets.isNotEmpty)
                                for (var resaleTicket in selectedResaleTickets)
                                  ResaleTicket(ticket: Ticket.fromMap(resaleTicket)),
                              if (resaleTickets.length > 2)
                                ElevatedButton(
                                  onPressed: () {
                                    context.pushNamed(
                                        'resale-tickets',
                                        extra: resaleTickets
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                  ),
                                  child: Text(
                                    translate(context)!.view_all_resales,
                                    style: const TextStyle(
                                      fontFamily: 'Readex Pro',
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              color: Colors.white,
                            ),
                            child: FutureBuilder<String>(
                              future: getUserRoleFromJwt(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final userRole = snapshot.data ?? '';

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      priceText,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Readex Pro',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(
                                        width: 150,
                                        child: ElevatedButton(
                                          onPressed: remainingCategories.isEmpty || (userRole != 'user' && userRole != '') ? null : () async {
                                            final tokenService = TokenService();
                                            String? token = await tokenService.getValidAccessToken();
                                            if (token == null) {
                                              context.read<NavigationCubit>().updateUserRole('');
                                              GoRouter.of(context).go(Routes.loginRegisterNamedPage);
                                            } else {
                                              context.pushNamed(
                                                  'booking',
                                                  extra: state.concert.concertCategories
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6.0),
                                            ),
                                            backgroundColor: Colors.deepOrange,
                                          ),
                                          child: Text(
                                            translate(context)!.book,
                                            style: const TextStyle(
                                              fontFamily: 'Readex Pro',
                                            ),
                                          ),
                                        )
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Center(
                    child: Text(
                      translate(context)!.generic_error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
              Positioned(
                top: 10.0,
                left: 10.0,
                child: FloatingActionButton(
                  child: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}