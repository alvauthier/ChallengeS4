import 'package:flutter/material.dart';
import 'package:weezemaster/conversations/blocs/conversations_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:weezemaster/login_register_screen.dart';
import 'package:weezemaster/chat.dart';
import 'package:weezemaster/core/services/token_services.dart';

import '../components/adaptive_navigation_bar.dart';

class ConversationsScreen extends StatefulWidget {
  static const String routeName = '/conversations';

  static navigateTo(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }
  
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => ConversationsScreenState();
}

class ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<String> getUserIdFromJwt() async {
    final tokenService = TokenService();
    String? jwt = await tokenService.getValidAccessToken();
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      return decodedToken['id'] as String;
    } else {
      LoginRegisterScreen.navigateTo(context);
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
        } else if (snapshot.hasData) {
          String userId = snapshot.data!;
          return BlocProvider(
            create: (context) => ConversationsBloc()..add(ConversationsDataLoaded(userId: userId)),
            child: SafeArea(
              child: Scaffold(
                backgroundColor: Colors.white,
                body: BlocBuilder<ConversationsBloc, ConversationsState>(
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
                      if (state.conversationsAsSeller.isNotEmpty || state.conversationsAsBuyer.isNotEmpty) {
                        List<Widget> combinedList = [];

                        if (state.conversationsAsBuyer.isNotEmpty) {
                          combinedList.add(const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'Vos conversations en tant qu\'acheteur',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Readex Pro'),
                            ),
                          ));

                          combinedList.addAll(state.conversationsAsBuyer.map((conversation) {
                            return ListTile(
                              title: Text(
                                  '${conversation.seller.firstname} ${conversation.seller.lastname}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Readex Pro',
                                      fontSize: 20
                                  )
                              ),
                              subtitle: Text(formatDate(conversation.updatedAt.toString())),
                              onTap: () {
                                ChatScreen.navigateTo(context, id: conversation.id);
                              },
                            );
                          }).toList());

                          combinedList.add(const Divider(height: 40));
                        }

                        if (state.conversationsAsSeller.isNotEmpty) {
                          combinedList.add(const Padding(
                            padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                            child: Text(
                              'Vos conversations en tant que vendeur',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Readex Pro'),
                            ),
                          ));

                          combinedList.addAll(state.conversationsAsSeller.map((conversation) {
                            return ListTile(
                              title: Text(
                                  '${conversation.buyer.firstname} ${conversation.buyer.lastname}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Readex Pro',
                                      fontSize: 20
                                  )
                              ),
                              subtitle: Text( formatDate(conversation.updatedAt.toString())),
                              onTap: () {
                                ChatScreen.navigateTo(context, id: conversation.id);
                              },
                            );
                          }).toList());
                        }

                        return ListView(
                          children: combinedList,
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
                            ),
                          ],
                        );
                      }
                    }

                    return const Center(
                      child: Text(
                        'État inattendu',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  },
                ),
                bottomNavigationBar: const AdaptiveNavigationBar(),
              ),
            ),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: Text(
                'Aucune donnée disponible',
                style: TextStyle(color: Colors.red),
              ),
            ),
            bottomNavigationBar: AdaptiveNavigationBar(),
          );
        }
      },
    );
  }
}