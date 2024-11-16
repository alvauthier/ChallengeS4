import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/core/models/concert.dart';
import '../../translation.dart';
import 'blocs/concerts_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConcertsScreen extends StatefulWidget {
  const ConcertsScreen({super.key});

  @override
  ConcertsScreenState createState() => ConcertsScreenState();
}

class ConcertsScreenState extends State<ConcertsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  File? _image;
  String? _base64Image;
  final picker = ImagePicker();
  DateTime? _selectedDate;

  Future<void> getImage() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
        _base64Image = base64Encode(_image!.readAsBytesSync());
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? dateTime = await showOmniDateTimePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(
        const Duration(days: 3652),
      ),
      is24HourMode: true,
    );
    if (dateTime != null) {
      setState(() {
        _selectedDate = dateTime;
      });
    }
  }

  void _showUpdateDialog(BuildContext context, Concert concert) {
    final concertsBloc = context.read<ConcertsBloc>();

    _nameController.text = concert.name;
    _locationController.text = concert.location;
    _selectedDate = DateTime.parse(concert.date);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modifier les informations du concert'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await getImage();
                      setState(() {});
                    },
                    child: _image != null
                        ? Image.file(
                      _image!,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                        : (concert.image != ""
                        ? Image.network(
                      '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/uploads/concerts/${concert.image}',
                      height: 200,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.camera_alt),
                    )),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Lieu'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? translate(context)!.select_date_empty
                              : '${_selectedDate!.toLocal().toIso8601String().split('T')[0]} ${_selectedDate!.toLocal().toIso8601String().split('T')[1].split(':').sublist(0, 2).join(':')}',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _selectDate(context);
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          backgroundColor: Colors.deepOrange,
                        ),
                        child: Text(
                          translate(context)!.select_date,
                          style: const TextStyle(fontFamily: 'Readex Pro'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _nameController.text = concert.name;
                    _locationController.text = concert.location;
                    _selectedDate = DateTime.parse(concert.date);
                    _image = null;

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await ApiServices.updateConcert(
                        concert.id,
                        _nameController.text,
                        _locationController.text,
                      );
                      Navigator.of(dialogContext).pop();
                      concertsBloc.add(ConcertsDataLoaded());
                    } catch (e) {
                      print('An error occurred while updating concert: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update concert: $e')),
                      );
                    }
                  },
                  child: const Text('Mettre à jour'),
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
      create: (context) => ConcertsBloc()..add(ConcertsDataLoaded()),
      child: BlocBuilder<ConcertsBloc, ConcertsState>(
        builder: (context, state) {
          if (state is ConcertsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConcertsDataLoadingSuccess) {
            return ListView.builder(
              itemCount: state.concerts.length,
              itemBuilder: (context, index) {
                final concert = state.concerts[index];
                return ListTile(
                  title: Text(concert.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${concert.date}'),
                      Text('Location: ${concert.location}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showUpdateDialog(context, concert);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (state is ConcertsDataLoadingError) {
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