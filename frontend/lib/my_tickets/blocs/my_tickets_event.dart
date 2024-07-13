part of 'my_tickets_bloc.dart';

@immutable
sealed class MyTicketsEvent {}

final class MyTicketsDataLoaded extends MyTicketsEvent {
  final String userId;

  MyTicketsDataLoaded({required this.userId});
}