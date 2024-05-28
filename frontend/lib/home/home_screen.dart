import 'package:flutter/material.dart';
import 'package:frontend/home/blocs/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(HomeDataLoaded()),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is HomeDataLoadingError) {
                return Center(
                  child: Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (state is HomeDataLoadingSuccess) {
                return ListView.builder(
                  itemBuilder: (context, index) {
                    final concert = state.concerts[index];
                    return ListTile(
                      key: Key(concert.id),
                      leading: Image.network(
                        'https://picsum.photos/seed/picsum/200/300'
                      ),
                      title: Text(concert.name),
                      subtitle: Text(concert.date),
                      trailing: Text(concert.location)
                    );
                  },
                  itemCount: state.concerts.length,
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}