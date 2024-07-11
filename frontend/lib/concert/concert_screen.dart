import 'package:flutter/material.dart';
import 'package:frontend/booking_screen.dart';
import 'package:frontend/concert/blocs/concert_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/services/token_services.dart';
import 'package:frontend/login_register_screen.dart';
import 'package:intl/intl.dart';
import 'package:frontend/components/resale_ticket.dart';
import 'package:frontend/components/organiser_widget.dart';
import 'package:frontend/components/interest_chip.dart';

class ConcertScreen extends StatelessWidget {
  final String concertId;

  const ConcertScreen({super.key, required this.concertId});

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
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
                    final concert = state.concert;

                    // Calcul des tickets restants
                    int totalRemainingTickets = concert.concertCategories
                        .map((category) => category.availableTickets - category.soldTickets)
                        .reduce((value, element) => value + element);

                    // Filtrer les tickets pour la revente
                    List resaleTickets = [];
                    for (var concerCategory in concert.concertCategories) {
                      if (concerCategory.tickets.isNotEmpty) {
                        for (var ticket in concerCategory.tickets) {
                          if (ticket.ticketListing != null && ticket.ticketListing!.status == 'available') {
                            resaleTickets.add(
                              {
                                'reseller': {
                                  'name': '${ticket.user.firstname} ${ticket.user.lastname}',
                                  'avatar': 'https://thispersondoesnotexist.com/',
                                },
                                'category': concerCategory.category.name,
                                'price': ticket.ticketListing!.price.toStringAsFixed(2),
                                'id': ticket.ticketListing!.id.toString(),
                              }
                            );
                          }
                        }
                      }
                    }

                    List selectedResaleTickets = resaleTickets.length > 2
                        ? (resaleTickets..shuffle()).take(2).toList()
                        : resaleTickets;

                    return SingleChildScrollView(
                      child: Column(
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
                              '$totalRemainingTickets places restantes',
                              style: const TextStyle(
                                fontFamily: 'Readex Pro',
                              ),
                            ),
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.only(top: 20.0, right: 10.0, left: 10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'À propos de cet événement',
                                style: TextStyle(
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
                          const Padding(
                            padding: EdgeInsets.only(top: 20.0, right: 10.0, left: 10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Tickets disponibles à la revente',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontFamily: 'Readex Pro',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (resaleTickets.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Il n'y a actuellement pas de tickets disponibles à la revente.",
                                  style: TextStyle(
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
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                              ),
                              child: const Text(
                                'Consulter toutes les reventes',
                                style: TextStyle(
                                  fontFamily: 'Readex Pro',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.only(top: 20.0, right: 10.0, left: 10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Organisé par',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontFamily: 'Readex Pro',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          OrganiserWidget(
                            organiser: Organiser.fromMap({
                              'id': state.concert.organization.id,
                              'name': state.concert.organization.name,
                              'avatar': 'https://picsum.photos/seed/picsum/200/200',
                              'followers': '1000',
                            }),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text(
                        'État inattendu',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                },
              ),
              Positioned(
                top: 10.0,
                left: 10.0,
                child: FloatingActionButton(
                  child: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BlocBuilder<ConcertBloc, ConcertState>(
                builder: (context, state) {
                  if (state is ConcertDataLoadingSuccess) {
                    var prices = state.concert.concertCategories.map((concertCategory) => concertCategory.price).toList();
                    var minPrice = prices.reduce((value, element) => value < element ? value : element);
                    var maxPrice = prices.reduce((value, element) => value > element ? value : element);

                    String priceText;
                    if (prices.length > 1) {
                      priceText = '${minPrice.toStringAsFixed(2)} € - ${maxPrice.toStringAsFixed(2)} €';
                    } else {
                      priceText = '${minPrice.toStringAsFixed(2)} €';
                    }

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
                        ElevatedButton(
                          onPressed: () async {
                            final tokenService = TokenService();
                            String? token = await tokenService.getValidAccessToken();
                            if (token == null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginRegisterScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingScreen(concertCategories: state.concert.concertCategories),
                                ),
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
                          child: const Text(
                            'Réserver un ticket',
                            style: TextStyle(
                              fontFamily: 'Readex Pro',
                            ),
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
        ),
      ),
    );
  }
}