import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TokenService {
  final _storage = const FlutterSecureStorage();
  final String _refreshTokenKey = 'refresh_token';
  final String _accessTokenKey = 'access_token';
  final String _refreshUrl = 'https://yourapi.com/refresh';

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse(_refreshUrl),
      body: jsonEncode({'refreshToken': refreshToken}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setAccessToken(data['accessToken']);
      return true;
    }

    return false;
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}
