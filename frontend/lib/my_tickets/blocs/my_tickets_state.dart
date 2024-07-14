part of 'my_tickets_bloc.dart';

@immutable
sealed class MyTicketsState {}

final class MyTicketsInitial extends MyTicketsState {}

final class MyTicketsLoading extends MyTicketsState {}

final class MyTicketsDataLoadingSuccess extends MyTicketsState {
  final List<Ticket> myTickets;

  MyTicketsDataLoadingSuccess({required this.myTickets});
}

final class MyTicketsDataLoadingError extends MyTicketsState {
  final String errorMessage;

  MyTicketsDataLoadingError({required this.errorMessage});
}