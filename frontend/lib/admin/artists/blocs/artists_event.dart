part of 'artists_bloc.dart';

@immutable
sealed class ArtistsEvent {}

final class ArtistsDataLoaded extends ArtistsEvent {}