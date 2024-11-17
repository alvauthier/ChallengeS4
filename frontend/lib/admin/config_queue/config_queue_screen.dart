import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:weezemaster/core/services/token_services.dart';
import 'package:weezemaster/translation.dart';

class ConfigQueueScreen extends StatefulWidget {
  const ConfigQueueScreen({super.key});

  @override
  _ConfigQueueScreenState createState() => _ConfigQueueScreenState();
}

class _ConfigQueueScreenState extends State<ConfigQueueScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentValue();
  }

  Future<void> _fetchCurrentValue() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/config/CONCERTS_MAX_USERS_BEFORE_QUEUE';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentValue = data['value'];
          _controller.text = _currentValue;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load current value');
      }
    } catch (e) {
      debugPrint('Error fetching current value: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateValue() async {
    final newValue = _controller.text;
    if (newValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(context)!.value_not_empty)),
      );
      return;
    }

    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/config/CONCERTS_MAX_USERS_BEFORE_QUEUE';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
        body: {'value': newValue},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context)!.config_update_success)),
        );
        setState(() {
          _currentValue = newValue;
        });
      } else {
        throw Exception('Failed to update value');
      }
    } catch (e) {
      debugPrint('Error updating value: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(context)!.config_update_failed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate(context)!.config_queue),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: translate(context)!.nb_max_users_queue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateValue,
                    child: Text(translate(context)!.update),
                  ),
                ],
              ),
            ),
    );
  }
}