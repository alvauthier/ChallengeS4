part of 'my_tickets_bloc.dart';

@immutable
abstract class MyTicketsState {}

class MyTicketsInitial extends MyTicketsState {}

class MyTicketsLoading extends MyTicketsState {}

class MyTicketsDataLoadingSuccess extends MyTicketsState {
  final List<Ticket> myTickets;

  MyTicketsDataLoadingSuccess({required this.myTickets});
}

class MyTicketsDataLoadingError extends MyTicketsState {
  final String errorMessage;

  MyTicketsDataLoadingError({required this.errorMessage});
}