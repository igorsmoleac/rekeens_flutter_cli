# Changelog

## 0.22.4

- **Removed commented-out `ShellRoute` block from `templates/bootstrap/router.dart`** per STYLE.md §6 ("Не оставлять закомментированный код"): the go_router template shipped with a 15-line commented-out `ShellRoute` example (settings/profile routes inside a `MainShell`); removed entirely, leaving only the active `GoRoute` for the home page

## 0.22.3

- **`main()` is now thin per STYLE.md §1** — `bin/rekeens_flutter_cli.dart` contained `--version` handling and the `g`→`generate` alias rewrite inline; both have been extracted into `lib/utils/arg_preprocessor.dart`
  - New `handleVersionFlag(List<String> args)` — returns `true` when `--version`/`-v` was present (and printed the version), `false` otherwise; caller exits on `true`
  - New `expandAliases(List<String> args)` — rewrites a leading `g` to `generate`, returns the args list unchanged otherwise; only the first positional argument is considered
  - `bin/rekeens_flutter_cli.dart` — `main()` now calls `handleVersionFlag`, builds the `CommandRunner`, and calls `runner.run(expandAliases(args))`; no inline business logic remains
- **Fixed `getAppVersion` crash when package root cannot be resolved** — `getPackageRoot()` was called outside the try/catch in `lib/utils/app_version.dart`, so a `StateError` ("Unable to locate rekeens_flutter_cli package root") propagated uncaught in environments where the CLI is not globally activated (e.g. unit tests); now wrapped in its own try/catch with a `logger.warn` and `'unknown'` fallback, consistent with the existing recovery pattern for YAML parsing errors
- New test file `test/arg_preprocessor_test.dart` (+10 tests: 4 `handleVersionFlag` covering absent/present/`-v`/mixed, 6 `expandAliases` covering `g`/`generate`/non-g/empty/first-only/non-first)

## 0.22.2

- **CI now matches the documented quality gates** — `DOCUMENTATION.md` claimed `dart.yml` runs format verification and `--fatal-infos` analysis, but the workflow only ran `dart analyze` (without `--fatal-infos`) and `dart test`
  - `.github/workflows/dart.yml` — added "Verify formatting" step running `dart format --output=none --set-exit-if-changed lib test bin` (only `lib`/`test`/`bin`; `templates/` contain `{{placeholders}}` that are not valid Dart and cannot be formatted); changed "Analyze project source" from `dart analyze` to `dart analyze --fatal-infos` to match the docs
  - `DOCUMENTATION.md` — "Testing & Code Quality" code block updated to show `lib test bin` (not `.`) with a comment explaining the `templates/` exclusion; `e2e_smoke.yml` description corrected to state all three presets (`minimal`, `mobile`, `full`) are tested as a matrix, not just `--preset=full`

## 0.22.1

- **Silent `catch (_) {}` blocks now log a warning** per STYLE.md §2 ("if recovery is possible, log a warning; otherwise rethrow"): 5 catch blocks across 4 files swallowed exceptions without any diagnostic output, making failures invisible to the user
  - `lib/services/project_scaffolder.dart` — cleanup of partial project dir after `flutter create` failure now logs `Failed to clean up partial project dir: <error>`; `taskkill` fallback to `sigkill` on Windows now logs `taskkill failed, falling back to sigkill: <error>`
  - `lib/utils/template_resolver.dart` — `getPackageRoot()` failure now logs `Could not resolve package root: <error>` before falling back to other template candidates
  - `lib/utils/package_metadata.dart` — `readPackageName` failure now logs `Could not read package name from <path>: <error>` before returning `null`
  - `lib/utils/app_version.dart` — `getAppVersion` failure now logs `Could not read app version from <path>: <error>` before returning `'unknown'`
  - All 5 blocks changed from `catch (_)` to `catch (e)` to include the underlying error in the warning message; `logger` import added to `template_resolver.dart`, `package_metadata.dart`, and `app_version.dart`

## 0.22.0

- **New `entity` and `usecase` generators complete the domain layer** of the Clean Architecture scaffolding: `rekeens g feature` already created `domain/entities/`, `domain/repositories/`, and `domain/usecases/` directories, but only `repository` had a generator — entities and use cases had to be hand-written
  - `rekeens g entity <feature> <name>` — creates `lib/features/<feature>/domain/entities/<name>_entity.dart` (plain Dart class with value equality via `==`/`hashCode` and a `const` constructor; no JSON codegen, no external deps)
  - `rekeens g usecase <feature> <name>` — creates `lib/features/<feature>/domain/usecases/<name>_usecase.dart` with a `<Name>UseCase` class exposing `Future<String> call(<Name>Params params)` and a matching `<Name>Params` class, following the canonical Clean Architecture use case pattern
  - Both generators support `--force`, `--dry-run`, and `--tests`/`--no-tests` like all other generators
