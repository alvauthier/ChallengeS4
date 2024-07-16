part of 'conversations_bloc.dart';

abstract class ConversationsEvent {}

class ConversationsDataLoaded extends ConversationsEvent {
  final String userId;

  ConversationsDataLoaded({required this.userId});
}