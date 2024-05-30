import 'package:flutter/material.dart';

class Organiser {
  final String avatar;
  final String name;
  final String followers;

  Organiser({required this.avatar, required this.name, required this.followers});

  factory Organiser.fromMap(Map<String, String> map) {
    return Organiser(
      avatar: map['avatar']!,
      name: map['name']!,
      followers: map['followers']!,
    );
  }
}

class OrganiserWidget extends StatelessWidget {
  final Organiser organiser;

  const OrganiserWidget({super.key, required this.organiser});

  String formatFollowers(String followers) {
    final int count = int.parse(followers);
    if (count < 1000) {
      return followers;
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 100,
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  organiser.avatar,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              organiser.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${formatFollowers(organiser.followers)} abonnés',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)
                          ),
                        ),
                        child: const Text(
                          'Suivre',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}