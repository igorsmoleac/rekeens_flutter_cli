class DependencyResolver {
  static List<String> resolve(Map<String, dynamic> options) {
    final deps = <String>[];

    final stateManagement = options['state_management'] as String? ?? 'none';
    final router = options['router'] as String? ?? 'none';
    final networking = options['networking'] as String? ?? 'none';
    final localization = options['localization'] as bool? ?? false;

    switch (stateManagement) {
      case 'riverpod':
        deps.add('flutter_riverpod');
        break;
      case 'bloc':
        deps.add('flutter_bloc');
        break;
    }

    switch (router) {
      case 'go_router':
        deps.add('go_router');
        break;
    }

    switch (networking) {
      case 'dio':
        deps.add('dio');
        break;
      case 'http':
        deps.add('http');
        break;
    }

    if (localization) {
      deps.add('intl');
    }

    return deps;
  }

  static List<String> resolveDevDependencies({bool includeCodegen = false}) {
    if (!includeCodegen) return [];
    return ['build_runner', 'freezed', 'json_serializable'];
  }
}
