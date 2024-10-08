part of 'tickets_bloc.dart';

@immutable
sealed class TicketsEvent {}

final class TicketsDataLoaded extends TicketsEvent {}