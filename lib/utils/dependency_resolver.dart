class DependencyResolver {
  static const Map<String, String> packageVersions = {
    'flutter_riverpod': '^3.4.2',
    'flutter_bloc': '^9.1.1',
    'go_router': '^18.0.0',
    'dio': '^5.11.0',
    'http': '^1.6.0',
    'intl': '^0.20.3',
    'build_runner': '^2.15.1',
    'freezed': '^3.2.5',
    'json_serializable': '^6.14.0',
  };

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

    return deps.map((package) {
      final version = packageVersions[package];
      return version != null ? '$package:$version' : package;
    }).toList();
  }

  static List<String> resolveDevDependencies({bool includeCodegen = false}) {
    if (!includeCodegen) return [];
    return [
      'build_runner:${packageVersions['build_runner']}',
      'freezed:${packageVersions['freezed']}',
      'json_serializable:${packageVersions['json_serializable']}',
    ];
  }
}
