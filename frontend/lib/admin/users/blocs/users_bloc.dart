import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/user.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc() : super(UsersInitial()) {
    on<UsersDataLoaded>((event, emit) async {
      emit(UsersLoading());

      try {
        final users = await ApiServices.getUsers();
        emit(UsersDataLoadingSuccess(users: users));
      } on ApiException catch (error) {
        emit(UsersDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(UsersDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}