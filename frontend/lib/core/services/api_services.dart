import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flinq/flinq.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/concert.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/core/models/category.dart';
import 'package:weezemaster/core/models/ticket.dart';
import 'package:weezemaster/core/models/ticket_listing.dart';
import 'package:weezemaster/core/services/token_services.dart';
import 'package:http/http.dart' as http;
import 'package:weezemaster/core/models/user.dart';

class ApiServices {
  static const storage = FlutterSecureStorage();
  static Future<List<Concert>> getConcerts() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/concerts';
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
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/concerts/$id';
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

  static Future<List<Concert>> getConcertsByOrga() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/organization/concerts';
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
      return data.map((e) => Concert.fromJson(e)).toList();
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching concerts.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<List<Interest>> getAllInterests() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/interests';
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
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/user/interests';
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
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/user/interests/$interestId';
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
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/user/interests/$interestId';
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
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/users/$id';
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
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/categories';
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
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/tickets/mytickets';
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

  static Future<dynamic> getConversation(String conversationId) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/conversations/$conversationId';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(message: 'Failed to fetch conversation');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } on SocketException {
      throw ApiException(message: 'Network error');
    } catch (error) {
      throw ApiException(message: 'Unknown error occurred while fetching conversation');
    }
  }

  static Future<void> sendMessage(String conversationId, String content) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/messages';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(
            {
              'content': content,
              'conversation_id': conversationId,
            }
        ),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(message: 'Failed to send message');
      }
    } on SocketException {
      throw ApiException(message: 'Network error');
    } catch (error) {
      throw ApiException(message: 'Unknown error occurred while sending message');
    }
  }

  static Future<String> postConversation(String buyerId, String sellerId, String ticketListingId) async {
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();
    final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/conversations';
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Accept': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'ticket_listing_id': ticketListingId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(message: 'Failed to create conversation');
    }

    final data = json.decode(response.body);
    return data['ID'];
  }

  static Future<String?> checkConversationExists(
    String ticketListingId,
    String buyerId,
  ) async {
    final tokenService = TokenService();
    String? jwtToken = await tokenService.getValidAccessToken();
    final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/conversations/check';
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Accept': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'ticket_listing_id': ticketListingId,
        'buyer_id': buyerId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(message: 'Failed to check conversation');
    }

    debugPrint("Response body: ${response.body}");

    final data = json.decode(response.body);
    debugPrint("Decoded data: $data");

    return data['ID'] == '' ? null : data['ID'];
  }

  static Future<List<User>> getUsers() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/users';
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
      return data.mapList((e) => User.fromJson(e));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching user.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<User> updateUser(String id, String firstname, String lastname, String email) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/users/$id';
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
        }),
      );
      if (response.statusCode != 200) {
        throw ApiException(message: 'Failed to update user');
      }
      return User.fromJson(json.decode(response.body));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while updating user.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<List<Ticket>> getTickets() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/tickets';
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
      log('An error occurred while fetching tickets.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<Ticket> updateTicket(String id, String? userId, String? categoryId) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/tickets/$id';
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'concert_category_id': categoryId,
        }),
      );
      if (response.statusCode != 200) {
        throw ApiException(message: 'Failed to update ticket');
      }
      return Ticket.fromJson(json.decode(response.body));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while updating ticket.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<List<TicketListing>> getTicketListings() async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ticketlisting';
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
      return data.mapList((e) => TicketListing.fromJson(e));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while fetching ticket listings.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<TicketListing> updateTicketListing(String id, double price, String status) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ticketlisting/$id';
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'price': price,
          'status': status,
        }),
      );
      if (response.statusCode != 200) {
        throw ApiException(message: 'Failed to update ticket listing');
      }
      return TicketListing.fromJson(json.decode(response.body));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while updating ticket listing.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<Interest> addInterest(String name) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/interests';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name
        }),
      );
      if (response.statusCode != 201) {
        throw ApiException(message: 'Failed to create interest');
      }
      return Interest.fromJson(json.decode(response.body));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while create interest.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<Interest> updateInterest(int id, String name) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/interests/$id';
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name
        }),
      );
      if (response.statusCode != 200) {
        throw ApiException(message: 'Failed to update interest');
      }
      return Interest.fromJson(json.decode(response.body));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while updating interest.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<void> deleteInterest(int id) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/interests/$id';
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode != 204) {
        throw ApiException(message: 'Failed to delete interest');
      }
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while deleting interest.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<Category> addCategory(String name) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/categories';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name
        }),
      );
      if (response.statusCode != 201) {
        throw ApiException(message: 'Failed to create category');
      }
      return Category.fromJson(json.decode(response.body));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while create interest.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<Category> updateCategory(int id, String name) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/categories/$id';
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name
        }),
      );
      if (response.statusCode != 200) {
        throw ApiException(message: 'Failed to update category');
      }
      return Category.fromJson(json.decode(response.body));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while updating category.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }

  static Future<Concert> updateConcert(String id, String name, String location) async {
    try {
      final tokenService = TokenService();
      String? jwtToken = await tokenService.getValidAccessToken();
      final apiUrl = '${dotenv.env['API_PROTOCOL']}://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/concerts/$id';
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'location': location,
        }),
      );
      if (response.statusCode != 200) {
        throw ApiException(message: 'Failed to update concert');
      }
      return Concert.fromJson(json.decode(response.body));
    } on SocketException catch (error) {
      log('Network error.', error: error);
      throw ApiException(message: 'Network error');
    } catch (error) {
      log('An error occurred while updating concert.', error: error);
      throw ApiException(message: 'Unknown error');
    }
  }
}