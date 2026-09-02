import 'package:flutter_riverpod/flutter_riverpod.dart';

import '{{provider_name}}_state.dart';

final {{provider_name}}Provider =
    StateNotifierProvider<{{class_name}}Notifier, {{class_name}}State>(
  (ref) => {{class_name}}Notifier(),
);

class {{class_name}}Notifier extends StateNotifier<{{class_name}}State> {
  {{class_name}}Notifier() : super(const {{class_name}}State());

  Future<void> doSomething() async {
    state = state.copyWith(isLoading: true);
    state = state.copyWith(isLoading: false, count: state.count + 1);
  }
}
