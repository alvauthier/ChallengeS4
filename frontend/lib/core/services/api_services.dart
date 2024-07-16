import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flinq/flinq.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/core/exceptions/api_exception.dart';
import 'package:frontend/core/models/concert.dart';
import 'package:frontend/core/models/category.dart';
import 'package:frontend/core/services/token_services.dart';
import 'package:http/http.dart' as http;

class ApiServices {
  static const storage = FlutterSecureStorage();
  static Future<List<Concert>> getConcerts() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/concerts';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ApiException(message: 'Bad request');
      }

      final data = json.decode(response.body) as List<dynamic>;
      return data.mapList((e) => Concert.fromJson(e));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching concerts.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<Concert> getConcert(String id) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/concerts/$id';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ApiException(message: 'Bad request');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return Concert.fromJson(data);
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching concert.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

    static Future<List<Category>> getCategories() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/categories';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ApiException(message: 'Bad request');
      }

      final data = json.decode(response.body) as List<dynamic>;
      return data.mapList((e) => Category.fromJson(e));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching concerts.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }
}