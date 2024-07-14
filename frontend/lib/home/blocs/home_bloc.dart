import 'package:flutter/foundation.dart';
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

      try {
        final concerts = await ApiServices.getConcerts();
        emit(HomeDataLoadingSuccess(concerts: concerts));
      } on ApiException catch (error) {
        emit(HomeDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(HomeDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}