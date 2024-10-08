part of 'categories_bloc.dart';

@immutable
sealed class CategoriesState {}

final class CategoriesInitial extends CategoriesState {}

final class CategoriesLoading extends CategoriesState {}

final class CategoriesDataLoadingSuccess extends CategoriesState {
  final List<Category> categories;

  CategoriesDataLoadingSuccess({required this.categories});
}

final class CategoriesDataLoadingError extends CategoriesState {
  final String errorMessage;

  CategoriesDataLoadingError({required this.errorMessage});
}