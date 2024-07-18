import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flinq/flinq.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/concert.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/core/models/category.dart';
import 'package:weezemaster/core/models/ticket.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:http/http.dart' as http;
import 'package:weezemaster/core/models/user.dart';

import '../models/conversation.dart';

class ApiServices {
  static const storage = FlutterSecureStorage();

  // Méthodes de conversion pour User
  static Map<String, dynamic> userToJson(User user) {
    return {
      'ID': user.id,
      'Firstname': user.firstname,
      'Lastname': user.lastname,
      'Tickets': user.tickets.map((e) => ticketToJson(e)).toList(),
      'Conversations': user.conversations.map((e) => conversationToJson(e)).toList(),
    };
  }

  static Map<String, dynamic> ticketToJson(Ticket ticket) {
    // Implémenter la sérialisation de Ticket ici
    return {
      'id': ticket.id,
      // autres champs de Ticket
    };
  }

  static Map<String, dynamic> conversationToJson(Conversation conversation) {
    // Implémenter la sérialisation de Conversation ici
    return {
      'id': conversation.id,
      // autres champs de Conversation
    };
  }

  static User userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['ID'],
      firstname: json['Firstname'],
      lastname: json['Lastname'],
      tickets: json['Tickets'] != null ? List<Ticket>.from(json['Tickets'].map((e) => Ticket.fromJson(e))) : [],
      conversations: (json['Conversations'] as List<dynamic>?)?.map((e) => Conversation.fromJson(e)).toList() ?? [],
    );
  }

  // Récupérer tous les utilisateurs
  static Future<List<User>> getUsers() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/users';
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
      return data.mapList((e) => userFromJson(e));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching users.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  // Ajouter un nouvel utilisateur
  static Future<void> addUser(User user) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/users';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(userToJson(user)),
      );
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ApiException(message: 'Failed to add user');
      }
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while adding user.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  // Mettre à jour un utilisateur
  static Future<void> updateUser(User user) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/users/${user.id}';
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(userToJson(user)),
      );
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ApiException(message: 'Failed to update user');
      }
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while updating user.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  // Supprimer un utilisateur
  static Future<void> deleteUser(String userId) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/users/$userId';
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ApiException(message: 'Failed to delete user');
      }
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while deleting user.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  // Méthodes existantes
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

  static Future<List<Interest>> getAllInterests() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/interests';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ApiException(message: 'Bad request');
      }

      final data = json.decode(response.body) as List<dynamic>;
      return data.mapList((e) => Interest.fromJson(e));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching interests.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<List<Interest>> getUserInterests() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/user/interests';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ApiException(message: 'Bad request');
      }

      final data = json.decode(response.body) as List<dynamic>;
      return data.mapList((e) => Interest.fromJson(e));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching user interests.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<void> addUserInterest(int interestId) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/user/interests/$interestId';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode != 200) {
        throw ApiException(message: 'Failed to add user interest');
      }
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while adding user interest.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<void> removeUserInterest(int interestId) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/user/interests/$interestId';
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode != 204) {
        throw ApiException(message: 'Failed to remove user interest');
      }
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while removing user interest.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<User> getUser(String id) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/users/$id';
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
      return User.fromJson(data);
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching user.', error: error);
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
      log('An error occurred while fetching categories.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<List<Ticket>> getUserTickets() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = 'http://${dotenv.env['API_HOST']}:${dotenv.env['API_PORT']}/tickets/mytickets';
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
      return data.mapList((e) => Ticket.fromJson(e));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching user tickets.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }
}
