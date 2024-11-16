import 'package:flutter/material.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/models/artist.dart';
import 'blocs/artists_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArtistsScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();

  ArtistsScreen({super.key});

  void _showAddingDialog(BuildContext context) {
    final artistsBloc = context.read<ArtistsBloc>();

    _nameController.text = '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ajouter un artiste'),
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
                  await ApiServices.addArtist(
                    _nameController.text,
                  );
                  Navigator.of(dialogContext).pop();
                  artistsBloc.add(ArtistsDataLoaded());
                } catch (e) {
                  print('An error occurred while adding artist: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add artist: $e')),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(BuildContext context, Artist artist) {
    final artistsBloc = context.read<ArtistsBloc>();

    _nameController.text = artist.name;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Modifier les informations de l\'artiste'),
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
                  await ApiServices.updateArtist(
                    artist.id,
                    _nameController.text,
                  );
                  Navigator.of(dialogContext).pop();
                  artistsBloc.add(ArtistsDataLoaded());
                } catch (e) {
                  print('An error occurred while updating artist: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update artist: $e')),
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

  void _showDeleteDialog(BuildContext context, Artist artist) {
    final artistsBloc = context.read<ArtistsBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer l\'artiste'),
          content: Text('Êtes-vous sûr de vouloir supprimer ${artist.name} ?'),
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
                  await ApiServices.deleteArtist(artist.id);
                  Navigator.of(dialogContext).pop();
                  artistsBloc.add(ArtistsDataLoaded());
                } catch (e) {
                  print('An error occurred while deleting artist: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete artist: $e')),
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
        create: (context) => ArtistsBloc()..add(ArtistsDataLoaded()),
        child: BlocBuilder<ArtistsBloc, ArtistsState>(
          builder: (context, state) {
            if (state is ArtistsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ArtistsDataLoadingSuccess) {
              return Scaffold(
                body: ListView.builder(
                  itemCount: state.artists.length,
                  itemBuilder: (context, index) {
                    final artist = state.artists[index];
                    return ListTile(
                        title: Text(artist.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showUpdateDialog(context, artist);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                _showDeleteDialog(context, artist);
                              },
                            ),
                          ],
                        )
                    );
                  },
                ),
                floatingActionButton: FloatingActionButton(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _showAddingDialog(context);
                  },
                  child: const Icon(Icons.add),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat
              );
            } else if (state is ArtistsDataLoadingError) {
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