part of 'profile_bloc.dart';

abstract class ProfileEvent {}

class ProfileDataLoaded extends ProfileEvent {
  final String userId;

  ProfileDataLoaded({required this.userId});
}