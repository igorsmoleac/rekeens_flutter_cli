# Contributing to Rekeens Flutter CLI

Thanks for your interest in contributing! This document describes the branch
model, commit conventions, and the checks every change must pass before it can
be merged.

## Prerequisites

| Tool | Version | Notes |
| :--- | :--- | :--- |
| Dart SDK | >= 3.12 | required, see `pubspec.yaml` |
| git | any recent version | required |
| Flutter SDK | stable | only needed to run the E2E smoke test locally |

## Getting started

```bash
git clone https://github.com/igorsmoleac/rekeens_flutter_cli.git
cd rekeens_flutter_cli
dart pub get
```

## Branching model

| Branch | Purpose |
| :--- | :--- |
| `main` | Stable channel. Releases are tagged `vX.Y.Z`, which triggers the pub.dev publish workflow. |
| `dev` | Integration branch. All feature work lands here first. |
| `feature/<name>`, `fix/<name>`, `chore/<name>` | Short-lived topic branches, created from `dev`. |

```text
feature/<name> ──PR──> dev ──PR──> main ──tag v0.X.Y──> pub.dev
```

- Always branch off `dev` and open pull requests **against `dev`**, not `main`.
- `main` receives code only through PRs from `dev`.
- Keep branches focused: one feature or fix per branch and PR.

## Commit messages

- Use the imperative mood ("Add", "Fix", "Remove") — as if completing
  *"This commit will …"*.
- Capitalize the first letter; no trailing period.
- Keep the subject line under ~72 characters.
- One logical change per commit.

Examples from the project history:

```text
Add --add-field and --remove-field to model generator
Fix model parser to handle CRLF line endings on Windows
Remove accidental empty dart file
Add runnable example and bump version
```

Dependency bumps opened by Dependabot follow the Conventional Commits style
(`chore(deps): bump <package> from X to Y`) — that is fine; do not rewrite them.

## Local checks

Run all of these before every PR — CI runs the same set on both
ubuntu-latest and windows-latest:

```bash
dart pub get
dart format lib test bin
dart analyze --fatal-infos lib test bin
dart test
```

Notes:

- `templates/` is intentionally excluded from formatting and analysis:
  template files contain `{{placeholders}}` that are not valid Dart.
- CI (`.github/workflows/dart.yml`) additionally runs the test suite with
  coverage and uploads it to Codecov, on ubuntu-latest and windows-latest.
- The E2E smoke workflow (`.github/workflows/e2e_smoke.yml`) scaffolds a real
  Flutter project for every preset (`minimal`, `mobile`, `full`) and runs
  `flutter analyze` + `flutter test` inside each. If your change affects
  templates or the scaffolding pipeline, run `dart run example/main.dart`
  locally as a quick smoke test.

## Pull requests

1. Push your topic branch and open a PR **against `dev`**.
2. The PR must:
   - include tests covering the new behavior;
   - add an entry at the top of `CHANGELOG.md` (see below);
   - update `README.md` / `DOCUMENTATION.md` if user-facing behavior changed;
   - pass formatting, analysis, and tests on both CI operating systems.
3. Use a short, imperative PR title matching the commit style above.

## Versioning & changelog

- Follow semver: new features bump the minor version, fixes bump the patch
  version.
- Bump `version:` in `pubspec.yaml`.
- Add a `## X.Y.Z` section at the top of `CHANGELOG.md` describing what changed
  and why, with sub-bullets for new files, tests, and docs when applicable:

```markdown
## 0.27.0

- **Update existing models with `--add-field` / `--remove-field`** — ...
  - **New files**: `lib/utils/model_file_parser.dart`, ...
  - **Tests**: `generators_test.dart` (+11: ...)
```

## Project layout

```text
bin/                 CLI entrypoint
lib/commands/        Command definitions (generate, create, doctor, ...)
lib/config/          rekeens.yaml loading, hooks, presets
lib/generators/      One generator per component (model, screen, repository, ...)
lib/services/        Cross-cutting services (template rendering, scaffolding)
lib/utils/           Helpers (field parsing, logging, path resolution)
templates/           Mustache-style templates ({{placeholders}}) — not analyzed
test/                Unit tests mirroring lib/
example/             Runnable demo driving all generators
```

## Reporting issues

- Run `rekeens doctor` and attach its output.
- Include the exact command you ran, the expected vs. actual result, and your
  operating system.
