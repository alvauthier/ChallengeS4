part of 'interests_bloc.dart';

@immutable
sealed class InterestsState {}

final class InterestsInitial extends InterestsState {}

final class InterestsLoading extends InterestsState {}

final class InterestsDataLoadingSuccess extends InterestsState {
  final List<Interest> interests;

  InterestsDataLoadingSuccess({required this.interests});
}

final class InterestsDataLoadingError extends InterestsState {
  final String errorMessage;

  InterestsDataLoadingError({required this.errorMessage});
}