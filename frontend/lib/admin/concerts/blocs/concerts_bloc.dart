import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/concert.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'concerts_event.dart';
part 'concerts_state.dart';

class ConcertsBloc extends Bloc<ConcertsEvent, ConcertsState> {
  ConcertsBloc() : super(ConcertsInitial()) {
    on<ConcertsDataLoaded>((event, emit) async {
      emit(ConcertsLoading());

      try {
        final concerts = await ApiServices.getConcerts();
        emit(ConcertsDataLoadingSuccess(concerts: concerts));
      } on ApiException catch (error) {
        emit(ConcertsDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(ConcertsDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}