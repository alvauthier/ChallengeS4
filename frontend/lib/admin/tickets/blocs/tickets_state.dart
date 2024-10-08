part of 'tickets_bloc.dart';

@immutable
sealed class TicketsState {}

final class TicketsInitial extends TicketsState {}

final class TicketsLoading extends TicketsState {}

final class TicketsDataLoadingSuccess extends TicketsState {
  final List<Ticket> tickets;

  TicketsDataLoadingSuccess({required this.tickets});
}

final class TicketsDataLoadingError extends TicketsState {
  final String errorMessage;

  TicketsDataLoadingError({required this.errorMessage});
}