import 'package:flutter/material.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/models/category.dart';
import 'package:weezemaster/translation.dart';
import 'blocs/categories_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();

  CategoriesScreen({super.key});

  void _showAddingDialog(BuildContext context) {
    final categoriesBloc = context.read<CategoriesBloc>();

    _nameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(translate(context)!.add_category),
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
                  await ApiServices.addCategory(_nameController.text);
                  Navigator.of(dialogContext).pop();
                  categoriesBloc.add(CategoriesDataLoaded());
                } catch (e) {
                  debugPrint('An error occurred while adding category: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${translate(context)!.add_category_failed} $e')),
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

  void _showUpdateDialog(BuildContext context, Category category) {
    final categoriesBloc = context.read<CategoriesBloc>();

    _nameController.text = category.name;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(translate(context)!.update_category),
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
                  await ApiServices.updateCategory(
                    category.id,
                    _nameController.text,
                  );
                  Navigator.of(dialogContext).pop();
                  categoriesBloc.add(CategoriesDataLoaded());
                } catch (e) {
                  debugPrint('An error occurred while updating category: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${translate(context)!.update_category_failed} $e')),
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => CategoriesBloc()..add(CategoriesDataLoaded()),
        child: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            if (state is CategoriesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoriesDataLoadingSuccess) {
              return Scaffold(
                body: ListView.builder(
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return ListTile(
                      title: Text(category.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showUpdateDialog(context, category);
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
            } else if (state is CategoriesDataLoadingError) {
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