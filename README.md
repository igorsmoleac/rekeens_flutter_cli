# Rekeens Flutter CLI

A Dart-based CLI for quickly creating Flutter projects with a consistent architecture, structure, and development setup.

The goal is simple: **stop rebuilding the same Flutter foundation for every project.**

Instead of manually creating folders, configuring dependencies, setting up architecture and repeating the same boilerplate, run:

```bash
rekeens create my_app
```

and start building the product.

---

## Features

* Create Flutter projects from predefined templates
* Feature-first architecture
* Consistent project structure
* Preconfigured application theme
* Code generators for common components
* Project environment diagnostics
* Template-based project generation
* Fast and repeatable project setup

---

## Installation

Install the CLI globally using Dart:

```bash
dart pub global activate rekeens_flutter_cli
```

Verify the installation:

```bash
rekeens --help
```

---

## Create a Project

Create a new Flutter project:

```bash
rekeens create my_app
```

The CLI will guide you through the project configuration using interactive prompts.

### Non-interactive mode

You can also provide configuration options directly:

```bash
rekeens create my_app \
  --platforms=android,ios,windows \
  --state-management=riverpod \
  --router=go_router \
  --networking=dio \
  --localization
```

If any of these flags are provided, the CLI will skip interactive questions and use the provided values, with defaults for missing options.

---

## Project Structure

Generated projects follow a feature-first architecture:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│       ├── app_colors.dart
│       ├── app_theme.dart
│       └── app_typography.dart
│
├── core/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── network/
│   ├── storage/
│   └── utils/
│
├── features/
│   └── home/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart
```

The structure is opinionated and designed to provide a consistent starting point for Flutter applications.

---

## Code Generators

Rekeens Flutter CLI can generate common application components.

### Feature

```bash
rekeens generate feature auth
```

Short form:

```bash
rekeens g feature auth
```

Generates:

```text
features/auth/
├── data/
├── domain/
└── presentation/
```

### Screen

```bash
rekeens generate screen login
```

### Model

```bash
rekeens generate model User
```

### Repository

```bash
rekeens generate repository User
```

### Service

```bash
rekeens generate service Auth
```

### Provider

```bash
rekeens generate provider Auth
```

---

## Doctor

Check the development environment:

```bash
rekeens doctor
```

The command checks the required development tools and environment.

Example:

```text
Rekeens Flutter CLI Doctor

✓ Flutter
✓ Dart
✓ Git

Environment is ready.
```

---

## Philosophy

Rekeens Flutter CLI is intentionally opinionated.

It is not intended to support every possible Flutter architecture or development style.

Instead, it provides a consistent starting point for projects following the Rekeens development workflow.

The idea:

```text
New idea
   ↓
rekeens create my_app
   ↓
Flutter foundation ready
   ↓
Build the product
```

The CLI handles repetitive project setup so development time can be spent on the actual product.

---

## How It Works

The CLI uses templates to build the project:

```text
rekeens create my_app
        │
        ▼
   Flutter project
        │
        ▼
     Templates
        │
        ▼
   Project structure
        │
        ▼
  Ready to develop
```

Templates are kept separate from the CLI logic, allowing the project foundation to evolve without rewriting the generator itself.

---

## Templates

Project templates are stored in:

```text
templates/
```

The template system is designed to make the generated project structure easy to modify and extend.

Future versions may support multiple presets, such as:

```text
minimal
mobile
full
```

---

## Roadmap

### Current

* [x] CLI foundation
* [x] Project creation
* [x] Interactive mode
* [x] Non-interactive mode (flags)
* [x] Template system
* [x] Feature generator
* [x] Screen generator
* [x] Model generator
* [x] Repository generator
* [x] Service generator
* [x] Provider generator
* [x] Doctor command
* [x] Basic dependency management
* [x] Dry-run mode
* [x] Unit tests for core logic
* [x] CI (GitHub Actions) for analyze and tests

### Planned

* [ ] Presets (minimal/mobile/full)
* [ ] Configuration file (`rekeens.yaml`)
* [ ] Dynamic dependency management based on options
* [ ] More generators
* [ ] Improved validation
* [ ] Automated tests for generated projects

---

## Author

Developed by **Igor Smoleac** for **Rekeens**.

GitHub: [github.com/igorsmoleac](https://github.com/igorsmoleac)