- New templates: `templates/features/entity/`, `templates/features/usecase/`, `templates/tests/entity/`, `templates/tests/usecase/`
- New generator classes: `EntityGenerator`, `UseCaseGenerator` (in `lib/generators/`)
- `GenerateCommand` — registers both new generators with `entity` and `usecase` cases; updated "Available:" list in the unknown-type error message
- `ListCommand` — `generators` list extended with `entity` and `usecase` entries (description + example)
- Generated test stubs:
  - `entity_test`: value equality by `id` (same id → equal, different id → not equal)
  - `usecase_test`: `call` returns the injected params input; null input falls back to empty string
- `DOCUMENTATION.md` — new "Entity Generator" and "Use Case Generator" sections; "Generated Test Stubs" table extended with `entity` and `usecase` rows
- `README.md` — quick-start examples and commands table extended with `entity` and `usecase`
- Tests: `all_generators_test.dart` (+14 tests: 5 EntityGenerator + 5 UseCaseGenerator + 2 EntityGenerator tests + 2 UseCaseGenerator tests), `generate_command_test.dart` (+2 tests: missing entity name, missing usecase name), `list_command_test.dart` (extended assertions for `entity`/`usecase` in list, examples, and generators set)

## 0.21.3

- **Repository test template now exercises the interface, not just the implementation** per STYLE.md §6 ("don't create an abstraction if it isn't used"): the generated `repository_test.dart` instantiated `RepositoryImpl` directly, leaving the `abstract class` interface with no consumer in the test
  - `templates/tests/repository/{{repository_name}}_repository_test.dart` — now imports the domain interface, declares both test subjects as `{{class_name}}Repository` (the interface type), and adds a `_Fake{{class_name}}Repository implements {{class_name}}Repository` mock with injected items to demonstrate the interface is actually exercised
  - Two tests: impl returns empty list by default; fake returns the injected items through the interface
  - No new dev dependency required (hand-written fake instead of mocktail/mockito, keeping the generated project dependency-light)
  - `test/all_generators_test.dart` — RepositoryGenerator test group now also asserts the test file imports the `domain/repositories` interface and contains `implements UserRepository`

## 0.21.2

- **Removed addressless `// TODO: implement ...` comments from generator templates** per STYLE.md §6 (anti-AI markers): templates must ship either a concrete example or a meaningful no-op stub, never a bare TODO
  - `templates/features/service/{{service_name}}_service.dart` — `performAction` body is now an empty `async {}` no-op (test `performAction completes` still passes)
  - `templates/features/provider/{{provider_name}}_provider.dart` — `doSomething` body is now an empty `async {}` no-op
  - `templates/features/cubit/{{provider_name}}_cubit.dart` — `doSomething` now emits a concrete `{{class_name}}Loading` state instead of a TODO, demonstrating the canonical `emit(...)` pattern
  - `templates/features/cubit/{{provider_name}}_state.dart` — added `{{class_name}}Loading` state class to back the emit example
  - Repository template TODO was already removed in 0.21.0 (`return [];` stub)

## 0.21.1

- **`dio_client.dart` now matches `http_client.dart` HTTP verb coverage**: added `put` and `delete` methods so projects generated with `--networking=dio` can perform PUT/DELETE requests without manual edits
  - `put<T>(path, {body, headers})` delegates to `_dio.put` via the existing `_request` wrapper (consistent error handling through `ApiException`)
  - `delete<T>(path, {headers})` delegates to `_dio.delete` via the same wrapper
  - Signatures mirror `http_client.dart` (`body` + `headers` for `put`, `headers` only for `delete`)

## 0.21.0

- **Repository generator split across Clean Architecture layers**: the interface and implementation are no longer emitted into a single file inside `data/repositories/` (which left `domain/repositories/` empty and violated layer separation)
  - Interface (`abstract class`) is now created at `lib/features/<feature>/domain/repositories/<name>_repository.dart`
  - Implementation is now created at `lib/features/<feature>/data/repositories/<name>_repository_impl.dart` and imports the interface via a relative path
- `templates/features/repository/` restructured into `domain/` and `data/` subdirectories replacing the previous single `{{repository_name}}_repository.dart` template
- `RepositoryGenerator.generate` — checks both target paths for existing files (respecting `--force`), ensures both directories exist, and emits two `copyTemplate` calls; dry-run logs both planned files
- `templates/tests/repository/{{repository_name}}_repository_test.dart` — import updated to the `_repository_impl.dart` path
- `DOCUMENTATION.md` — "Repository Generator" section updated to describe the two-file output and Clean Architecture split
- Tests: `all_generators_test.dart` RepositoryGenerator group updated to assert both the `domain/` interface and `data/` implementation files are created with correct content and relative import

## 0.20.1

