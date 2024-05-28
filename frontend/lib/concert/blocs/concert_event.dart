part of 'concert_bloc.dart';

abstract class ConcertEvent {}

class ConcertDataLoaded extends ConcertEvent {
  final String concertId;

  ConcertDataLoaded({required this.concertId});
}