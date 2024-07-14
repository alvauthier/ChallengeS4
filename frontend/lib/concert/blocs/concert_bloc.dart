import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/concert.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'concert_event.dart';
part 'concert_state.dart';

class ConcertBloc extends Bloc<ConcertEvent, ConcertState> {
  ConcertBloc() : super(ConcertInitial()) {
    on<ConcertDataLoaded>((event, emit) async {
      emit(ConcertLoading());

      try {
        final concert = await ApiServices.getConcert(event.concertId);
        emit(ConcertDataLoadingSuccess(concert: concert));
      } on ApiException catch (error) {
        emit(ConcertDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(ConcertDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}