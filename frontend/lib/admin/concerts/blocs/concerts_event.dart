part of 'concerts_bloc.dart';

@immutable
sealed class ConcertsEvent {}

final class ConcertsDataLoaded extends ConcertsEvent {}