part of 'ticket_listings_bloc.dart';

@immutable
sealed class TicketListingsState {}

final class TicketListingsInitial extends TicketListingsState {}

final class TicketListingsLoading extends TicketListingsState {}

final class TicketListingsDataLoadingSuccess extends TicketListingsState {
  final List<TicketListing> ticketListings;

  TicketListingsDataLoadingSuccess({required this.ticketListings});
}

final class TicketListingsDataLoadingError extends TicketListingsState {
  final String errorMessage;

  TicketListingsDataLoadingError({required this.errorMessage});
}