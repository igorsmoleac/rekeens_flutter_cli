# Changelog

## 0.8.0

- `rekeens doctor` now checks additional tools beyond Dart/Flutter/Git:
  - **Android SDK**: resolves via `ANDROID_HOME` / `ANDROID_SDK_ROOT` env vars and verifies the directory exists; reports presence of `platform-tools`
  - **Xcode**: runs `xcodebuild -version` on macOS only; skipped on other platforms
  - **Chrome**: tries `google-chrome`/`chromium`/`chrome --version` (Linux), `/Applications/Google Chrome.app` (macOS), `chrome --version` (Windows), and falls back to scanning standard install paths on disk
- Core tools (Dart/Flutter/Git) and optional tools (Android SDK/Xcode/Chrome) are reported in separate sections with distinct summary lines
- `exitCode=1` is set only when a core tool is missing; missing optional tools produce a warning instead
- `DoctorCommand` now accepts injectable `processRunner` and `environment` for testability
- `extractVersion` handles `Xcode` (`Xcode <version>`) and `Chrome` (`<major>.<minor>.<build>.<patch>`) outputs
- Fixed duplicate tool name in doctor output (`Dart Dart 3.5.0` → `Dart 3.5.0`) since `extractVersion` already includes the tool name
- Unit tests for new `extractVersion` cases (Xcode, Chrome, Chromium) and process-runner-injected `run()` covering core-tool success/failure, Android SDK present/missing, and Chrome found/not-found

## 0.7.2

- New `rekeens list` command shows all available presets and generators
- Presets section lists `minimal`, `mobile`, `full` with their configuration (platforms, state management, router, networking, theme, localization, codegen)
- Generators section lists `feature`, `screen`, `model`, `repository`, `service`, `provider` with descriptions and usage examples
- Output uses colored styling via `mason_logger` (yellow section headers, cyan names)
- `ListCommand` accepts an injectable `Logger` for testability
- Unit tests for `ListCommand` covering preset/generator listing, example output, and generator-type consistency with the `generate` command

## 0.7.1

- New `rekeens config init` command generates a `rekeens.yaml` with default settings in the current directory
- Supports `--force`/`-f` to overwrite an existing config and `--dry-run`/`-n` to preview the action without writing
- Generated config is loadable by `ConfigLoader` and matches the CLI defaults (platforms, architecture, state management, router, networking, localization, theme, codegen)
- `ConfigInitCommand` accepts an injectable `workingDirectory` for testability
- Unit tests for `ConfigInitCommand` covering creation, overwrite protection, `--force`, `--dry-run` (long and short forms), `ConfigLoader` round-trip, and missing-subcommand handling

## 0.7.0

- Replace all `print()` calls with colored terminal output via `mason_logger` (`logger.info`, `logger.success`, `logger.warn`, `logger.err`, `logger.detail`)
- New shared `logger` instance in `lib/utils/logger.dart`
- `doctor` command now reports tool checks with green success / red error styling instead of plain `✓`/`✗` bullets
- `create` command step messages use `logger.info`, verbose output uses `logger.detail`, and the final result uses `logger.success`
- Generator success messages (`feature`, `screen`, `model`, `repository`, `service`, `provider`) and dry-run notices now go through the shared logger
- Errors in `main()` are reported via `logger.err` instead of writing to `stderr` directly

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