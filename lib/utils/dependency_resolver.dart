class DependencyResolver {
  static List<String> resolve(Map<String, dynamic> options) {
    final deps = <String>[];

    switch (options['state_management']) {
      case 'riverpod':
        deps.add('flutter_riverpod');
        break;
      case 'bloc':
        deps.add('flutter_bloc');
        break;
    }

    switch (options['router']) {
      case 'go_router':
        deps.add('go_router');
        break;
    }

    switch (options['networking']) {
      case 'dio':
        deps.add('dio');
        break;
      case 'http':
        deps.add('http');
        break;
    }

    if (options['localization'] == true) {
      deps.add('intl');
    }

    return deps;
  }
}
