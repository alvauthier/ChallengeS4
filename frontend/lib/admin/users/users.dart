import 'package:flutter/material.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/models/user.dart';
import 'blocs/users_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersScreen extends StatelessWidget {
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  UsersScreen({super.key});

  void _showUpdateDialog(BuildContext context, User user) {
    final usersBloc = context.read<UsersBloc>();

    _firstnameController.text = user.firstname;
    _lastnameController.text = user.lastname;
    _emailController.text = user.email;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Modifier les informations de l\'utilisateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _firstnameController,
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lastnameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
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
                  await ApiServices.updateUser(
                    user.id,
                    _firstnameController.text,
                    _lastnameController.text,
                    _emailController.text,
                  );
                  Navigator.of(dialogContext).pop();
                  usersBloc.add(UsersDataLoaded());
                } catch (e) {
                  print('An error occurred while updating user: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update user: $e')),
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
        create: (context) => UsersBloc()..add(UsersDataLoaded()),
        child: BlocBuilder<UsersBloc, UsersState>(
          builder: (context, state) {
            if (state is UsersLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is UsersDataLoadingSuccess) {
              return ListView.builder(
                itemCount: state.users.length,
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  return ListTile(
                    title: Text('${user.firstname} ${user.lastname}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user.email}'),
                        Text('Role: ${user.role}'),
                      ],
                    ),
                    trailing: user.role != 'admin'
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showUpdateDialog(context, user);
                            },
                          ),
                        ],
                      )
                    : null,
                  );
                },
              );
            } else if (state is UsersDataLoadingError) {
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