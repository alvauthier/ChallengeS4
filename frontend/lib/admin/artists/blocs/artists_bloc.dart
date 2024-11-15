import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/artist.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'artists_event.dart';
part 'artists_state.dart';

class ArtistsBloc extends Bloc<ArtistsEvent, ArtistsState> {
  ArtistsBloc() : super(ArtistsInitial()) {
    on<ArtistsDataLoaded>((event, emit) async {
      emit(ArtistsLoading());

      try {
        final artists = await ApiServices.getAllArtists();
        emit(ArtistsDataLoadingSuccess(artists: artists));
      } on ApiException catch (error) {
        emit(ArtistsDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(ArtistsDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}