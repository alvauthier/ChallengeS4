part of 'my_tickets_bloc.dart';

@immutable
abstract class MyTicketsEvent {}

class MyTicketsDataLoaded extends MyTicketsEvent {
  MyTicketsDataLoaded();
}