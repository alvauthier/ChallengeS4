import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flinq/flinq.dart';
import 'package:frontend/core/exceptions/api_exception.dart';
import 'package:frontend/core/models/concert.dart';
import 'package:http/http.dart' as http;

class ApiServices {
  static Future<List<Concert>> getConcerts() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8080/concerts'));
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
      final response = await http.get(Uri.parse('http://10.0.2.2:8080/concerts/$id'));
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
}