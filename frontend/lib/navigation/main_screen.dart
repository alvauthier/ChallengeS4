import 'package:flutter/material.dart';
import 'package:weezemaster/controller/navigation_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weezemaster/translation.dart';
import 'package:go_router/go_router.dart';
import 'package:weezemaster/core/utils/constants.dart';
import 'package:weezemaster/shared/named_nav_bar_item_widget.dart';

class MainScreen extends StatefulWidget {
  final Widget screen;

  MainScreen({Key? key, required this.screen}) : super(key: key);

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  String? userRole;

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationCubit, NavigationState>(
      listener: (context, state) {
        setState(() {
          userRole = state.userRole;
        });
      },
      child: Scaffold(
        body: widget.screen,
        bottomNavigationBar: _buildBottomNavigation(context),
      ),
    );
  }
}

BlocBuilder<NavigationCubit, NavigationState> _buildBottomNavigation(BuildContext context) {
  return BlocBuilder<NavigationCubit, NavigationState>(
    buildWhen: (previous, current) => previous.index != current.index,
    builder: (context, state) {
      List<NamedNavigationBarItemWidget> tabs;

      if (state.userRole == 'user') {
        tabs = [
          NamedNavigationBarItemWidget(
            initialLocation: Routes.homeNamedPage,
            icon: const Icon(Icons.home),
            label: translate(context)!.home,
          ),
          NamedNavigationBarItemWidget(
            initialLocation: Routes.myTicketsNamedPage,
            icon: const Icon(Icons.receipt),
            label: translate(context)!.my_tickets,
          ),
          NamedNavigationBarItemWidget(
            initialLocation: Routes.conversationsNamedPage,
            icon: const Icon(Icons.message),
            label: translate(context)!.my_messages,
          ),
          NamedNavigationBarItemWidget(
            initialLocation: Routes.profileNamedPage,
            icon: const Icon(Icons.person),
            label: translate(context)!.my_profile,
          ),
        ];
      } else if (state.userRole == 'organizer') {
        tabs = [
          NamedNavigationBarItemWidget(
            initialLocation: Routes.organizerConcertNamedPage,
            icon: const Icon(Icons.event),
            label: translate(context)!.my_concerts,
          ),
          NamedNavigationBarItemWidget(
            initialLocation: Routes.registerConcertNamedPage,
            icon: const Icon(Icons.add),
            label: translate(context)!.create_a_concert,
          ),
          NamedNavigationBarItemWidget(
            initialLocation: Routes.profileNamedPage,
            icon: const Icon(Icons.person),
            label: translate(context)!.my_profile,
          ),
        ];
      } else if (state.userRole == 'admin') {
        tabs = [
          NamedNavigationBarItemWidget(
            initialLocation: Routes.homeNamedPage,
            icon: const Icon(Icons.home),
            label: translate(context)!.home,
          ),
          NamedNavigationBarItemWidget(
            initialLocation: Routes.adminNamedPage,
            icon: const Icon(Icons.admin_panel_settings_sharp),
            label: translate(context)!.admin_panel,
          ),
          NamedNavigationBarItemWidget(
            initialLocation: Routes.profileNamedPage,
            icon: const Icon(Icons.person),
            label: translate(context)!.my_profile,
          ),
        ];
      } else {
        tabs = [
          NamedNavigationBarItemWidget(
            initialLocation: Routes.homeNamedPage,
            icon: const Icon(Icons.home),
            label: translate(context)!.home,
          ),
          NamedNavigationBarItemWidget(
            initialLocation: Routes.loginRegisterNamedPage,
            icon: const Icon(Icons.login),
            label: translate(context)!.login,
          ),
        ];
      }

      return NavigationBar(
        onDestinationSelected: (value) {
          context.read<NavigationCubit>().getNavBarItem(value, state.userRole);
          context.go(tabs[value].initialLocation);
        },
        destinations: tabs.map((tab) => NavigationDestination(
          icon: tab.icon,
          label: tab.label ?? '',
        )).toList(),
        selectedIndex: state.index,
      );
    },
  );
}