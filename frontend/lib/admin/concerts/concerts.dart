import 'package:flutter/material.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/models/concert.dart';
import 'blocs/concerts_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConcertsScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  ConcertsScreen({super.key});

  void _showUpdateDialog(BuildContext context, Concert concert) {
    final concertsBloc = context.read<ConcertsBloc>();

    _nameController.text = concert.name;
    _locationController.text = concert.location;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Modifier les informations du concert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Lieu'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ApiServices.updateConcert(
                    concert.id,
                    _nameController.text,
                    _locationController.text,
                  );
                  Navigator.of(dialogContext).pop();
                  concertsBloc.add(ConcertsDataLoaded());
                } catch (e) {
                  print('An error occurred while updating concert: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update concert: $e')),
                  );
                }
              },
              child: const Text('Mettre à jour'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConcertsBloc()..add(ConcertsDataLoaded()),
      child: BlocBuilder<ConcertsBloc, ConcertsState>(
        builder: (context, state) {
          if (state is ConcertsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConcertsDataLoadingSuccess) {
            return ListView.builder(
              itemCount: state.concerts.length,
              itemBuilder: (context, index) {
                final concert = state.concerts[index];
                return ListTile(
                  title: Text(concert.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${concert.date}'),
                      Text('Location: ${concert.location}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showUpdateDialog(context, concert);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (state is ConcertsDataLoadingError) {
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