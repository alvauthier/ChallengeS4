import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weezemaster/conversations/blocs/conversations_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../login_register_screen.dart';
import 'package:weezemaster/register_concert_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => ConversationsScreenState();
}

class ConversationsScreenState extends State<ConversationsScreen> {
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
  }

  Future<String> getUserIdFromJwt() async {
    String? jwt = await storage.read(key: 'access_token');
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      if(decodedToken['role'] == 'organizer'){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RegisterConcertScreen()),
      );
      }
      return decodedToken['id'] as String;
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
      );
      return '';
    }
  }

  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: getUserIdFromJwt(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          String userId = snapshot.data!;
          return BlocProvider(
            create: (context) => ConversationsBloc()..add(ConversationsDataLoaded(userId: userId)),
            child: SafeArea(
              child: Scaffold(
                backgroundColor: Colors.white,
                body:  BlocBuilder<ConversationsBloc, ConversationsState>(
                  builder: (context, state) {
                    if (state is ConversationsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is ConversationsDataLoadingError) {
                      return Center(
                        child: Text(
                          state.errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (state is ConversationsDataLoadingSuccess) {
                      if(state.conversations.isNotEmpty) {
                        return Column(
                          children: [
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'Vos conversations',
                                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Readex Pro'),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: state.conversations.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                          state.conversations[index].buyer,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Readex Pro')
                                      ),
                                      subtitle: Text(
                                          formatDate(state.conversations[index].messages.last.updatedAt as String),
                                          style: const TextStyle(fontSize: 15, fontFamily: 'Readex Pro')
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(context, '/conversation', arguments: state.conversations[index].id);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const Column(
                          children: [
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'Vos conversations',
                                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Readex Pro'),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                'Aucune conversation disponible',
                                style: TextStyle(
                                  fontFamily: 'Readex Pro',
                                  fontSize: 20,
                                ),
                              ),
                            )
                          ]
                        );
                      }
                    } else {
                      return const Center(
                        child: Text(
                          'État inattendu',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          );
        }
    });
  }
}