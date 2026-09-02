import 'package:rekeens_flutter_cli/utils/app_version.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

/// Handles the `--version` / `-v` top-level flag.
///
/// Returns `true` when the flag was present and the version has been printed,
/// in which case the caller should exit immediately. Returns `false` when the
/// flag was absent and normal command dispatch should proceed.
Future<bool> handleVersionFlag(List<String> args) async {
  if (!args.contains('--version') && !args.contains('-v')) {
    return false;
  }
  logger.info(await getAppVersion());
  return true;
}

/// Rewrites the `g` alias to `generate` in-place.
///
/// Returns the (possibly mutated) argument list so the caller can pass it to
/// the [CommandRunner]. Only the first positional argument is considered, so
/// `rekeens g auth login` becomes `rekeens generate auth login` while
/// `rekeens --version` is left untouched.
List<String> expandAliases(List<String> args) {
  if (args.isNotEmpty && args.first == 'g') {
    return ['generate', ...args.skip(1)];
  }
  return args;
}
