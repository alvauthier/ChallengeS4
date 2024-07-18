part of 'home_bloc.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeDataLoadingSuccess extends HomeState {
  final List<Concert> concerts;

  HomeDataLoadingSuccess({required this.concerts});
}

final class HomeDataLoadingError extends HomeState {
  final String errorMessage;

  HomeDataLoadingError({required this.errorMessage});
}