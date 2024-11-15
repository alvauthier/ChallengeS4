import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/core/services/websocket_service.dart';
import 'package:weezemaster/home/blocs/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:weezemaster/components/search_bar.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/services/api_services.dart';

// Définir un enum pour les options de tri
enum SortOption { none, interests, recent, ancient }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _filteredConcerts = [];
  List<Interest> userInterests = [];
  bool isUserConnected = false;

  // Ajouter une variable d'état pour suivre l'option de tri actuelle
  SortOption _currentSortOption = SortOption.none;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    checkUserConnection();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<String> getUserRoleFromJwt(accessToken) async {
    Map<String, dynamic> decodedToken = _decodeToken(accessToken);

    return decodedToken['role'];
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

  Future<void> checkUserConnection() async {
    final tokenService = TokenService();
    String? token = await tokenService.getValidAccessToken();
    final userRole = await getUserRoleFromJwt(token);

    if (token != null && userRole == 'user') {
      setState(() {
        isUserConnected = true;
      });
      await fetchUserInterests();
    }
  }

  Future<void> fetchUserInterests() async {
    try {
      final interests = await ApiServices.getUserInterests();
      setState(() {
        userInterests = interests;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des centres d\'intérêts: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _refreshData(BuildContext context) async {
    context.read<HomeBloc>().add(HomeDataLoaded());
  }

  String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return dateFormat.format(dateTime);
  }

  final webSocketService = WebSocketService();
  
  Future<void> joinQueueOrConcertPage(String concertId, String userId) async {
    webSocketService.connect(concertId, userId);

    // Accès au flux de diffusion
    final broadcastStream = webSocketService.stream;
    
    if (broadcastStream == null) {
      debugPrint('Failed to get WebSocket broadcast stream.');
      return;
    }

    broadcastStream.listen(
      (event) {
        final data = jsonDecode(event);

        if (data['isFirstMessage'] == true && data['status'] == 'access_granted') {
          context.pushNamed(
            'concert',
            pathParameters: {'id': concertId},
            extra: {
              'webSocketService': webSocketService,
            },
          );
        } else if (data['isFirstMessage'] == true && data['status'] == 'in_queue') {
          context.pushNamed(
            'queue',
            extra: {
              'position': data['position'],
              'webSocketService': webSocketService,
            },
          );
        }
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
      },
      onDone: () {
        debugPrint('WebSocket connection closed.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(HomeDataLoaded()),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is HomeDataLoadingError) {
                return RefreshIndicator(
                  onRefresh: () => _refreshData(context),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset('assets/no_internet.png', width: 100, height: 100),
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                translate(context)!.generic_error,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                context.read<HomeBloc>().add(HomeDataLoaded());
                              },
                              child: Text(translate(context)!.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (state is HomeDataLoadingSuccess) {
                // Filtrer les concerts en fonction de la recherche
                _filteredConcerts = state.concerts.where((concert) {
                  return concert.name.toLowerCase().contains(_searchController.text.toLowerCase());
                }).toList();

                // Appliquer le tri en fonction de l'option sélectionnée
                if (_currentSortOption == SortOption.interests) {
                  _filteredConcerts.sort((a, b) {
                    // Récupère les noms des intérêts des concerts
                    List<dynamic> aInterests = a.interests.map((interest) => interest.name).toList();
                    List<dynamic> bInterests = b.interests.map((interest) => interest.name).toList();

                    // Vérifie si le concert a un intérêt correspondant à l'utilisateur
                    bool aHasInterest = aInterests.any((interest) => userInterests.any((userInterest) => userInterest.name == interest));
                    bool bHasInterest = bInterests.any((interest) => userInterests.any((userInterest) => userInterest.name == interest));

                    // Trie les concerts avec des intérêts en premier
                    if (aHasInterest && !bHasInterest) return -1;
                    if (!aHasInterest && bHasInterest) return 1;
                    return 0;
                  });
                } else if (_currentSortOption == SortOption.recent) {
                  _filteredConcerts.sort((a, b) {
                    return DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt));
                  });
                } else if (_currentSortOption == SortOption.ancient) {
                  _filteredConcerts.sort((a, b) {
                    return DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt));
                  });
                }
                

                return RefreshIndicator(
                  onRefresh: () => _refreshData(context),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'Weezemaster',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ReadexProBold',
                          ),
                        ),
                      ),
                      CustomSearchBar(
                        controller: _searchController,
                        onChanged: (text) {
                          setState(() {});
                        },
                      ),
                      if (isUserConnected)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${translate(context)!.my_interests} : ${userInterests.length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Readex Pro',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (String value) {
                                    setState(() {
                                      if (value == translate(context)!.interests) {
                                        _currentSortOption = SortOption.interests;
                                      } else if (value == translate(context)!.recent) {
                                        _currentSortOption = SortOption.recent;
                                      } else if (value == translate(context)!.ancient) {
                                        _currentSortOption = SortOption.ancient;
                                      } else {
                                        _currentSortOption = SortOption.none;
                                      }
                                    });
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return {translate(context)!.interests, translate(context)!.recent, translate(context)!.ancient}.map((String choice) {
                                      return PopupMenuItem<String>(
                                        value: choice,
                                        child: Text(choice),
                                      );
                                    }).toList();
                                  },
                                  child: const Icon(Icons.sort),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${_filteredConcerts.length} ${_filteredConcerts.length == 1 ? 'concert' : 'concerts'}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontFamily: 'Readex Pro',
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            final concert = _filteredConcerts[index];
                            return GestureDetector(
                              onTap: () async {
                                final tokenService = TokenService();
                                String? token = await tokenService.getValidAccessToken();
                                if (token == null) {
                                  context.pushNamed(
                                    'concert',
                                    pathParameters: {'id': concert.id},
                                  );
                                } else {
                                  final parts = token.split('.');
                                  if (parts.length != 3) {
                                    throw Exception('Invalid token');
                                  }

                                  String output = parts[1].replaceAll('-', '+').replaceAll('_', '/');
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

                                  String userId = json.decode(utf8.decode(base64.decode(output)))['id'];

                                  debugPrint('Joining queue or concert page for concert: ${concert.id} and user: $userId');
                                  await joinQueueOrConcertPage(concert.id, userId);

                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                        ),
                                        child: Image.network(
                                          (concert.image != null && concert.image.isNotEmpty)
                                              ? '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/uploads/concerts/${concert.image}'
                                              : 'https://picsum.photos/seed/picsum/800/400',
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                                        child: Text(
                                          concert.name,
                                          style: const TextStyle(
                                            fontFamily: 'Readex Pro',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 26,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 20.0),
                                        child: Text(
                                          formatDate(concert.date),
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontFamily: 'Readex Pro',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                                        child: Text(
                                          concert.location,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'Readex Pro',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          itemCount: _filteredConcerts.length,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}
