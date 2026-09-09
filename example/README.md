# Example

A runnable demonstration of the `rekeens_flutter_cli` generator API.

## Files

| File | Description |
| :--- | :--- |
| `main.dart` | Executable example: scaffolds a minimal demo project in a temporary directory and runs **all nine generators** through the same public API the CLI uses. |
| `rekeens.yaml.example` | Reference `rekeens.yaml` configuration (team defaults, hooks, custom `analysis_options.yaml`). |

## Running

From the package root:

```sh
dart run example/main.dart
```

Or, after activating the CLI globally, drive the same flow from the command
line inside any Flutter project:

```sh
rekeens g feature auth
rekeens g model auth user id:string name:string email:string? age:int \
  createdAt:datetime role:enum Role metadata:Map<String, dynamic>
rekeens g entity auth user
rekeens g usecase auth login
rekeens g repository auth user
rekeens g datasource auth user_api --base-url=https://api.demo.dev
rekeens g service auth auth_api
rekeens g provider auth session
rekeens g screen auth login
```

## What the example produces

The example creates a throwaway project (named `demo_app`) in the system
temp directory, generates an `auth` feature with a full set of components,
prints the resulting tree, and prints the contents of the generated typed
model. The directory is intentionally left on disk for inspection.

```text
rekeens_demo_<id>/
├── lib
│   ├── app
│   │   └── router.dart              # routes "/auth" and "/auth/login" added
│   └── features
│       └── auth
│           ├── data
│           │   ├── datasources
│           │   │   ├── user_api_datasource.dart
│           │   │   └── user_api_datasource_impl.dart
│           │   ├── models
│           │   │   └── user_model.dart
│           │   ├── repositories
│           │   │   └── user_repository_impl.dart
│           │   └── services
│           │       └── auth_api_service.dart
│           ├── domain
│           │   ├── entities
│           │   │   └── user_entity.dart
│           │   ├── repositories
│           │   │   └── user_repository.dart
│           │   └── usecases
│           │       └── login_usecase.dart
│           └── presentation
│               ├── pages
│               │   ├── auth_page.dart
│               │   └── login_screen.dart
│               ├── providers
│               │   ├── session_provider.dart
│               │   └── session_state.dart
│               └── widgets
└── test
    └── features
        └── auth
            ├── data
            │   ├── datasources
            │   │   └── user_api_datasource_test.dart
            │   ├── models
            │   │   └── user_model_test.dart
            │   ├── repositories
            │   │   └── user_repository_test.dart
            │   └── services
            │       └── auth_api_service_test.dart
            ├── domain
            │   ├── entities
            │   │   └── user_entity_test.dart
            │   └── usecases
            │       └── login_usecase_test.dart
            └── presentation
                ├── pages
                │   ├── auth_page_test.dart
                │   └── login_screen_test.dart
                └── providers
                    └── session_provider_test.dart
```

> The tree above reflects the generator output as of **0.26.x** (including
> the `datasource` generator introduced in 0.26.0 and the parameterized
> `base_url` from 0.26.1).

## Notes

- The example targets the **Riverpod** state management (explicitly passed
  to `ProviderGenerator`); in a real project the generator auto-detects
  Riverpod vs. BLoC from `pubspec.yaml`.
- Generated files are plain templates — they are not meant to compile
  inside this repository (they import `flutter_riverpod`, `go_router`,
  etc.). Run them through `rekeens create` / `rekeens g` inside a real
  Flutter project to get an analyzable codebase.
