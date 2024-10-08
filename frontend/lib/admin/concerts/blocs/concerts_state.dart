part of 'concerts_bloc.dart';

@immutable
sealed class ConcertsState {}

final class ConcertsInitial extends ConcertsState {}

final class ConcertsLoading extends ConcertsState {}

final class ConcertsDataLoadingSuccess extends ConcertsState {
  final List<Concert> concerts;

  ConcertsDataLoadingSuccess({required this.concerts});
}

final class ConcertsDataLoadingError extends ConcertsState {
  final String errorMessage;

  ConcertsDataLoadingError({required this.errorMessage});
}