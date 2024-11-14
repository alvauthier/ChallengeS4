import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/profile/blocs/profile_bloc.dart';
import 'package:weezemaster/translation.dart';
import 'package:weezemaster/core/utils/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final storage = const FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();

  File? _image;
  String? _base64Image;
  final picker = ImagePicker();

  Future<void> getImage() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
        _base64Image = base64Encode(_image!.readAsBytesSync());
      }
    });
  }

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
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                            child: Column(
                              children: [
                                Text(
                                  translate(context)!.edit_profile,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Readex Pro',
                                  ),
                                ),
                                const SizedBox(height: 40),
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ],
                            ),
                          );
                        }

                        if (state is ProfileDataLoadingError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                            child: Column(
                              children: [
                                Text(
                                  translate(context)!.edit_profile,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Readex Pro',
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  state.errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }

                        if (state is ProfileDataLoadingSuccess) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Text(
                                    translate(context)!.edit_profile,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Readex Pro',
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  GestureDetector(
                                    onTap: getImage,
                                    child: Stack(
                                      children: [
                                        ClipOval(
                                          child: _image != null
                                              ? Image.file(
                                            _image!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          )
                                              : (state.user.image != ""
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
                                          )),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: const BoxDecoration(
                                              color: Colors.deepOrange,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  offset: Offset(0, 2),
                                                  blurRadius: 6.0,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _firstnameController..text = state.user.firstname,
                                    decoration: InputDecoration(
                                      labelText: translate(context)!.firstname,
                                      errorMaxLines: 3,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return translate(context)!.firstname_empty;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _lastnameController..text = state.user.lastname,
                                    decoration: InputDecoration(
                                      labelText: translate(context)!.lastname,
                                      errorMaxLines: 3,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return translate(context)!.lastname_empty;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _emailController..text = state.user.email,
                                    decoration: InputDecoration(
                                      labelText: translate(context)!.email,
                                      errorMaxLines: 3,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return translate(context)!.email_empty;
                                      }
                                      return null;
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (_formKey.currentState!.validate()) {
                                            try {
                                              final tokenService = TokenService();
                                              String? jwtToken = await tokenService.getValidAccessToken();

                                              var request = http.MultipartRequest(
                                                'PATCH',
                                                Uri.parse('${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/users/$userId'),
                                              );

                                              request.headers['Authorization'] = 'Bearer $jwtToken';

                                              request.fields['email'] = _emailController.text;
                                              request.fields['firstname'] = _firstnameController.text;
                                              request.fields['lastname'] = _lastnameController.text;

                                              if (_image != null) {
                                                request.files.add(
                                                  await http.MultipartFile.fromPath(
                                                    'image',
                                                    _image!.path,
                                                    contentType: MediaType('image', _image!.path.split('.').last),
                                                  ),
                                                );
                                              }

                                              var response = await request.send();

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(response.statusCode == 200
                                                      ? translate(context)!.update_profile_success
                                                      : translate(context)!.update_profile_failed),
                                                  duration: const Duration(seconds: 5),
                                                ),
                                              );

                                              context.pushReplacement(Routes.profileNamedPage);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(e.toString()),
                                                  duration: const Duration(seconds: 5),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6.0),
                                          ),
                                          backgroundColor: Colors.deepOrange,
                                        ),
                                        child: Text(
                                          translate(context)!.update,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Readex Pro',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                    Positioned(
                      top: 25.0,
                      left: 20.0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 30,
                        ),
                        onPressed: () => context.pushReplacement(Routes.profileNamedPage),
                      ),
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