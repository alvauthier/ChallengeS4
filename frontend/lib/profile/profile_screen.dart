import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/profile/blocs/profile_bloc.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/utils/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/controller/navigation_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
  }

  Future<void> clearTokens() async {
    TokenService tokenService = TokenService();
    await tokenService.clearTokens();
  }

  void _logout() async {
    await clearTokens();
    if (mounted) {
      context.read<NavigationCubit>().updateUserRole('');
      context.pushNamed('login');
    }
  }

  Future<String> getUserIdFromJwt() async {
    final tokenService = TokenService();
    String? jwt = await tokenService.getValidAccessToken();
    if (jwt != null) {
      Map<String, dynamic> decodedToken = _decodeToken(jwt);
      return decodedToken['id'] as String;
    } else {
      GoRouter.of(context).go(Routes.loginRegisterNamedPage);
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
            create: (context) => ProfileBloc()..add(ProfileDataLoaded(userId: userId)),
            child: SafeArea(
              child: Scaffold(
                backgroundColor: Colors.white,
                body: Stack(
                  children: [
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        if (state is ProfileLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is ProfileDataLoadingError) {
                          return Center(
                            child: Text(
                              state.errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (state is ProfileDataLoadingSuccess) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    '${translate(context)!.hello} ${state.user.firstname} ${state.user.lastname}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Readex Pro',
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  ClipOval(
                                    child: state.user.image != ""
                                        ? Image.network(
                                      '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/uploads/users/${state.user.image}',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                        : const Image(
                                      image: AssetImage("assets/user-placeholder.jpg"),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  Expanded(
                                    child: ListView(
                                      children: [
                                        ListTile(
                                          title: Text(
                                            translate(context)!.edit_profile,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontFamily: 'Readex Pro',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                            color: Colors.black,
                                            size: 30,
                                          ),
                                          onTap: () => context.pushNamed('edit-profile'),
                                        ),
                                        const SizedBox(height: 10),
                                        if (state.user.role == 'user')
                                          Column(
                                            children: [
                                              ListTile(
                                                title: Text(
                                                  translate(context)!.my_interests,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Readex Pro',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                trailing: const Icon(
                                                  Icons.chevron_right,
                                                  color: Colors.black,
                                                  size: 30,
                                                ),
                                                onTap: () => context.pushNamed('user-interests'),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ),
                                        ListTile(
                                          title: Text(
                                            translate(context)!.logout,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontFamily: 'Readex Pro',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                            color: Colors.black,
                                            size: 30,
                                          ),
                                          onTap: _logout,
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                )
              ),
            ),
          );
        } else {
          return Scaffold(
            body: Center(
              child: Text(
                translate(context)!.no_data,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
      },
    );
  }
}