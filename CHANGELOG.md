# Changelog

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