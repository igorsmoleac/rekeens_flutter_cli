import 'package:flutter_bloc/flutter_bloc.dart';

class AppState {
  const AppState();
}

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState());
}