- Fix info-level warning in generated app_typography.dart by using non-nullable fontFamily with empty string fallback

## 0.20.0

- **Generated test stubs**: all component generators (`feature`, `screen`, `model`, `repository`, `service`, `provider`/`cubit`) now create a test file alongside the main source by default
  - Test files are placed under `test/features/<feature>/...` mirroring the `lib/` structure
  - `model_test`: constructor equality, `fromJson`, `toJson`, round-trip
  - `repository_test`: `getItems` returns empty list
  - `service_test`: `performAction` completes without throwing
  - `screen_test` / `feature_test`: widget tests — AppBar title, body text, renders without throwing
  - `provider_test` (riverpod): `ProviderContainer` resolves the provider
  - `cubit_test` (bloc): `blocTest` verifies initial state
  - Test stubs use `package:{{project_name}}/...` imports resolved from `pubspec.yaml`'s `name:` field
- New `--tests` / `--no-tests` flag on `rekeens generate` (default: `--tests`); use `--no-tests` to skip test generation
- `BaseGenerator` — new `generateTest()` helper and `projectDir` / `getProjectName()` accessors; `generate()` methods in all 6 generators gained a `withTests` parameter (default `true`); dry-run mode logs planned test file creation
- New test templates under `templates/tests/` category: `feature/`, `screen/`, `model/`, `repository/`, `service/`, `cubit/`, `provider/` — separate from `templates/features/` for architectural clarity
- `BaseGenerator.copyTemplate` — new `category` parameter (default `'features'`); `generateTest()` passes `category: 'tests'`
- `GenerateCommand` — new `--tests` flag, passes `withTests` to all generators
- `DOCUMENTATION.md` — "Common Generator Flags" section updated with `--tests`/`--no-tests`, new "Generated Test Stubs" table, templates table updated with test subdirectories
- Tests: +14 new tests covering test file generation for all 6 generators (default creates test, `withTests=false` skips, dry-run doesn't write)

## 0.19.0

- New `--pin-versions` CLI flag (and `pin_versions` key in `rekeens.yaml`): when enabled, `flutter pub add` is invoked with `--exact` so dependencies are pinned to the latest resolved version instead of using caret ranges — ensures reproducible installs across machines and over time
- `ProjectScaffolder._addDependencies` — new `pinVersions` parameter; when true, `--exact` is inserted into `flutter pub add` args before `--dev` and package names; applies to both regular and dev dependencies
- `ProjectScaffolder.scaffold` — reads `options['pin_versions']` and passes it to `_addDependencies` for both the main and dev dependency calls
- `OptionsResolver` — `pin_versions` added to `_hasAnyCreateFlag`, `_collectOptionsFromFlags`, `_fillDefaults` (default `false`), and interactive prompt (new `askYesNo` after codegen)
- `CreateCommand` — new `--pin-versions` / `--no-pin-versions` flag
- `ConfigInitCommand` — default `rekeens.yaml` now includes `pin_versions: false`
- `DOCUMENTATION.md` — CLI flags table updated with `--pin-versions`, config schema updated with `pin_versions`
- Tests: `options_resolver_test.dart` (+3 tests: `--pin-versions` sets true, `--no-pin-versions` sets false, defaults false in preset/fillDefaults), `project_scaffolder_test.dart` (+2 tests: `--exact` present when `pin_versions=true`, absent when `false`), `config_init_command_test.dart` (+1 assertion: `pin_versions` in loaded config)

## 0.18.0

- `templates/base/lib/app/theme/app_colors.dart` — filled with real semantic color tokens: brand (`primary`/`secondary`/`tertiary`), semantic (`error`/`success`/`warning`/`info`), light & dark surfaces, outlines, dividers, scrim/shadow — `seedColor` is now a `{{seed_color}}` placeholder driven by the new `seed_color` option
- `templates/base/lib/app/theme/app_typography.dart` — expanded from 4 styles to a complete Material 3 `TextTheme` (all 15 styles: display/headline/title/body/label × large/medium/small) with proper font sizes, weights, letter-spacing, and line heights — `fontFamily` is conditionally rendered via `{{#if has_font}}` from the new `font_family` option
- `templates/base/lib/app/theme/app_theme.dart` — now imports and uses `AppColors.seedColor` + `AppTypography.textTheme` to build light/dark `ThemeData` (previously hardcoded `Colors.blue` seed and ignored typography); `useMaterial3` is driven by `{{use_material3}}` placeholder
- `templates/bootstrap/app.dart` — replaced inline `ThemeData(...)` with `theme: AppTheme.light` + `darkTheme: AppTheme.dark` (imports `theme/app_theme.dart`); theme logic is now centralized in `AppTheme` instead of duplicated inline
- `ProjectScaffolder._applyTemplate` — now receives `options` map and passes `seed_color`, `font_family`, `use_material3` as variables plus `has_font`/`material3` as conditions to `TemplateService.copyTemplate` for the base template
- New `--seed-color` CLI flag: accepts hex color in `0xFFRRGGBB`, `#RRGGBB`, `RRGGBB`, or `0xAARRGGBB` format; normalized to `0xFFRRGGBB` uppercase by `OptionsResolver._normalizeHexColor`; validated for length and hex characters
- New `--font-family` CLI flag: accepts a font family name string; empty value is not stored (system default)
- `OptionsResolver`: `seed_color` and `font_family` added to `_hasAnyCreateFlag`, `_collectOptionsFromFlags`, `_fillDefaults` (defaults `0xFF2196F3` and `''`), and interactive prompt (two new `askString` prompts after theme)
- `Preset` class: added `seedColor` (default `0xFF2196F3`) and `fontFamily` (default `''`) fields; `toOptions()` now includes `seed_color` and `font_family`
- Presets updated: `minimal` uses `0xFF2196F3` (blue), `mobile` uses `0xFF6750A4` (purple), `full` uses `0xFF6750A4` + `Roboto` font
- `ConfigInitCommand` default `rekeens.yaml` now includes `seed_color: 0xFF2196F3` and `font_family: ''`
- `DOCUMENTATION.md` updated: theme directory tree description, presets table (added Seed Color + Font columns), CLI flags table (added `--seed-color` and `--font-family`), config schema (added `seed_color` and `font_family`), new "Theme Customization" subsection documenting both keys
- Tests: `presets_test.dart` (+5 tests: seed_color/font_family for each preset + toOptions keys), `options_resolver_test.dart` (+7 tests: preset seed_color/font_family, invalid seed-color validation, hex normalization variants, empty font-family), `config_init_command_test.dart` (+2 assertions: seed_color and font_family in loaded config), `project_file_writer_test.dart` (theme tests rewritten: verify AppTheme.light/dark usage instead of inline ThemeData), new `theme_templates_test.dart` (8 tests: app_colors seed_color substitution, app_typography full TextTheme + font_family conditional, app_theme useMaterial3 + AppColors/AppTypography references)

## 0.17.0

- New `analysis_options` top-level section in `rekeens.yaml`: when present, `rekeens create` serializes its content to `analysis_options.yaml` in the generated project, overriding the default `flutter_lints` config from `flutter create` — previously generated projects always used the default lints with no way to customize
- `ConfigLoader.loadAnalysisOptions()`: reads the top-level `analysis_options` section from `rekeens.yaml` and returns it as a deeply-converted `Map<String, dynamic>` (nested `YamlMap`/`YamlList` are recursively converted to plain Dart types via new `_convertYamlNode` helper so the result can be serialized back to YAML)
- `OptionsResolver.resolve()` refactored: existing logic moved to `_resolveOptions()`, `resolve()` now wraps it and merges `analysis_options` from config into the options map — works regardless of whether preset, flags, config defaults, or interactive prompt produced the base options
- `ProjectFileWriter._renderAnalysisOptions()`: writes `analysis_options.yaml` using `YamlEditor` when `options['analysis_options']` is present; skips silently when absent (default from `flutter create` is preserved)
- `ConfigInitCommand` default `rekeens.yaml` now includes a commented-out `analysis_options` section with example `include`, `analyzer.language`, `analyzer.errors`, and `linter.rules` entries
- `DOCUMENTATION.md` updated: Schema Specification section now documents the `analysis_options` top-level key with a full example and explanation
- Tests: `config_loader_test.dart` (+7 tests for `loadAnalysisOptions`: nested map, absent section, no config file, non-map value, list rules, invalid YAML warning, home config fallback), `options_resolver_test.dart` (+4 tests: analysis_options from config, absent section, with preset, no config file), `project_file_writer_test.dart` (+3 tests: writes YAML with nested map, skips when absent, handles list-style linter rules), `config_init_command_test.dart` (+2 tests: commented example present, commented section not parsed)

## 0.16.0

- `templates/bootstrap/router.dart` (go_router variant) now includes a commented `ShellRoute` example demonstrating nested routes with a shared wrapper widget (e.g. scaffold with nav bar) — the home route remains a top-level `GoRoute` so the template compiles out of the box
- New `lib/services/router_updater.dart` (`RouterUpdater`): idempotently adds routes to an existing `lib/app/router.dart` — detects go_router vs simple `AppRouter` variant from file content, inserts `GoRoute` entries (with import) or `static const String` route names, skips if the route path already exists, respects `--dry-run`, skips silently if `router.dart` is absent
- `FeatureGenerator` now calls `RouterUpdater` after creating a feature: adds `/<feature_name>` route pointing to `<ClassName>Page` (e.g. `/auth` → `AuthPage`)
- `ScreenGenerator` now calls `RouterUpdater` after creating a screen: adds `/<feature_name>/<screen_name>` route pointing to `<ClassName>Screen` (e.g. `/auth/login` → `LoginScreen`)
- Route naming convention: feature `auth` → path `/auth`; screen `login` in `auth` → path `/auth/login`; simple-router constant names use lowerCamelCase (e.g. `authLogin`)
- `DOCUMENTATION.md` updated: Feature Generator and Screen Generator sections now document automatic route addition; `router.dart` tree description updated to mention ShellRoute example
- New `test/router_updater_test.dart` (10 tests): go_router route addition (feature + screen), idempotency, existing route preservation, dry-run, simple AppRouter route constants, camelCase naming for multi-word names, missing router.dart handling
- `test/generators_test.dart` updated: 2 new tests verifying FeatureGenerator and ScreenGenerator add routes to `router.dart`
- `test/helpers/generator_test_helper.dart` updated: now creates `lib/app/router.dart` with a go_router template in the temp project so generator tests can verify route auto-addition

## 0.15.0

- New `--storage` option (`shared_preferences`, `secure_storage`, `none`, default `shared_preferences`) adds a local key-value storage abstraction to the generated project — previously `core/storage/` was an empty README despite being documented as a ready layer
- `ProjectFileWriter.configureProjectFiles` now renders `core/storage` templates: `key_value_storage.dart` (abstract interface with `read`/`write`/`delete`/`clear`) is always rendered when storage is enabled, plus the matching implementation (`shared_preferences_storage.dart` or `secure_storage.dart`); `--storage=none` (or omitting the option) leaves the directory untouched
- New `templates/core/key_value_storage.dart`: abstract `KeyValueStorage` interface — `read`, `write`, `delete`, `clear` — so features depend on the abstraction, not the concrete package
- New `templates/core/shared_preferences_storage.dart`: `SharedPreferencesStorage implements KeyValueStorage` wrapping `package:shared_preferences`
- New `templates/core/secure_storage.dart`: `SecureStorage implements KeyValueStorage` wrapping `package:flutter_secure_storage`
- `DependencyResolver` now adds `shared_preferences` or `flutter_secure_storage` based on the `storage` option
- `Preset` class gains a `storage` field: `minimal` → `none`, `mobile` → `shared_preferences`, `full` → `secure_storage`; `toOptions()` includes `storage`
- `OptionsResolver` validates `--storage` against allowed values, includes it in `_hasAnyCreateFlag`, `_fillDefaults`, `_validateConfigOptions`, and the interactive prompt (after networking)
- `ConfigInitCommand` default `rekeens.yaml` now includes `storage: shared_preferences`
- `ListCommand` preset output now shows `storage: <value>`
- `CreateCommand` exposes `--storage` flag
- `DOCUMENTATION.md` updated: `core/storage/` directory tree, presets table (new Storage column), CLI flags table (`--storage` row), `core` Template Categories row, config file schema example
- Tests updated: `presets_test.dart` (storage assertions for all 3 presets + `toOptions` keys), `options_resolver_test.dart` (invalid/valid storage values, defaults, single-value flags, config file, interactive prompt), `dependency_resolver_test.dart` (shared_preferences + secure_storage deps), `config_init_command_test.dart` (storage in loaded config), `list_command_test.dart` (storage in output), `project_scaffolder_test.dart` (storage in options maps + dep assertions), `project_file_writer_test.dart` (4 new tests: shared_preferences, secure_storage, none, omitted)

## 0.14.0

- `ProjectFileWriter.configureProjectFiles` now renders `core/errors` templates into the generated project, completing the error-handling stack: `failure.dart` and `result.dart` are always rendered (foundational types), `exception_to_failure_mapper.dart` is rendered only when `--networking` is not `none` (it imports `ApiException` from `core/network/`)
- New `templates/core/failure.dart`: sealed `Failure` class with `ServerFailure` (5xx), `ClientFailure` (4xx), `NetworkFailure`, `CacheFailure`, and `UnknownFailure` subclasses — replaces the draft that had a `CacheFailure` constructor typo and no `ClientFailure` (causing dead code in the mapper where both 4xx and 5xx returned `ServerFailure`)
- New `templates/core/result.dart`: `Result<T>` sealed class with `Success<T>` / `FailureResult<T>` and convenience getters (`isSuccess`, `isFailure`, `valueOrNull`, `failureOrNull`) — replaces `Either<Failure, T>` from `dartz` with a dependency-free idiomatic Dart 3 sealed class, following STYLE.md's "don't add dependencies without necessity" rule
- Rewrote `templates/core/exception_to_failure_mapper.dart`: fixed broken `package:rekeens_flutter_cli/...` imports (templates render into a generated project with a different name — now uses relative `import 'failure.dart'` and `import '../network/api_exception.dart'`); 4xx now maps to `ClientFailure` instead of falling through to the unreachable `ServerFailure` branch; `null` statusCode maps to `NetworkFailure`
- Reuses the existing `ApiException` from `core/network/api_exception.dart` (added in 0.13.0) instead of duplicating it as a separate `AppException` — both carry `message`, `statusCode`, and `responseBody`
- `DOCUMENTATION.md` updated: `core/errors/` directory tree now lists the generated files; `core` row in Template Categories expanded to cover error templates
- 5 new tests in `project_file_writer_test.dart` covering: failure+result always rendered (even without networking), mapper rendered for dio/http, mapper omitted for none/omitted networking, no `package:rekeens_flutter_cli` imports in rendered mapper

## 0.13.0

- `ProjectFileWriter.configureProjectFiles` now renders `core/network` templates into the generated project based on the `--networking` option, so users get a ready-to-use HTTP layer instead of just a dependency
- When `--networking=dio` or `--networking=http`, the CLI writes `network_config.dart`, `api_exception.dart`, and the matching client (`dio_client.dart` / `http_client.dart`) into `lib/core/network/`; `--networking=none` (or omitting the option) leaves the directory untouched
- Rewrote `templates/core/dio_client.dart` with an auth-token interceptor (`Authorization: Bearer`), request logging via `LogInterceptor`, and error handling that converts `DioException` into `ApiException`
- Rewrote `templates/core/http_client.dart` with the same auth-token + logging + error-handling concerns, exposing `get`/`post`/`put`/`delete` and throwing `ApiException` on non-2xx responses
- New `templates/core/api_exception.dart` provides a typed exception carrying `message`, `statusCode`, and `responseBody`
- `templates/core/network_config.dart` gains an optional `TokenProvider` callback so callers can supply the current bearer token without subclassing the client
- Renamed the internal `_renderBootstrapFile` helper to `_renderTemplateFile` (now generic enough to render files from any template category, not just `bootstrap`)
- New tests cover dio/http/none/omitted networking scenarios in `project_file_writer_test.dart`
- `DOCUMENTATION.md` updated: `core/network/` directory tree now lists the generated files; new `core` row added to the Template Categories table; `--networking` flag description notes the scaffolding output, not just the dependency

## 0.12.0

- Add validation for enum-like options (state-management, router, networking, theme, architecture, platforms) with clear error messages
- Log warning when `rekeens.yaml` parsing fails instead of silently ignoring
- Expand e2e smoke test to cover all presets (`minimal`, `mobile`, `full`) using matrix strategy
- Add unit tests for invalid option values
- Unify model generation with explicit fields through template system with `{{#each}}` support
- Add Windows CI matrix to run unit tests on Windows, covering Windows-specific process handling

## 0.11.10

- `Dart CI` workflow (`.github/workflows/dart.yml`) now runs `dart analyze` + `dart test` on both `ubuntu-latest` and `windows-latest` via an OS matrix, instead of only Ubuntu
- Guarantees that Windows-specific code branches are actually executed in CI: `defaultScaffoldProcessRunner`'s `cmd /c` process spawn and `taskkill /F /T /PID` process-tree kill, `ConfigLoader`'s `USERPROFILE` fallback, `TemplateResolver`'s `USERPROFILE` home detection, and `DoctorCommand`'s Windows-only tool checks
- The `defaultScaffoldProcessRunner` timeout test branches on `Platform.isWindows` (`ping -t localhost` vs `sleep 30`) — previously only the `sleep` path ran in CI, leaving the `taskkill` path untested
- `fail-fast: false` ensures both OS jobs complete, surfacing failures on either platform in a single run
- Cache key already used `${{ runner.os }}`, so pub caches remain per-OS without key collisions

## 0.11.9

- Unified model generation on the template system: `ModelGenerator` no longer uses `StringBuffer` to build model source for `--fields` — it now renders a `model_with_fields` template via `copyTemplate`, matching the approach used for all other generators and bootstrap files
- Extended `TemplateService` with `{{#each list}}...{{/each}}` loop support: `renderContent`, `copyTemplate`, and `renderFile` accept an optional `lists` parameter (`Map<String, List<Map<String, String>>>`); each block's inner content is repeated per item with item-specific variable substitution
- New template `templates/features/model_with_fields/{{model_name}}_model.dart` contains the class skeleton with four `{{#each fields}}` sections (field declarations, constructor params, fromJson lines, toJson lines)
- Per-field expressions that involve type-specific logic (`fromJson` casts, `DateTime` parsing, nullable handling) are pre-computed in Dart (`_buildFieldVariables`) and passed as string variables to the template — the template handles structure and iteration, Dart handles type dispatch
- Removed `_generateModelSource`, `_jsonKey`, and unused `generateSourceForTest` from `ModelGenerator`; removed unused `dart:io` import
- `BaseGenerator.copyTemplate` now accepts and forwards an optional `lists` parameter
- 6 new `template_service_test.dart` tests covering `{{#each}}` iteration, empty/missing lists, multiple blocks, combination with top-level variables, and `copyTemplate` integration

## 0.11.8

- E2E smoke workflow (`.github/workflows/e2e_smoke.yml`) now scaffolds and validates all three presets (`minimal`, `mobile`, `full`) via a `strategy.matrix` instead of only `--preset=full` 
- Each preset exercises a different combination of conditional template blocks (`{{#if}}`/`{{#unless}}` on `state_management`, `router`, `networking`, `localization`, `codegen`); the `minimal` preset is the only one that hits the `none` branches for state/router/networking, so a regression there previously went undetected
- `fail-fast: false` ensures all preset jobs run to completion, surfacing every failing preset in a single push rather than aborting on the first failure
- Job name reflects the preset: `create (<preset>) + analyze + test` 
- E2E smoke workflow (`.github/workflows/e2e_smoke.yml`) now scaffolds and validates all three presets (`minimal`, `mobile`, `full`) via a `strategy.matrix` instead of only `--preset=full`
- Each preset exercises a different combination of conditional template blocks (`{{#if}}`/`{{#unless}}` on `state_management`, `router`, `networking`, `localization`, `codegen`); the `minimal` preset is the only one that hits the `none` branches for state/router/networking, so a regression there previously went undetected
- `fail-fast: false` ensures all preset jobs run to completion, surfacing every failing preset in a single push rather than aborting on the first failure
- Job name reflects the preset: `create (<preset>) + analyze + test`


## 0.11.7

- `ConfigLoader.load` now logs a `warning` when `rekeens.yaml` fails to parse instead of silently swallowing the error via `catch (_) { return null; }` 
- The warning includes the resolved config file path, the parse error message, and notes that the CLI is falling back to defaults
- `ConfigLoader.load` accepts an optional `Logger? log` parameter (defaults to the global `logger`) for testability, mirroring the `ListCommand({Logger? log})` injection pattern
- New tests verify the warning is emitted for malformed YAML (unclosed flow sequences) and that no warning is logged when the config file is absent or valid but lacks a `defaults` section

## 0.11.6

- Validate enum-like options (`--state-management`, `--router`, `--networking`, `--theme`, `--architecture`) against their allowed values in `OptionsResolver._applyFlags` and when loading defaults from `rekeens.yaml` 
- A typo such as `--state-management=Riverpod` now throws a `UsageException` listing the available values instead of silently producing a broken project (no dependency added, no template activated)
- `architecture` currently accepts only `feature-first`; unsupported values are rejected with a clear message
- New `_validateEnumValue`/`_validateConfigOptions` helpers mirror the existing preset validation

## 0.11.5

- Clarify documentation: `--architecture` currently supports only `feature-first`; other patterns are planned

## 0.11.4

- Removed hardcoded `packageVersions` map from `DependencyResolver` — dependency versions are no longer pinned in CLI source code
- `flutter pub add` now receives bare package names (e.g. `flutter_riverpod` instead of `flutter_riverpod:^3.4.2`) and resolves the latest compatible version automatically at project creation time
- Eliminates version staleness: the CLI no longer ships outdated constraints that drift behind upstream releases between CLI updates
- Generated projects get the latest stable versions with caret constraints (`^x.y.z`) written by `flutter pub add`, with exact versions pinned in `pubspec.lock` as usual
- The E2E smoke test workflow (`e2e_smoke.yml`) serves as the safety net: it scaffolds a `--preset=full` project and runs `flutter analyze` + `flutter test`, catching any breakage from upstream dependency changes
- Updated `dependency_resolver_test.dart` and `project_scaffolder_test.dart` to expect bare package names instead of `package:version` strings

## 0.11.3

- New E2E smoke test workflow (`.github/workflows/e2e_smoke.yml`) that runs the full `rekeens create` pipeline end-to-end in CI: installs Flutter SDK, activates the CLI globally, scaffolds a project with `--preset=full`, then runs `flutter analyze` and `flutter test` inside the generated project
- Protects templates from silent degradation when dependencies or templates are updated (regressions in generated `main.dart`, `app.dart`, `router.dart`, `l10n`, or the `full` preset dependency set surface as CI failures)
- Triggered on `push`/`pull_request` to `main`/`dev` and via `workflow_dispatch`; runs as a separate job alongside `dart.yml` to keep the heavy Flutter-SDK step isolated from the fast unit-test CI

## 0.11.2

- Add timeouts for all external process invocations (`flutter create`, `flutter pub add`, `flutter pub get`, `flutter gen-l10n`, `dart format`, `flutter analyze`) to prevent the CLI from hanging indefinitely without feedback
- New `ProcessTimeouts` class with conservative per-command timeout constants: `create` (5 min), `pub` (3 min), `genL10n` (2 min), `format` (2 min), `analyze` (5 min)
- `ScaffoldProcessRunner` typedef extended with optional `timeout` parameter
- `defaultScaffoldProcessRunner` rewritten to use `listen`/`Completer` instead of `addStream` (avoids "StreamSink is already bound" errors when called sequentially), kills the process tree on timeout (`taskkill /F /T` on Windows, `SIGKILL` on Unix), and throws a descriptive `TimeoutException` 
- `ProjectScaffolder` passes the appropriate `ProcessTimeouts.*` constant to every `_runProcess` call
- 3 new tests: timeout propagation through the scaffold pipeline (full and minimal), and `defaultScaffoldProcessRunner` timeout behavior (kills on timeout, completes within bounds, null timeout works)

## 0.11.1

- Fix: `AppCubit` and `AppState` are now generated in `lib/core/state/` instead of `lib/app/`, matching the project's layered architecture convention (state management belongs in `core/`, not the app shell)
- `AppState` extracted into its own `app_state.dart` file (was previously inlined in `app_cubit.dart`) with `isLoading` field and `copyWith` for immutable state updates
- `AppCubit` now imports `app_state.dart` and exposes a `setLoading(bool)` method
- `main.dart` import path updated to `core/state/app_cubit.dart` 
- New bootstrap template `templates/bootstrap/app_state.dart` 
- Updated `project_file_writer_test.dart` to verify the new file locations and `AppState` separation

## 0.11.0

- `ProjectFileWriter.enableFlutterGenerate` rewritten to use `yaml` (parsing) + `yaml_edit` (targeted editing) instead of fragile line-by-line `StringBuffer` manipulation
- Fixes edge cases that could break the old implementation: CRLF line endings, `generate:` inside comments, mixed indentation, `flutter:` section absent
- Comments and original formatting are now preserved (YamlEditor performs string-level edits, not full regeneration)
- Added `yaml_edit: ^2.2.4` dependency (official Dart team package for YAML manipulation with comment/whitespace preservation)
- 5 new edge-case tests: CRLF line endings, `generate:` in comments, comment preservation, already-true no-op, real `flutter create` pubspec format

## 0.10.0

- Bootstrap files (`main.dart`, `app.dart`, `router.dart`, `app_cubit.dart`, `l10n.yaml`, `app_en.arb`) are now generated from templates in `templates/bootstrap/` instead of imperative `StringBuffer` code in `ProjectFileWriter` 
- `TemplateService` extended with conditional rendering (`{{#if cond}}...{{/if}}`, `{{#unless cond}}...{{/unless}}`) and a `renderFile` method for single-file rendering with variables and conditions
- `ProjectFileWriter` rewritten to use `TemplateService` + `TemplateResolver` (same resolution chain as feature generators: home → local → built-in); accepts injectable `templateService`, `templateResolver`, `workingDirectory`, and `templatesRootOverride` 
- Static `main.dart`, `app.dart`, `router.dart` removed from `templates/base/` (now generated from `templates/bootstrap/` based on selected options)
- Users can now override bootstrap templates by placing files in `~/.rekeens/templates/bootstrap/` (home) or `./.rekeens/templates/bootstrap/` (local project)
- `ProjectScaffolder` now propagates `workingDirectory` to the default `ProjectFileWriter` 
- No user-facing behavior changes; generated project files are identical to the previous `StringBuffer` output

## 0.9.0

- Refactor `CreateCommand` into a thin controller following SRP: orchestration and option resolution extracted into dedicated services
- New `OptionsResolver` (`lib/services/options_resolver.dart`) handles preset/flag/config/interactive resolution (`_resolveOptions`, `_mergePresetWithFlags`, `_collectOptionsFromFlags`, `_fillDefaults`, `_collectOptions`) — accepts injectable `PrompterService`, `workingDirectory`, and `homeDirectory` for testing
- New `ProjectScaffolder` (`lib/services/project_scaffolder.dart`) runs the creation pipeline: `flutter create` → template copy → file configuration → dependencies → dev dependencies → localization → `dart format` → `flutter analyze`; accepts injectable `processRunner`, `TemplateService`, `TemplateResolver`, `ProjectFileWriter`, `Logger`, and `workingDirectory` for testing
- `CreateCommand.run()` reduced to argument validation, option resolution delegation, dry-run preview, and scaffolder invocation
- Unit tests for `OptionsResolver` (preset resolution, flag overrides, config file merge, defaults, interactive prompt, unknown preset error) and `ProjectScaffolder` (full pipeline order, codegen/localization skipping, empty platforms, `flutter create` failure cleanup)
- No user-facing behavior changes; CLI flags and output are unchanged

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
