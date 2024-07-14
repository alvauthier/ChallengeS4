import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/core/models/ticket.dart';

part 'my_tickets_event.dart';
part 'my_tickets_state.dart';

class MyTicketsBloc extends Bloc<MyTicketsEvent, MyTicketsState> {
  MyTicketsBloc() : super(MyTicketsInitial()) {
    on<MyTicketsDataLoaded>((event, emit) async {
      emit(MyTicketsLoading());

      try {
        final user = await ApiServices.getUser(event.userId);
        emit(MyTicketsDataLoadingSuccess(myTickets: user.tickets));
      } on ApiException catch (error) {
        emit(MyTicketsDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(MyTicketsDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}