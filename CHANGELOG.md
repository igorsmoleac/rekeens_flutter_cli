# Changelog

## 0.6.3

- Extract shared generator test setup (temp project creation, `setUpAll`/`setUp`/`tearDown`, `withAuthFeature`) into `test/helpers/generator_test_helper.dart`
- Refactor `generators_test.dart` and `all_generators_test.dart` to use `GeneratorTestHelper`, removing duplicated boilerplate

## 0.6.2

- Unit tests for `ConfigLoader` covering local/home config loading, precedence, invalid YAML, missing defaults section, list conversion, and boolean values
- Unit tests for `presets` covering all three presets (minimal, mobile, full) and `Preset.toOptions()`
- Extended `ProjectFileWriter` tests covering go_router vs none router, material3 vs material2 theme, localization file generation, and `enableFlutterGenerate` (insert, dedup, append, missing pubspec)
- Extended `TemplateService` tests covering binary files, missing source, nested directories, .gitkeep, multiple variables, and unreplaced placeholders
- Unit tests for `PrompterService` covering `askString`, `askYesNo`, `askChoice`, `askMultipleChoice` with mocked stdin/stdout
- `ConfigLoader.load` now accepts optional `workingDirectory` and `homeDirectory` parameters for testability
- `PrompterService` now accepts injectable `output` (StringSink) and `readLine` callback for testability

## 0.6.1

- Unit tests for `DoctorCommand` covering version-string extraction for Dart, Flutter, Git, and edge cases (empty input, non-ASCII bullet stripping, multiline output)
- Unit tests for `GenerateCommand` covering argument validation, unknown-type rejection, missing-name detection for all sub-generators, and `--force`/`--dry-run` flag parsing
- `DoctorCommand.extractVersion` exposed as `@visibleForTesting` to enable pure-logic testing without spawning real processes
- `TemplateResolver.resolve` no longer throws when the built-in package root cannot be located if a matching home or local template is found first

## 0.6.0

- Custom templates support: CLI now resolves templates by searching `~/.rekeens/templates/` (user-global), then `.rekeens/templates/` in the current project (local), and finally the built-in `templates/` shipped with the package
- New `TemplateResolver` utility drives both `create` (base template) and `generate` (feature/screen/model/repository/service/provider templates), so any template can be overridden or new generator types added without modifying CLI source
- Throws a clear `StateError` listing every searched path when a template cannot be found in any location
- Unit tests for `TemplateResolver` covering home > local > built-in precedence and the not-found case

## 0.5.0

- Parameterized model generation: `rekeens g model auth user name:string age:int` generates fields, constructor, `fromJson`, and `toJson` from `name:type` arguments
- Supported types: `String`, `int`, `double`, `bool`, `DateTime`, `List<String>`, `List<int>`, `List<double>`, `List<bool>` (and nullable variants with `?`)
- Type aliases: case-insensitive (`string` → `String`, `datetime`/`date` → `DateTime`), and `[]` array syntax (`string[]` → `List<String>`) for Windows shells where `<>` are metacharacters
- When no fields are provided, falls back to the default template (`id:int`, `name:String`)
- Rejects invalid field formats, unsupported types, and duplicate field names with clear `FormatException` messages

## 0.4.2

- Make `getPackageRoot()` reliable under `dart pub global activate` by resolving the package URI via `Isolate.resolvePackageUri` instead of walking up from `Platform.script` (which points at the Pub cache snapshot)
- Fall back to walking up from `Platform.script` and `Platform.resolvedExecutable`, matching the package by `name` in `pubspec.yaml`
- Throw a clear `StateError` when the package root cannot be located instead of silently returning an incorrect path

## 0.4.1

- Check `flutter create` exit code and abort subsequent steps (template, dependencies, codegen) on failure with a clear error message
- Clean up partially created project directory when `flutter create` fails
- Verify project directory exists after `flutter create` succeeds
- Flush stderr before `exit(64)` in `main()` so error messages are not lost on Windows

## 0.4.0

- Pin dependency versions in `DependencyResolver` (e.g. `flutter_bloc:^9.1.1`, `dio:^5.11.0`) so generated projects get reproducible, compatible package versions
- Add `--codegen` flag to install `build_runner`, `freezed`, and `json_serializable` as dev_dependencies
- `codegen` option is now part of interactive prompts, presets (`full` preset enables it), config file, and dry-run output
- Fix version conflict between `freezed` and `build_runner` by using compatible pinned versions (`build_runner:^2.15.1`, `freezed:^3.2.5`, `json_serializable:^6.14.0`)

## 0.3.0

- Add BLoC support in templates: `main.dart` wraps the app in `BlocProvider` with an `AppCubit` when `state_management: bloc` is selected
- `generate provider` now auto-detects the project's state management from `pubspec.yaml` and generates a Cubit + State (sealed class) for BLoC projects, or a Riverpod provider otherwise
- New `cubit` template (`{{provider_name}}_cubit.dart` + `{{provider_name}}_state.dart`)

## 0.2.0

- Add real localization support (l10n.yaml, ARB, flutter_localizations, flutter gen-l10n)

## 0.1.1

- Initial release
- Project creation with interactive and non-interactive modes
- Feature-first architecture template
- Code generators: feature, screen, model, repository, service, provider
- Presets: minimal, mobile, full
- Configuration file support (`rekeens.yaml`)
- Dynamic dependency management based on selected options
- `doctor` command for environment diagnostics
- Dry-run mode (`--dry-run`) for create and generate commands
- Unit tests for core logic
- Global installation support via `dart pub global activate`