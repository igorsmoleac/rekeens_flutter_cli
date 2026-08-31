import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/utils/project_paths.dart';

class TemplateResolver {
  const TemplateResolver({this.homeDirectoryOverride});
  final String? homeDirectoryOverride;

  Future<String> resolve({
    required String category,
    String? subPath,
    String? workingDirectory,
    String? packageRootOverride,
  }) async {
    final segments = <String>[category, ?subPath];

    final candidates = <String>[];

    final home = homeDirectoryOverride ?? _homeDirectory();
    if (home != null) {
      candidates.add(p.joinAll([home, '.rekeens', 'templates', ...segments]));
    }

    final cwd = workingDirectory ?? Directory.current.path;
    candidates.add(p.joinAll([cwd, '.rekeens', 'templates', ...segments]));

    String? root;
    try {
      root = packageRootOverride ?? await getPackageRoot();
    } catch (_) {
      root = null;
    }
    if (root != null) {
      candidates.add(p.joinAll([root, 'templates', ...segments]));
    }

    for (final candidate in candidates) {
      if (Directory(candidate).existsSync()) return candidate;
    }

    final location = subPath == null ? category : '$category/$subPath';
    throw StateError(
      'Template "$location" not found. Searched:\n'
      '${candidates.map((c) => '  - $c').join('\n')}',
    );
  }

  String? _homeDirectory() {
    final env = Platform.environment;
    return env['HOME'] ?? env['USERPROFILE'];
  }
}
