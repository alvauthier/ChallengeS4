import 'package:flutter/cupertino.dart';
import 'package:weezemaster/core/exceptions/api_exception.dart';
import 'package:weezemaster/core/models/category.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc() : super(CategoriesInitial()) {
    on<CategoriesDataLoaded>((event, emit) async {
      emit(CategoriesLoading());

      try {
        final categories = await ApiServices.getCategories();
        emit(CategoriesDataLoadingSuccess(categories: categories));
      } on ApiException catch (error) {
        emit(CategoriesDataLoadingError(errorMessage: error.message));
      } catch (error) {
        emit(CategoriesDataLoadingError(errorMessage: 'Unhandled error'));
      }
    });
  }
}