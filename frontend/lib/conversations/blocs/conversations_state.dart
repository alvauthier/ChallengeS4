part of 'conversations_bloc.dart';

@immutable
sealed class ConversationsState {}

final class ConversationsInitial extends ConversationsState {}

final class ConversationsLoading extends ConversationsState {}

final class ConversationsDataLoadingSuccess extends ConversationsState {
  final List<Conversation> conversationsAsBuyer;
  final List<Conversation> conversationsAsSeller;

  ConversationsDataLoadingSuccess({required this.conversationsAsBuyer, required this.conversationsAsSeller});
}

final class ConversationsDataLoadingError extends ConversationsState {
  final String errorMessage;

  ConversationsDataLoadingError({required this.errorMessage});
}