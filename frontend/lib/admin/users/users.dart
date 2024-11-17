import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:weezemaster/core/models/user.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/translation.dart';
import 'blocs/users_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  UsersScreenState createState() => UsersScreenState();
}

class UsersScreenState extends State<UsersScreen> {
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _image;
  String? _base64Image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  void _showUpdateDialog(BuildContext context, User user) {
    final usersBloc = context.read<UsersBloc>();

    _firstnameController.text = user.firstname;
    _lastnameController.text = user.lastname;
    _emailController.text = user.email;
    _image = null;

    Future<void> getImage() async {
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _image = File(pickedImage.path);
          _base64Image = base64Encode(_image!.readAsBytesSync());
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(translate(context)!.update_user),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await getImage();
                      setState(() {});
                    },
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
                              : (user.image != ""
                              ? Image.network(
                            '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/uploads/users/${user.image}',
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _firstnameController,
                    decoration: InputDecoration(labelText: translate(context)!.firstname),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lastnameController,
                    decoration: InputDecoration(labelText: translate(context)!.lastname),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: translate(context)!.email),
                  ),
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
                      final tokenService = TokenService();
                      String? jwtToken = await tokenService.getValidAccessToken();

                      var request = http.MultipartRequest(
                        'PATCH',
                        Uri.parse('${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/users/${user.id}'),
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

                      await request.send();

                      Navigator.of(dialogContext).pop();
                      usersBloc.add(UsersDataLoaded());
                    } catch (e) {
                      debugPrint('An error occurred while updating user: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${translate(context)!.update_user_failed} $e')),
                      );
                    }
                  },
                  child: Text(translate(context)!.update),
                ),
              ],
            );
          },
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
                        Text('${translate(context)!.email} : ${user.email}'),
                        Text('${translate(context)!.role} : ${user.role}'),
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