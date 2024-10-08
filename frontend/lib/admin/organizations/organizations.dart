import 'package:flutter/material.dart';
import 'package:weezemaster/core/models/organization.dart';

class OrganizationsScreen extends StatelessWidget {
  final List<Organization> organizations = [
    Organization(id: '', name: 'Org 1'),
  ];

  OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: organizations.length,
        itemBuilder: (context, index) {
          final organization = organizations[index];
          return ListTile(
            title: Text(organization.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit organization logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Delete organization logic
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}