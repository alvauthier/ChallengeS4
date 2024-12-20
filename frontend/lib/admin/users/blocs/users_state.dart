part of 'users_bloc.dart';

@immutable
sealed class UsersState {}

final class UsersInitial extends UsersState {}

final class UsersLoading extends UsersState {}

final class UsersDataLoadingSuccess extends UsersState {
  final List<User> users;

  UsersDataLoadingSuccess({required this.users});
}

final class UsersDataLoadingError extends UsersState {
  final String errorMessage;

  UsersDataLoadingError({required this.errorMessage});
}