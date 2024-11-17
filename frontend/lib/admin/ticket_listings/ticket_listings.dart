import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weezemaster/core/models/ticket_listing.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/translation.dart';
import 'blocs/ticket_listings_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TicketListingsScreen extends StatefulWidget {
  const TicketListingsScreen({super.key});

  @override
  _TicketListingsScreenState createState() => _TicketListingsScreenState();
}

class _TicketListingsScreenState extends State<TicketListingsScreen> {
  final TextEditingController _price = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showUpdateDialog(BuildContext context, TicketListing ticketListing) async {
    final ticketListingsBloc = context.read<TicketListingsBloc>();

    setState(() {
      _price.text = ticketListing.price.toString();
      _status = ticketListing.status;
    });

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(translate(context)!.update_ticket_listing),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${translate(context)!.price} (max ${ticketListing.ticket.concertCategory.price}€)'),
                  TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final newPrice = double.tryParse(newValue.text);
                        if (newPrice != null && newPrice > ticketListing.ticket.concertCategory.price) {
                          return oldValue;
                        }
                        return newValue;
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(translate(context)!.status),
                  DropdownButton<String>(
                    value: _status,
                    onChanged: (String? value) {
                      setState(() {
                        _status = value;
                      });
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'available',
                        child: Text(translate(context)!.available),
                      ),
                      DropdownMenuItem(
                        value: 'sold',
                        child: Text(translate(context)!.sold),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(translate(context)!.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    await ApiServices.updateTicketListing(
                      ticketListing.id,
                      double.parse(_price.text),
                      _status!,
                    );

                    Navigator.of(dialogContext).pop();
                    ticketListingsBloc.add(TicketListingsDataLoaded());
                  },
                  child: Text(translate(context)!.update),
                ),
              ],
            );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TicketListingsBloc()..add(TicketListingsDataLoaded()),
      child: BlocBuilder<TicketListingsBloc, TicketListingsState>(
        builder: (context, state) {
          if (state is TicketListingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TicketListingsDataLoadingSuccess) {
            return ListView.builder(
              itemCount: state.ticketListings.length,
              itemBuilder: (context, index) {
                final ticketListing = state.ticketListings[index];
                return ListTile(
                  title: Text(ticketListing.id),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price: ${ticketListing.price}€'),
                      Text('Status: ${ticketListing.status}'),
                      Text('Ticket ID: ${ticketListing.ticketId}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showUpdateDialog(context, ticketListing);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (state is TicketListingsDataLoadingError) {
            return Center(
              child: Text(state.errorMessage),
            );
          } else {
            return const Center(child: Text('Unhandled state'));
          }
        },
      ),
    );
  }
}