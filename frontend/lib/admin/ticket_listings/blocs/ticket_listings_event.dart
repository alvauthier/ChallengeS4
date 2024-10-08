part of 'ticket_listings_bloc.dart';

@immutable
sealed class TicketListingsEvent {}

final class TicketListingsDataLoaded extends TicketListingsEvent {}