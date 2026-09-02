# Rekeens Flutter CLI — Technical Documentation

This document provides a technical reference for **Rekeens Flutter CLI (`rekeens`)**, including architectural standards, command references, configuration options, code generator specifications, and custom template extensibility.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
   - [Feature-First Clean Architecture](#feature-first-clean-architecture)
   - [Directory Structure](#directory-structure)
   - [Layer Responsibilities](#layer-responsibilities)
2. [Installation & Setup](#2-installation--setup)
   - [Prerequisites](#prerequisites)
   - [Global Activation](#global-activation)
   - [PATH Configuration](#path-configuration)
   - [Diagnostics (`doctor`)](#diagnostics-doctor)
3. [Project Scaffolding (`create`)](#3-project-scaffolding-create)
   - [Creation Modes](#creation-modes)
   - [Presets Specification](#presets-specification)
   - [CLI Flags & Options Reference](#cli-flags--options-reference)
4. [Component Generators (`generate` / `g`)](#4-component-generators-generate--g)
   - [Feature Generator](#feature-generator)
   - [Screen Generator](#screen-generator)
   - [Model Generator & Field Type System](#model-generator--field-type-system)
   - [Repository Generator](#repository-generator)
   - [Service Generator](#service-generator)
   - [Provider / Cubit Generator](#provider--cubit-generator)
   - [Common Generator Flags](#common-generator-flags)
5. [Listing System (`list`)](#5-listing-system-list)
6. [Configuration Management (`rekeens.yaml`)](#6-configuration-management-rekeensyaml)
   - [Schema Specification](#schema-specification)
   - [Resolution Precedence](#resolution-precedence)
   - [Initializing Configuration (`config init`)](#initializing-configuration-config-init)
7. [Custom Template System](#7-custom-template-system)
   - [Template Resolution Hierarchy](#template-resolution-hierarchy)
   - [Template Variables](#template-variables)
8. [Development & Contributing](#8-development--contributing)

---

## 1. Architecture Overview

### Feature-First Clean Architecture

Rekeens organizes applications using a **Feature-First / Clean Architecture** approach. Code is grouped by business domains in `lib/features/<feature_name>/` rather than flat technical layers at the project root.

Benefits:
- **High Cohesion**: Files associated with a single domain feature are kept together.
- **Scalability**: Modules can be developed, maintained, or replaced independently.
- **Testability**: Clear boundaries between presentation (`presentation`), domain rules (`domain`), and data access (`data`).

### Directory Structure

```text
lib/
├── app/                  # Application initialization, root routing & design system
│   ├── app.dart          # Root widget configuring MaterialApp, theme & l10n
│   ├── router.dart       # GoRouter config (with ShellRoute example) / simple AppRouter route constants
│   └── theme/            # Design system tokens (seed-driven colors, full TextTheme)
│       ├── app_colors.dart       # Semantic color tokens (brand, surfaces, outlines) from seed_color
│       ├── app_theme.dart        # light/dark ThemeData from AppColors + AppTypography
│       └── app_typography.dart   # Complete Material 3 TextTheme with optional font_family
│
├── core/                 # Shared cross-cutting infrastructure
│   ├── config/           # App flavors, environments & remote configs
│   ├── constants/        # Global constants, API endpoints & keys
│   ├── errors/           # Failure models, exceptions & error mappers
│   │   ├── failure.dart          # Sealed Failure (Server/Client/Network/Cache/Unknown)
│   │   ├── result.dart           # Result<T> sealed class (Success / FailureResult)
│   │   └── exception_to_failure_mapper.dart  # ApiException → Failure (when networking enabled)
│   ├── extensions/       # Dart extension utilities
│   ├── network/          # HTTP client instance (Dio / Http), interceptors
│   │   ├── network_config.dart  # BaseUrl, timeouts, headers, token provider
│   │   ├── api_exception.dart   # Typed ApiException (message, statusCode, body)
│   │   └── <dio_client|http_client>.dart  # Client w/ auth + log + error handling
│   ├── storage/          # Local key-value storage & cache adapters
│   │   ├── key_value_storage.dart          # Abstract KeyValueStorage interface
│   │   └── <shared_preferences_storage|secure_storage>.dart  # Implementation
│   └── utils/            # General-purpose helper functions
│
├── features/             # Business modules (Domain-Driven boundaries)
│   └── <feature_name>/
│       ├── data/         # Data layer: Remote/Local sources, models, repository impls
│       │   ├── datasources/
│       │   ├── models/
│       │   ├── repositories/
│       │   └── services/
│       ├── domain/       # Domain layer: Entities, repository interfaces, use cases
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/ # UI layer: State controllers, screens & local widgets
│           ├── pages/
│           ├── providers/ # Riverpod StateNotifiers or BLoC Cubits
│           └── widgets/
│
├── shared/               # Reusable presentation components & design primitives
│   ├── components/
│   └── widgets/
│
├── l10n/                 # Localization catalogs (.arb files when l10n is enabled)
│   ├── app_en.arb
│   └── app_localizations.dart
│
└── main.dart             # Entrypoint with root state management wrappers
```

### Layer Responsibilities

| Layer | Responsibility | Dependencies |
| :--- | :--- | :--- |
| **`domain`** | Pure Dart business logic (Entities, Use Cases, Repository Contracts). | Independent of Flutter SDK and third-party packages. |
| **`data`** | Implements repository interfaces, handles HTTP requests and local caching/serialization. | Depends on `domain` and external libraries. |
| **`presentation`** | UI rendering (Screens, Widgets) and state management (Riverpod / BLoC). | Depends on `domain`. |
| **`core`** | Shared utilities, network clients, error models, and app configurations. | Independent of features. |
| **`app`** | App-level entrypoint, global navigation, and theme definitions. | Depends on `core`, `features`, and `shared`. |

---

## 2. Installation & Setup

### Prerequisites

- **Dart SDK**: `>= 3.13.0`
- **Flutter SDK**: `>= 3.0.0`
- **Git**: `>= 2.x`

### Global Activation

Activate the CLI globally using Dart pub:

```bash
dart pub global activate rekeens_flutter_cli
```

### PATH Configuration

Ensure Dart's global pub cache binary directory is in your environment `PATH`:

- **macOS / Linux**:
  ```bash
  export PATH="$PATH":"$HOME/.pub-cache/bin"
  ```
  *(Add to `~/.zshrc`, `~/.bashrc`, or shell profile)*

- **Windows**:
  Ensure `%LOCALAPPDATA%\Pub\Cache\bin` is added to your User `PATH` environment variable.

### Diagnostics (`doctor`)

Verify that development tools and environment dependencies are available:

```bash
rekeens doctor
```

Checks executed:
- **Core (Required)**: `Dart SDK`, `Flutter SDK`, `Git`.
- **Optional**: `Android SDK` (`ANDROID_HOME` / `ANDROID_SDK_ROOT`), `Xcode` (macOS), `Google Chrome` (Web).

---

## 3. Project Scaffolding (`create`)

```bash
rekeens create <project_name> [options]
```

Project names must conform to Dart package naming rules: lower_snake_case starting with a letter or underscore.

### Creation Modes

#### 1. Interactive Mode
Running `rekeens create <project_name>` without options launches an interactive prompt.

#### 2. Preset Mode
Bootstraps a project using a predefined architecture profile:

```bash
rekeens create my_app --preset=mobile
```

#### 3. Headless / Flags Mode
Explicitly supply options for non-interactive execution (e.g., CI/CD scripts):

```bash
rekeens create my_app \
  --platforms=android,ios,web \
  --state-management=riverpod \
  --router=go_router \
  --networking=dio \
  --localization \
  --theme=material3 \
  --codegen
```

### Presets Specification

| Preset | Target Platforms | State Mgmt | Router | Network | Storage | Localization | Theme | Seed Color | Font | Codegen |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`minimal`** | `android, ios` | `none` | `none` | `none` | `none` | `false` | `material3` | `0xFF2196F3` | — | `false` |
| **`mobile`** | `android, ios` | `riverpod` | `go_router` | `dio` | `shared_preferences` | `true` | `material3` | `0xFF6750A4` | — | `false` |
| **`full`** | `android, ios, windows, linux, macos, web` | `riverpod` | `go_router` | `dio` | `secure_storage` | `true` | `material3` | `0xFF6750A4` | `Roboto` | `true` |

### CLI Flags & Options Reference

| Flag / Option | Allowed Values | Default | Description |
| :--- | :--- | :--- | :--- |
| `--preset` | `minimal`, `mobile`, `full` | &mdash; | Uses a preset profile |
| `--platforms` | `android,ios,windows,linux,macos,web` | `android,ios,windows,linux` | Comma-separated list of target platforms |
| `--architecture` | `feature-first` | `feature-first` | Project architecture type. **Supported values:** `feature-first` (currently the only option). Other architecture patterns are on the roadmap. |
| `--state-management` | `riverpod`, `bloc`, `none` | `riverpod` | State management solution |
| `--router` | `go_router`, `none` | `go_router` | Application router |
| `--networking` | `dio`, `http`, `none` | `dio` | HTTP client library and `core/network` scaffolding (client, `network_config.dart`, `api_exception.dart` with auth/log/error handling) |
| `--storage` | `shared_preferences`, `secure_storage`, `none` | `shared_preferences` | Local key-value storage and `core/storage` scaffolding (`key_value_storage.dart` interface + implementation) |
| `--localization` | `--localization`, `--no-localization` | `false` *(Prompt: `true`)* | Enables Flutter `gen-l10n` & `intl` |
| `--theme` | `material3`, `material2` | `material3` | Theme system |
| `--seed-color` | hex string (e.g. `0xFF2196F3`, `#2196F3`) | `0xFF2196F3` | Seed color for `ColorScheme.fromSeed` — drives `AppColors.seedColor` |
| `--font-family` | string (e.g. `Roboto`) | `''` (system default) | Font family applied to all `AppTypography` `TextTheme` styles |
| `--codegen` | `--codegen`, `--no-codegen` | `false` | Adds `build_runner`, `freezed`, `json_serializable` |
| `--pin-versions` | `--pin-versions`, `--no-pin-versions` | `false` | Pins dependency versions with `flutter pub add --exact` for reproducible installs |
| `-n, --dry-run` | Flag | `false` | Previews actions without creating files |
| `-v, --verbose` | Flag | `false` | Enables verbose diagnostic output |

---

## 4. Component Generators (`generate` / `g`)

The generator command scaffolds domain elements into an existing Flutter project.

```bash
rekeens generate <type> <feature_name> [args] [options]
# Alias:
rekeens g <type> <feature_name> [args] [options]
```

### Feature Generator

Scaffolds a new feature directory structure with `data/`, `domain/`, and `presentation/` layers and a starter page. Automatically adds a `GoRoute` (or route constant for non-go_router projects) to `lib/app/router.dart` for the feature's page.

```bash
rekeens g feature authentication
# Creates: lib/features/authentication/...
# Adds route: /authentication -> AuthenticationPage
```

### Screen Generator

Creates a screen page widget inside `lib/features/<feature>/presentation/pages/`. Automatically adds a nested route to `lib/app/router.dart`.

```bash
rekeens g screen authentication login
# Output: lib/features/authentication/presentation/pages/login_screen.dart
# Adds route: /authentication/login -> LoginScreen
```

Route auto-generation is idempotent — running the same generator twice will not duplicate the route entry. If `router.dart` does not exist, the updater logs a warning and skips.

### Model Generator & Field Type System

Creates an immutable model class with a `const` constructor, typed fields, `fromJson` factory, and `toJson` serialization.

```bash
rekeens g model profile user \
  id:string \
  name:string \
  email:string? \
  age:int \
  score:double? \
  isVerified:bool \
  roles:string[] \
  registeredAt:datetime
```

#### Supported Field Syntax & Type Mapping

| CLI Type | Dart Canonical Type | Nullable CLI Syntax | Dart Nullable Type |
| :--- | :--- | :--- | :--- |
| `string`, `String` | `String` | `string?` | `String?` |
| `int` | `int` | `int?` | `int?` |
| `double` | `double` | `double?` | `double?` |
| `bool` | `bool` | `bool?` | `bool?` |
| `datetime`, `date`, `DateTime` | `DateTime` | `datetime?` | `DateTime?` |
| `string[]`, `List<String>` | `List<String>` | `string[]?` | `List<String>?` |
| `int[]`, `List<int>` | `List<int>` | `int[]?` | `List<int>?` |
| `double[]`, `List<double>` | `List<double>` | `double[]?` | `List<double>?` |
| `bool[]`, `List<bool>` | `List<bool>` | `bool[]?` | `List<bool>?` |

### Repository Generator

Splits the repository across Clean Architecture layers: the abstract interface
is created in `lib/features/<feature>/domain/repositories/` and the concrete
implementation in `lib/features/<feature>/data/repositories/`. The
implementation imports the interface via a relative path.

```bash
rekeens g repository profile user
# Output:
#   lib/features/profile/domain/repositories/user_repository.dart        (interface)
#   lib/features/profile/data/repositories/user_repository_impl.dart     (implementation)
```

### Service Generator

Creates a service or API client class inside `lib/features/<feature>/data/services/`.

```bash
rekeens g service authentication auth_api
# Output: lib/features/authentication/data/services/auth_api_service.dart
```

### Provider / Cubit Generator

Generates state management controllers in `lib/features/<feature>/presentation/providers/`.

The CLI automatically detects the active state management package from `pubspec.yaml`:
- If `flutter_bloc` is detected: Generates `<name>_cubit.dart` and `<name>_state.dart`.
- If `flutter_riverpod` is detected: Generates `<name>_provider.dart`.

```bash
rekeens g provider authentication auth
```

### Entity Generator

Creates a domain entity inside `lib/features/<feature>/domain/entities/`. Entities are
plain Dart classes with value equality (`==`/`hashCode`) and a `const` constructor —
no JSON serialization, no external dependencies.

```bash
rekeens g entity profile user
# Output: lib/features/profile/domain/entities/user_entity.dart
```

### Use Case Generator

Creates a domain use case inside `lib/features/<feature>/domain/usecases/`. The use case
exposes a `call(Params)` method and a matching `<Name>Params` class, following the
canonical Clean Architecture use case pattern.

```bash
rekeens g usecase auth login
# Output: lib/features/auth/domain/usecases/login_usecase.dart
```

### Common Generator Flags

- `-f, --force`: Overwrite existing files if they already exist.
- `-n, --dry-run`: Preview planned file generations in the console without writing to disk.
- `--tests` (default) / `--no-tests`: Generate unit/widget test stubs alongside the component. Test files are placed under `test/features/<feature>/...` mirroring the `lib/` structure. Use `--no-tests` to skip test generation.

### Generated Test Stubs

By default, every generator also creates a test file with basic checks:

| Generator | Test file | Test type | Example assertions |
|:---|:---|:---|:---|
| `feature` | `test/features/<f>/presentation/pages/<f>_page_test.dart` | widget | renders without throwing |
| `screen` | `test/features/<f>/presentation/pages/<s>_screen_test.dart` | widget | AppBar title, body text |
| `model` | `test/features/<f>/data/models/<m>_model_test.dart` | unit | constructor equality, `fromJson`, `toJson`, round-trip |
| `repository` | `test/features/<f>/data/repositories/<r>_repository_test.dart` | unit | `getItems` returns empty list |
| `service` | `test/features/<f>/data/services/<s>_service_test.dart` | unit | `performAction` completes |
| `provider` (riverpod) | `test/features/<f>/presentation/providers/<p>_provider_test.dart` | unit | `ProviderContainer` resolves provider |
| `cubit` (bloc) | `test/features/<f>/presentation/providers/<p>_cubit_test.dart` | unit | `blocTest` initial state |
| `entity` | `test/features/<f>/domain/entities/<e>_entity_test.dart` | unit | value equality by `id` |
| `usecase` | `test/features/<f>/domain/usecases/<u>_usecase_test.dart` | unit | `call` returns injected params, null fallback |

Test stubs use `package:{{project_name}}/...` imports resolved from `pubspec.yaml`'s `name:` field. Templates live under `templates/tests/` as a separate category from `templates/features/`.

---

## 5. Listing System (`list`)

To inspect all available presets, generators, and syntax examples directly in the CLI:

```bash
rekeens list
```

---

## 6. Configuration Management (`rekeens.yaml`)

Project or global defaults can be declared in a `rekeens.yaml` file to standardize project configuration.

### Schema Specification

```yaml
defaults:
  platforms:
    - android
    - ios
    - windows
    - linux
  architecture: feature-first
  state_management: riverpod
  router: go_router
  networking: dio
  storage: shared_preferences
  localization: true
  theme: material3
  seed_color: 0xFF6750A4
  font_family: Roboto
  codegen: false
  pin_versions: false

# Optional: custom analysis_options.yaml for generated projects.
# When present, rekeens create writes this section verbatim to
# analysis_options.yaml in the project root, overriding the default
# generated by `flutter create`.
analysis_options:
  include: package:flutter_lints/flutter.yaml
  analyzer:
    language:
      strict-casts: true
      strict-raw-types: true
    errors:
      todo: ignore
  linter:
    rules:
      prefer_const_constructors: true
      prefer_const_declarations: true
      avoid_print: true
      require_trailing_commas: true
```

The `analysis_options` section is a top-level key (not under `defaults`). Its structure mirrors a standard Flutter `analysis_options.yaml` file. When `rekeens create` detects this section, it serializes the content to `analysis_options.yaml` in the generated project, replacing the default `flutter_lints` config from `flutter create`. If the section is absent, the default is left untouched.

#### Theme Customization (`seed_color` & `font_family`)

The `seed_color` and `font_family` keys under `defaults` control the design tokens generated into `lib/app/theme/`:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `seed_color` | hex string | `0xFF2196F3` | Seed color for `ColorScheme.fromSeed`. Accepted formats: `0xFFRRGGBB`, `#RRGGBB`, `RRGGBB`, `0xAARRGGBB`. Drives `AppColors.seedColor` and both light/dark `ColorScheme` in `AppTheme`. |
| `font_family` | string | `''` (empty) | Font family name applied to every `TextStyle` in `AppTypography.textTheme`. Empty string = platform default. Example: `Roboto`, `Inter`. |

When `seed_color` is set, `AppColors` is generated with the hex value as `seedColor`, and `AppTheme` builds `ColorScheme.fromSeed(seedColor: AppColors.seedColor)` for both light and dark themes. When `font_family` is non-empty, `AppTypography` declares `static const String? fontFamily = '<value>'` and references it in all 15 Material 3 `TextTheme` styles.

### Resolution Precedence

When running commands, configuration options are merged and resolved in the following priority order:

1. **CLI Command-line Flags** (`--state-management=bloc`, etc.)
2. **Selected Preset** (`--preset=mobile`)
3. **Local Workspace Config** (`./rekeens.yaml`)
4. **Global User Config** (`~/.rekeens.yaml` / `%USERPROFILE%\rekeens.yaml`)
5. **Interactive Answers / Built-in Defaults**

### Initializing Configuration (`config init`)

Generate a default `rekeens.yaml` file in the current working directory:

```bash
rekeens config init
# Overwrite existing:
rekeens config init --force
```

---

## 7. Custom Template System

Rekeens supports custom template overrides. You can replace the default boilerplate templates with your own customized versions.

### Template Categories

| Category | Used by | Description |
|----------|---------|-------------|
| `base` | `rekeens create` | Project skeleton (directory structure, `home_page.dart`, theme files, READMEs) |
| `bootstrap` | `rekeens create` | Entry-point files rendered with selected options (`main.dart`, `app.dart`, `router.dart`, `app_cubit.dart`, `l10n.yaml`, `app_en.arb`) |
| `core` | `rekeens create` | Cross-cutting infrastructure rendered with selected options: `network_config.dart`, `api_exception.dart`, `dio_client.dart` / `http_client.dart` (when `--networking` is not `none`); `failure.dart`, `result.dart` (always); `exception_to_failure_mapper.dart` (when `--networking` is not `none`); `key_value_storage.dart` + `shared_preferences_storage.dart` / `secure_storage.dart` (when `--storage` is not `none`) |
| `features` | `rekeens generate *` | Feature-scoped generators (feature, screen, model, repository, service, provider, cubit) |
| `tests` | `rekeens generate *` | Test stub templates rendered alongside feature components (`feature`, `screen`, `model`, `repository`, `service`, `provider`, `cubit`) |

### Template Resolution Hierarchy

When scaffolding templates, Rekeens searches the following locations in order:

1. **Global User Templates**: `~/.rekeens/templates/<category>/<subPath>`
2. **Project Local Templates**: `./.rekeens/templates/<category>/<subPath>`
3. **Built-in Package Templates**

### Template Variables

Templates utilize double-curly-brace placeholders:
- `{{project_name}}` &mdash; Project identifier in snake_case.
- `{{feature_name}}` &mdash; Feature name in snake_case.
- `{{class_name}}` &mdash; PascalCase representation of the target entity.
- `{{model_name}}`, `{{provider_name}}`, `{{screen_name}}`, `{{service_name}}`, `{{repository_name}}`.

### Conditional Blocks (bootstrap templates)

Bootstrap templates support conditional sections that are included or excluded based on the options selected during `rekeens create`:

- `{{#if <condition>}}...{{/if}}` &mdash; rendered only when `<condition>` is true.
- `{{#unless <condition>}}...{{/unless}}` &mdash; rendered only when `<condition>` is false.

Available conditions:

| Condition | True when |
|-----------|-----------|
| `riverpod` | `state_management == 'riverpod'` |
| `bloc` | `state_management == 'bloc'` |
| `none` | `state_management == 'none'` |
| `go_router` | `router == 'go_router'` |
| `material3` | `theme == 'material3'` |
| `l10n` | `localization == true` |

Example (`main.dart`):

```dart
import 'package:flutter/material.dart';
{{#if riverpod}}import 'package:flutter_riverpod/flutter_riverpod.dart';
{{/if}}import 'app/app.dart';

void main() {
{{#if riverpod}}  runApp(const ProviderScope(child: App()));
{{/if}}{{#if none}}  runApp(const App());
{{/if}}}
```

---

## 8. Development & Contributing

### Running from Source

```bash
git clone https://github.com/igorsmoleac/rekeens_flutter_cli.git
cd rekeens_flutter_cli
dart pub get
dart run bin/rekeens_flutter_cli.dart doctor
```

### Testing & Code Quality

```bash
# Run unit and integration tests
dart test

# Format verification
dart format --output=none --set-exit-if-changed .

# Static analysis
dart analyze --fatal-infos
```

CI runs two workflows on every push and pull request to `main`/`dev`:

- **`dart.yml`** — unit tests, format verification, and static analysis of the CLI itself.
- **`e2e_smoke.yml`** — end-to-end smoke test that activates the CLI globally, scaffolds a project with `--preset=full` (all platforms, riverpod, go_router, dio, localization, codegen), then runs `flutter analyze` and `flutter test` inside the generated project. This guards the templates against silent degradation when dependencies or templates are updated.

---

Developed by **Igor Smoleac** for **Rekeens** &bull; Released under the [MIT License](LICENSE).
