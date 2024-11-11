part of 'navigation_cubit.dart';

class NavigationState extends Equatable {
  final String bottomNavItems;
  final int index;
  final String userRole;

  const NavigationState({
    required this.bottomNavItems,
    required this.index,
    required this.userRole,
  });

  @override
  List<Object> get props => [bottomNavItems, index, userRole];
}