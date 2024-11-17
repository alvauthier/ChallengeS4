import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:weezemaster/core/utils/constants.dart';

part 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit(String initialUserRole) : super(NavigationState(bottomNavItems: Routes.homeNamedPage, index: 0, userRole: initialUserRole));

  void getNavBarItem(int index, String userRole) {
    if (userRole == 'user') {
      switch (index) {
        case 0:
          emit(const NavigationState(bottomNavItems: Routes.homeNamedPage, index: 0, userRole: 'user'));
          break;
        case 1:
          emit(const NavigationState(bottomNavItems: Routes.myTicketsNamedPage, index: 1, userRole: 'user'));
          break;
        case 2:
          emit(const NavigationState(bottomNavItems: Routes.conversationsNamedPage, index: 2, userRole: 'user'));
          break;
        case 3:
          emit(const NavigationState(bottomNavItems: Routes.userInterestsNamedPage, index: 3, userRole: 'user'));
          break;
      }
    } else if (userRole == 'organizer') {
      switch (index) {
        case 0:
          emit(const NavigationState(bottomNavItems: Routes.homeNamedPage, index: 0, userRole: 'organizer'));
          break;
        case 1:
          emit(const NavigationState(bottomNavItems: Routes.registerConcertNamedPage, index: 1, userRole: 'organizer'));
          break;
        case 2:
          emit(const NavigationState(bottomNavItems: Routes.profileNamedPage, index: 2, userRole: 'organizer'));
          break;
      }
    } else if (userRole == 'admin') {
      switch (index) {
        case 0:
          emit(const NavigationState(bottomNavItems: Routes.homeNamedPage, index: 0, userRole: 'admin'));
          break;
        case 1:
          emit(const NavigationState(bottomNavItems: Routes.adminNamedPage, index: 1, userRole: 'admin'));
          break;
        case 2:
          emit(const NavigationState(bottomNavItems: Routes.logsNamedPage, index: 2, userRole: 'admin'));
          break;
        case 3:
          emit(const NavigationState(bottomNavItems: Routes.profileNamedPage, index: 3, userRole: 'admin'));
          break;
      }
    } else {
      switch (index) {
        case 0:
          emit(const NavigationState(bottomNavItems: Routes.homeNamedPage, index: 0, userRole: ''));
          break;
        case 1:
          emit(const NavigationState(bottomNavItems: Routes.loginRegisterNamedPage, index: 1, userRole: ''));
          break;
      }
    }
  }

  void updateUserRole(String userRole) {
    int index = 0;

    if(userRole == '') {
      index = 1;
    }

    // Emit a temporary state with a different index to force a rebuild
    emit(NavigationState(bottomNavItems: state.bottomNavItems, index: -1, userRole: state.userRole));
    // Emit the actual state with the updated user role
    emit(NavigationState(bottomNavItems: state.bottomNavItems, index: index, userRole: userRole));
  }
}