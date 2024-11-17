part of 'profile_bloc.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileDataLoadingSuccess extends ProfileState {
  final User user;

  ProfileDataLoadingSuccess({required this.user});
}

final class ProfileDataLoadingError extends ProfileState {
  final String errorMessage;

  ProfileDataLoadingError({required this.errorMessage});
}