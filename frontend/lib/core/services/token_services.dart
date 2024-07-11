import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenService {
  final _storage = const FlutterSecureStorage();
  final String _refreshTokenKey = 'refresh_token';
  final String _accessTokenKey = 'access_token';
  final String _refreshUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/refresh';

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<bool> refreshToken() async {
    // print('Refreshing token...');
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      print('No refresh token found');
      return false;
    }

    if (JwtDecoder.isExpired(refreshToken)) {
      print('Refresh token expired');
      return false;
    }

    print('Refresh token found: $refreshToken');

    final response = await http.post(
      Uri.parse(_refreshUrl),
      body: jsonEncode({"refresh_token": refreshToken}),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print("Token refreshed successfully");
      final data = jsonDecode(response.body);
      await setAccessToken(data['access_token']);
      return true;
    }

    return false;
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> getValidAccessToken() async {
    print('Getting valid access token...');
    String? accessToken = await getAccessToken();
    if (accessToken == null || JwtDecoder.isExpired(accessToken)) {
      print('Access token expired, Generating a new one...');
      bool success = await refreshToken();
      if (success) {
        accessToken = await getAccessToken();
      } else {
        clearTokens();
        return null;
      }
    }
    return accessToken;
  }
}
