import 'package:flutter/material.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'blocs/interests_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InterestsScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();

  InterestsScreen({super.key});

  void _showUpdateDialog(BuildContext context, Interest interest) {
    final interestsBloc = context.read<InterestsBloc>();

    _nameController.text = interest.name;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Modifier les informations de l\'intérêt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 8),
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
                  await ApiServices.updateInterest(
                    interest.id,
                    _nameController.text,
                  );
                  Navigator.of(dialogContext).pop();
                  interestsBloc.add(InterestsDataLoaded());
                } catch (e) {
                  print('An error occurred while updating interest: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update interest: $e')),
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

  void _showDeleteDialog(BuildContext context, Interest interest) {
    final interestsBloc = context.read<InterestsBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer l\'intérêt'),
          content: Text('Êtes-vous sûr de vouloir supprimer ${interest.name} ?'),
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
                  await ApiServices.deleteInterest(interest.id);
                  Navigator.of(dialogContext).pop();
                  interestsBloc.add(InterestsDataLoaded());
                } catch (e) {
                  print('An error occurred while deleting interest: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete interest: $e')),
                  );
                }
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => InterestsBloc()..add(InterestsDataLoaded()),
        child: BlocBuilder<InterestsBloc, InterestsState>(
          builder: (context, state) {
            if (state is InterestsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is InterestsDataLoadingSuccess) {
              return ListView.builder(
                itemCount: state.interests.length,
                itemBuilder: (context, index) {
                  final interest = state.interests[index];
                  return ListTile(
                    title: Text(interest.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showUpdateDialog(context, interest);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            _showDeleteDialog(context, interest);
                          },
                        ),
                      ],
                    )
                  );
                },
              );
            } else if (state is InterestsDataLoadingError) {
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