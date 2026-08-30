# Changelog

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