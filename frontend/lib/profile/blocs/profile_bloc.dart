import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/user.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    on<ProfileDataLoaded>((event, emit) async {
      emit(ProfileLoading());

      try {
        final user = await ApiServices.getUser(event.userId);
        emit(ProfileDataLoadingSuccess(user: user));
      } on ApiException catch (error) {
        emit(ProfileDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(ProfileDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}