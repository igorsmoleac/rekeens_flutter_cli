import 'package:flutter_bloc/flutter_bloc.dart';

import '{{provider_name}}_state.dart';

class {{class_name}}Cubit extends Cubit<{{class_name}}State> {
  {{class_name}}Cubit() : super(const {{class_name}}Initial());

  Future<void> doSomething() async {
    // TODO: implement cubit logic
  }
}
