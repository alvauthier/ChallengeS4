import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/ticket.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'tickets_event.dart';
part 'tickets_state.dart';

class TicketsBloc extends Bloc<TicketsEvent, TicketsState> {
  TicketsBloc() : super(TicketsInitial()) {
    on<TicketsDataLoaded>((event, emit) async {
      emit(TicketsLoading());

      try {
        final tickets = await ApiServices.getTickets();
        emit(TicketsDataLoadingSuccess(tickets: tickets));
      } on ApiException catch (error) {
        emit(TicketsDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(TicketsDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}