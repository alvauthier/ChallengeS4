import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/concert.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<HomeDataLoaded>((event, emit) async {
      emit(HomeLoading());

      Future<String> getUserRoleFromJwt() async {
        const storage = FlutterSecureStorage();
        String? jwt = await storage.read(key: 'access_token');
        if (jwt != null) {
          final parts = jwt.split('.');
          if (parts.length != 3) {
            throw Exception('Invalid token');
          }

          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final payloadMap = json.decode(payload);
          if (payloadMap is! Map<String, dynamic>) {
            throw Exception('Invalid payload');
          }

          return payloadMap['role'];
        }
        return '';
      }

      try {
        final userRole = await getUserRoleFromJwt();
        final List<Concert> concerts;

        if (userRole == 'organizer') {
          concerts = await ApiServices.getConcertsByOrga();
        } else {
          concerts = await ApiServices.getConcerts();
        }

        emit(HomeDataLoadingSuccess(concerts: concerts));
      } on ApiException catch (error) {
        emit(HomeDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(HomeDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}