import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/interest.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'interests_event.dart';
part 'interests_state.dart';

class InterestsBloc extends Bloc<InterestsEvent, InterestsState> {
  InterestsBloc() : super(InterestsInitial()) {
    on<InterestsDataLoaded>((event, emit) async {
      emit(InterestsLoading());

      try {
        final interests = await ApiServices.getAllInterests();
        emit(InterestsDataLoadingSuccess(interests: interests));
      } on ApiException catch (error) {
        emit(InterestsDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(InterestsDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}