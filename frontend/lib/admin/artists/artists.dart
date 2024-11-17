import 'package:flutter/material.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/models/artist.dart';
import 'package:weezemaster/translation.dart';
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
          title: Text(translate(context)!.add_artist),
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
              child: Text(translate(context)!.cancel),
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
                  debugPrint('An error occurred while adding artist: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${translate(context)!.add_artist_failed} $e')),
                  );
                }
              },
              child: Text(translate(context)!.add),
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
          title: Text(translate(context)!.update_artist),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: translate(context)!.lastname),
              ),
              const SizedBox(height: 8),
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
                try {
                  await ApiServices.updateArtist(
                    artist.id,
                    _nameController.text,
                  );
                  Navigator.of(dialogContext).pop();
                  artistsBloc.add(ArtistsDataLoaded());
                } catch (e) {
                  debugPrint('An error occurred while updating artist: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${translate(context)!.update_artist_failed} $e')),
                  );
                }
              },
              child: Text(translate(context)!.update),
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
          title: Text(translate(context)!.delete_artist),
          content: Text('${translate(context)!.confirm_delete} ${artist.name} ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(translate(context)!.cancel),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ApiServices.deleteArtist(artist.id);
                  Navigator.of(dialogContext).pop();
                  artistsBloc.add(ArtistsDataLoaded());
                } catch (e) {
                  debugPrint('An error occurred while deleting artist: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${translate(context)!.delete_artist_failed} $e')),
                  );
                }
              },
              child: Text(translate(context)!.delete),
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