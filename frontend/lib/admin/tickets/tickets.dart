import 'package:flutter/material.dart';
import 'package:weezemaster/core/models/concert_category.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/models/ticket.dart';
import 'package:weezemaster/core/models/user.dart';
import 'package:weezemaster/translation.dart';
import 'blocs/tickets_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<User> _users = [];
  List<ConcertCategory> _concertCategories = [];
  String? _selectedUserId;
  String? _selectedConcertCategoryId;

  @override
  void initState() {
    super.initState();
    _getUsers();
  }

  Future<void> _getUsers() async {
    try {
      final users = await ApiServices.getUsers();
      setState(() {
        _users = users..sort((a, b) => '${a.firstname} ${a.lastname}'.compareTo('${b.firstname} ${b.lastname}'));
      });
    } catch (e) {
      debugPrint('Failed to fetch users: $e');
    }
  }

  Future<void> _getConcertCategories(String id) async {
    try {
      final concert = await ApiServices.getConcert(id);
      setState(() {
        _concertCategories = concert.concertCategories;
      });
    } catch (e) {
      debugPrint('Failed to fetch concert: $e');
    }
  }

  Future<void> _showUpdateDialog(BuildContext context, Ticket ticket) async {
    final ticketsBloc = context.read<TicketsBloc>();

    setState(() {
      _selectedUserId = ticket.user.id;
      _selectedConcertCategoryId = ticket.concertCategory.id;
    });

    await _getConcertCategories(ticket.concertCategory.concert.id);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(translate(context)!.update_ticket),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(translate(context)!.user),
                  DropdownButton<String>(
                    value: _selectedUserId,
                    items: _users.map((User user) {
                      return DropdownMenuItem<String>(
                        value: user.id,
                        child: Text('${user.firstname} ${user.lastname}'),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedUserId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(translate(context)!.category),
                  DropdownButton<String>(
                    value: _selectedConcertCategoryId,
                    items: _concertCategories.map((ConcertCategory concertCategory) {
                      return DropdownMenuItem<String>(
                        value: concertCategory.id,
                        child: Text(concertCategory.category.name),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedConcertCategoryId = value;
                      });
                    },
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
                    await ApiServices.updateTicket(
                      ticket.id,
                      _selectedUserId!,
                      _selectedConcertCategoryId!,
                    );

                    Navigator.of(dialogContext).pop();
                    ticketsBloc.add(TicketsDataLoaded());
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
      create: (context) => TicketsBloc()..add(TicketsDataLoaded()),
      child: BlocBuilder<TicketsBloc, TicketsState>(
        builder: (context, state) {
          if (state is TicketsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TicketsDataLoadingSuccess) {
            return ListView.builder(
              itemCount: state.tickets.length,
              itemBuilder: (context, index) {
                final ticket = state.tickets[index];
                return ListTile(
                  title: Text(ticket.id),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${translate(context)!.user} : ${ticket.user.firstname} ${ticket.user.lastname}'),
                      Text('${translate(context)!.concert_name} : ${ticket.concertCategory.concert.name}'),
                      Text('${translate(context)!.category} : ${ticket.concertCategory.category.name}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showUpdateDialog(context, ticket);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (state is TicketsDataLoadingError) {
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