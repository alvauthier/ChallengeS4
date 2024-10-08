import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/ticket_listing.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'ticket_listings_event.dart';
part 'ticket_listings_state.dart';

class TicketListingsBloc extends Bloc<TicketListingsEvent, TicketListingsState> {
  TicketListingsBloc() : super(TicketListingsInitial()) {
    on<TicketListingsDataLoaded>((event, emit) async {
      emit(TicketListingsLoading());

      try {
        final ticketListings = await ApiServices.getTicketListings();
        emit(TicketListingsDataLoadingSuccess(ticketListings: ticketListings));
      } on ApiException catch (error) {
        emit(TicketListingsDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(TicketListingsDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}