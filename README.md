# Rekeens Flutter CLI

<p align="center">
  <strong>Production-ready Flutter scaffolding and code generation tool.</strong><br>
  Built on Feature-First Clean Architecture, pre-configured state management, and modular generators.
</p>

<p align="center">
  <a href="https://pub.dev/packages/rekeens_flutter_cli"><img src="https://img.shields.io/pub/v/rekeens_flutter_cli.svg" alt="coming soon"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.13+-blue.svg" alt="Dart SDK Version"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B.svg" alt="Flutter"></a>
  <a href="https://github.com/igorsmoleac/rekeens_flutter_cli/actions"><img src="https://img.shields.io/github/actions/workflow/status/igorsmoleac/rekeens_flutter_cli/dart.yml?branch=main" alt="CI Status"></a>
  <a href="https://github.com/igorsmoleac/rekeens_flutter_cli/actions"><img src="https://img.shields.io/github/actions/workflow/status/igorsmoleac/rekeens_flutter_cli/e2e_smoke.yml?branch=main" alt="E2E Smoke"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License"></a>
</p>

---

## Highlights

- **Instant Scaffolding** &mdash; Creates a runnable Flutter app with routing, theme, state management, and networking pre-wired.
- **Feature-First Architecture** &mdash; Enforces domain boundaries (`data`, `domain`, `presentation`) per business feature.
- **Code Generators** &mdash; Scaffolds features, screens, repositories, services, providers, and typed models (`fromJson`/`toJson`).
- **Presets and Configs** &mdash; Predefined profiles (`minimal`, `mobile`, `full`) and team-wide defaults via `rekeens.yaml`.
- **Environment Diagnostics** &mdash; Built-in `doctor` command to inspect your local Flutter/Dart toolchain.

For complete specifications and template override guides, see the [Technical Documentation](DOCUMENTATION.md).

---

## Installation

Activate globally via Dart:

```bash
dart pub global activate rekeens_flutter_cli
```

Verify the installation and check system prerequisites:

```bash
rekeens doctor
```

*(Ensure your global pub cache bin directory is in your system `PATH`)*

---

## Quick Start

### 1. Create a Project

```bash
# Interactive wizard
rekeens create my_app

# Or use a preset
rekeens create my_app --preset=mobile

# Or use CLI flags
rekeens create my_app --state-management=riverpod --router=go_router --networking=dio --localization
```

#### Presets

| Preset | Platforms | State | Router | Network | Localization | Codegen |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`minimal`** | `android, ios` | None | None | None | No | No |
| **`mobile`** | `android, ios` | Riverpod | GoRouter | Dio | Yes | No |
| **`full`** | `android, ios, windows, linux, macos, web` | Riverpod | GoRouter | Dio | Yes | Yes (`freezed`, `json_serializable`) |

---

### 2. Generate Components

Inside your project directory, scaffold modular code using `rekeens generate` (or `rekeens g`):

```bash
# Generate a complete feature structure
rekeens g feature auth

# Generate a typed model with JSON serialization
rekeens g model auth user id:string name:string email:string? age:int createdAt:datetime

# Generate screen, repository, service, and state provider
rekeens g screen auth login
rekeens g repository auth user
rekeens g service auth api
rekeens g provider auth session
```

*The provider generator automatically detects whether your project uses **Riverpod** (generates Provider) or **BLoC** (generates Cubit + State).*

---

## Architecture

Generated projects follow a modular **Feature-First Clean Architecture**:

```text
lib/
├── app/                  # Application bootstrap, routing and theme
├── core/                 # Shared network client, storage, error models, utils
├── features/             # Business modules
│   └── <feature_name>/
│       ├── data/         # Models (with JSON mapping), datasources, repositories
│       ├── domain/       # Entities, repository interfaces, use cases
│       └── presentation/ # UI pages, state providers (Riverpod/Bloc), widgets
├── shared/               # Reusable presentation widgets and design tokens
├── l10n/                 # Localization catalogs (.arb files)
└── main.dart             # Application entrypoint
```

---

## Command Reference

| Command | Description | Example |
| :--- | :--- | :--- |
| `rekeens doctor` | Inspects local development toolchain | `rekeens doctor` |
| `rekeens create <name>` | Scaffolds a new Flutter application | `rekeens create my_app --preset=mobile` |
| `rekeens list` | Lists all available presets and generators | `rekeens list` |
| `rekeens g feature <name>` | Scaffolds feature layers (`data`, `domain`, `presentation`) | `rekeens g feature profile` |
| `rekeens g screen <feature> <name>` | Creates a screen widget inside a feature | `rekeens g screen profile settings` |
| `rekeens g model <feature> <name> [fields]` | Creates a typed model with `fromJson` and `toJson` | `rekeens g model profile user name:string age:int` |
| `rekeens g repository <feature> <name>` | Creates a repository inside a feature | `rekeens g repository profile user` |
| `rekeens g service <feature> <name>` | Creates an API service inside a feature | `rekeens g service profile user_api` |
| `rekeens g provider <feature> <name>` | Creates a Riverpod provider or BLoC Cubit | `rekeens g provider profile profile_state` |
| `rekeens config init` | Generates a `rekeens.yaml` default configuration file | `rekeens config init` |

*Pass `-f, --force` to overwrite existing files, or `-n, --dry-run` to preview actions without writing to disk.*

---

## Configuration (`rekeens.yaml`)

Define shared team defaults in `rekeens.yaml`:

```yaml
defaults:
  platforms: [android, ios, windows]
  architecture: feature-first
  state_management: riverpod
  router: go_router
  networking: dio
  localization: true
  theme: material3
  codegen: false
```

---

## Documentation

For full guides on:
- Architecture layer responsibilities and data flow
- Advanced CLI flags and CI/CD integration
- Model generator field types and nullability rules
- Overriding templates via `~/.rekeens/templates/` or `./.rekeens/templates/`
- Local development and testing

See the [Technical Documentation (DOCUMENTATION.md)](DOCUMENTATION.md).

---

## License & Author

Developed by **Igor Smoleac** for **Rekeens**.  
Released under the [MIT License](LICENSE).
