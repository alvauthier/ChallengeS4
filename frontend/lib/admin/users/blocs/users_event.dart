part of 'users_bloc.dart';

@immutable
sealed class UsersEvent {}

final class UsersDataLoaded extends UsersEvent {}