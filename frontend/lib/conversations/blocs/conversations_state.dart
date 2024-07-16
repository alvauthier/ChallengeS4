part of 'conversations_bloc.dart';

@immutable
sealed class ConversationsState {}

final class ConversationsInitial extends ConversationsState {}

final class ConversationsLoading extends ConversationsState {}

final class ConversationsDataLoadingSuccess extends ConversationsState {
  final List<Conversation> conversations;

  ConversationsDataLoadingSuccess({required this.conversations});
}

final class ConversationsDataLoadingError extends ConversationsState {
  final String errorMessage;

  ConversationsDataLoadingError({required this.errorMessage});
}