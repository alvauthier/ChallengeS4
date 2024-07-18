import 'package:flutter/foundation.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/conversation.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc() : super(ConversationsInitial()) {
    on<ConversationsDataLoaded>((event, emit) async {
      emit(ConversationsLoading());

      try {
        final user = await ApiServices.getUser(event.userId);
        final conversationsAsBuyer = user.conversationsAsBuyer;
        final conversationsAsSeller = user.conversationsAsSeller;
        emit(ConversationsDataLoadingSuccess(conversationsAsBuyer: conversationsAsBuyer, conversationsAsSeller: conversationsAsSeller));
      } on ApiException catch (error) {
        emit(ConversationsDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(ConversationsDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}