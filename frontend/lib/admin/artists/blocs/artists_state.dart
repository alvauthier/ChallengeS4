part of 'artists_bloc.dart';

@immutable
sealed class ArtistsState {}

final class ArtistsInitial extends ArtistsState {}

final class ArtistsLoading extends ArtistsState {}

final class ArtistsDataLoadingSuccess extends ArtistsState {
  final List<Artist> artists;

  ArtistsDataLoadingSuccess({required this.artists});
}

final class ArtistsDataLoadingError extends ArtistsState {
  final String errorMessage;

  ArtistsDataLoadingError({required this.errorMessage});
}