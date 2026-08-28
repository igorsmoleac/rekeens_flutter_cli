import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';

class RepositoryGenerator extends BaseGenerator {
  Future<void> generate(
    String featureName,
    String repositoryName, {
    bool force = false,
  }) async {
    if (featureName.isEmpty || repositoryName.isEmpty) {
      throw Exception('Feature name and repository name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(repositoryName)) {
      throw Exception('Names must be in snake_case.');
    }

    final featureDir = getFeatureDir(featureName);
    final repositoriesDir = p.join(featureDir, 'data', 'repositories');
    final targetPath = p.join(
      repositoriesDir,
      '${repositoryName}_repository.dart',
    );
    checkFileExists(targetPath, 'Repository "$repositoryName"', force: force);

    ensureDirectory(repositoriesDir);

    final className = toPascalCase(repositoryName);
    await copyTemplate(
      templateSubPath: 'repository',
      targetDir: repositoriesDir,
      variables: {'repository_name': repositoryName, 'class_name': className},
    );

    print('Repository "$repositoryName" created in feature "$featureName".');
  }
}
