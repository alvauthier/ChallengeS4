import 'package:flutter/material.dart';
import 'package:weezemaster/resale_tickets_screen.dart';
import 'package:weezemaster/booking_screen.dart';
import 'package:weezemaster/concert/blocs/concert_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/login_register_screen.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/components/resale_ticket.dart';
import 'package:weezemaster/components/interest_chip.dart';
import 'package:weezemaster/translation.dart';

import 'package:weezemaster/components/adaptive_navigation_bar.dart';

class ConcertScreen extends StatelessWidget {
  static const String routeName = '/concert';

  static Future<dynamic> navigateTo(BuildContext context, {required String id}) async {
    return Navigator.of(context).pushNamed(routeName, arguments: id);
  }

  final String id;

  const ConcertScreen({super.key, required this.id});

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
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
                          if (ticket.ticketListing != null && ticket.ticketListing!.status == 'available') {
                            resaleTickets.add(
                                {
                                  'reseller': {
                                    'id': ticket.user.id,
                                    'name': '${ticket.user.firstname} ${ticket.user.lastname}',
                                    'avatar': 'https://thispersondoesnotexist.com/',
                                  },
                                  'category': concertCategory.category.name,
                                  'price': ticket.ticketListing!.price.toStringAsFixed(2),
                                  'id': ticket.ticketListing!.id.toString()
                                }
                            );
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
                                      fontFamily: 'Readex Pro',
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
                                      fontFamily: 'Readex Pro',
                                      fontWeight: FontWeight.w700,
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
                                      fontSize: 25,
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
                                      fontSize: 25,
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
                                    ResaleTicketsScreen.navigateTo(context, resaleTickets: resaleTickets);
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
                            child: Row(
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
                                    onPressed: remainingCategories.isEmpty ? null : () async {
                                      final tokenService = TokenService();
                                      String? token = await tokenService.getValidAccessToken();
                                      if (token == null) {
                                        LoginRegisterScreen.navigateTo(context);
                                      } else {
                                        BookingScreen.navigateTo(context, concertCategories: state.concert.concertCategories);
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
                  onPressed: () => Navigator.pushNamed(context, '/'),
                ),
              ),
            ],
          ),
          bottomNavigationBar: const AdaptiveNavigationBar(),
        ),
      ),
    );
  }
}