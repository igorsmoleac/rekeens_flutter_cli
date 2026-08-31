class AppState {
  final bool isLoading;

  const AppState({this.isLoading = false});

  AppState copyWith({bool? isLoading}) {
    return AppState(isLoading: isLoading ?? this.isLoading);
  }
}
