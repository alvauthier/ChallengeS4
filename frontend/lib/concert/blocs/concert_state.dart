part of 'concert_bloc.dart';

@immutable
sealed class ConcertState {}

final class ConcertInitial extends ConcertState {}

final class ConcertLoading extends ConcertState {}

final class ConcertDataLoadingSuccess extends ConcertState {
  final Concert concert;

  ConcertDataLoadingSuccess({required this.concert});
}

final class ConcertDataLoadingError extends ConcertState {
  final String errorMessage;

  ConcertDataLoadingError({required this.errorMessage});
}