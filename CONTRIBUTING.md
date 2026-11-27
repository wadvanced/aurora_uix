# Contributing to Aurora UIX

Thank you for considering contributing to Aurora UIX! We appreciate your help in making this project better.

## Table of Contents

1. [How to Contribute](#how-to-contribute)
2. [Development Setup](#development-setup)
3. [Code Style and Quality](#code-style-and-quality)
4. [Testing](#testing)
5. [Documentation](#documentation)
6. [Commit Conventions](#commit-conventions)
7. [Pull Request Process](#pull-request-process)
8. [Code of Conduct](#code-of-conduct)

---
## How to Contribute

### Reporting Bugs

Found a bug? Help us fix it!

1. **Check existing issues** — Search [GitHub Issues](https://github.com/wadvanced/aurora_uix/issues) to see if it's already reported
2. **Provide details** — Open a new issue with:
   - Clear title describing the problem
   - Step-by-step reproduction steps
   - Expected vs. actual behavior
   - Code sample or minimal test case
   - Your environment (Elixir version, OS, etc.)

### Suggesting Enhancements

Have an idea? Share it!

1. **Open a discussion** — Start a [GitHub Discussion](https://github.com/wadvanced/aurora_uix/discussions) to explore the idea
2. **Or create an issue** — With the `enhancement` label if you prefer
3. **Provide context** — Explain the use case and benefits

### Pull Requests

Ready to code? Here's the process:

1. **Fork the repository** and create a branch from `main`
2. **Set up development environment** (see [Development Setup](#development-setup))
3. **Make your changes** with focused commits
4. **Add tests** for new functionality
5. **Update documentation** if you changed the API
6. **Ensure code quality** — Run `mix consistency`
7. **Submit your PR** with a clear description

---
## Development Setup

### Prerequisites

Before contributing, ensure you have:

- **Elixir and Erlang** — The versions in `.tool-versions` (Elixir 1.19.4,
  Erlang 28.2); the package supports Elixir `~> 1.17`
- **PostgreSQL 13+**, with the `uuid-ossp` and `citext` extensions available (the migrations create
  them)
- **Chrome and ChromeDriver** — For the browser tests

### Databases

- **Tests** use a private PostgreSQL instance per checkout, which `scripts/test_pg.sh` creates and
  starts on its own; it needs the PostgreSQL server binaries (`initdb`, `pg_ctl`). To use a server
  you already run instead, set `AURORA_UIX_TEST_PG=shared`: it connects to `localhost` as user
  `postgres`, password `postgres`, database `aurora_uix_test`.
- **Development** connects to `localhost` with the same user, password and database
  (`dev/config/dev.exs`).

### Clone & Setup

```bash
# Clone repository
git clone https://github.com/wadvanced/aurora_uix.git
cd aurora_uix

# Install dependencies
mix deps.get

# Create the test database (first time only; mix test does not run migrations)
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate

# Create the development database (to run the development server)
mix ecto.create
mix ecto.migrate

# Build assets
mix assets.setup
mix assets.build
```

### Custom Configuration

To change the development or test settings, create `config/dev.exs` or `config/test.exs` with
**only** the keys you want to change. They are loaded after `dev/config/dev.exs` and
`test/config/test.exs`, and Git ignores them. Do not copy the whole test file there: it computes
paths from its own location.

```elixir
# config/test.exs
import Config

config :aurora_uix, Aurora.Uix.Repo, pool_size: 5
```

---
## Code Style and Quality

### Format Code

Ensure consistent formatting before committing:

```bash
mix format
```

### Run Quality Checks

Aurora UIX enforces code quality using:

```bash
# Run all checks at once
mix consistency
```

`mix consistency` runs these steps in order and stops at the first failure:

| Step | Does |
|---|---|
| `auix.gen.tailwind_classes` | Regenerates the icon class list |
| `format` | Formats the code |
| `spark.formatter` | Formats the Spark DSL declarations |
| `compile --warnings-as-errors` | Compiles with strict warnings |
| `credo --strict` | Lints with Credo |
| `dialyzer` | Static analysis |
| `doctor` | Documentation coverage |

**All checks must pass** before merging a pull request.

### Elixir Style Guide

We follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide). Key points:

- Use 2 spaces for indentation
- Keep lines under 98 characters
- Use descriptive variable names
- Write clear, concise comments only when needed
- Follow module naming conventions

---
## Testing

### Running Tests

```bash
# Run all tests (including Wallaby)
mix test

# Run only unit/integration tests (skip Wallaby)
mix test test/cases* test/doctests

# Run only browser base tests (Only Wallaby)
mix test test/browser*
```

> **Important**: CI runs all tests including Wallaby on every PR. We recommend setting up Wallaby locally.

### Wallaby Setup

Wallaby runs browser-based integration tests. Follow the [Wallaby setup guide](https://hexdocs.pm/wallaby/readme.html#setup).

### Interactive Testing

Start test servers to visually and manually validate your changes:

#### Phoenix server with guides routes
```bash
# Development server
mix phx.server

# Development server with iex
iex -S mix phx.server
```
<a id="server-under-test-environment"></a>

#### Server under test environment

All routes will be available
```bash
MIX_ENV=test iex --dot-iex "test/start_test_server.exs" -S mix
```

Test routes are configured in [`test/support/app_web/routes.ex`](test/support/app_web/routes.ex).

### Creating Sample Data

When testing locally, use helpers to create sample data:

Start the [test server](#server-under-test-environment), it will open an iex session.

```elixir
# In iex> with test server running:
Aurora.Uix.Test.Helper.create_guides_sample_data()
```

> **Keep in mind**: All data will be deleted and recreated persistently (not sandboxed).

See [`test/support/helper.ex`](test/support/helper.ex) for more helper functions.

### Testing Guidelines

- **Focus on new code** — Only test the functionality you added
- **Avoid redundant tests** — Don't test framework behavior
- **Use sandboxing** — Database transactions are automatically rolled back when using within test blocks
- **Clear test names** — Test names should describe what's being tested

---
## Documentation

### Guides & Examples

Help improve our [guides](guides/overview/overview.md)!

- `guides/tutorial/` — Building a first application
- `guides/overview/` and `guides/introduction/` — Overview and getting started
- `guides/core/` — Core concepts
- `guides/customization/` — Customization & extension (styling, theming, components, actions)
- `guides/advanced/` — Advanced usage and troubleshooting
- `guides/whats_new/` — Upgrade notes for each release

> The `doc/` directory is ExDoc build output generated by `mix docs` — never hand-edit it.

### Authoring Guidelines

- Use clear, concise language
- Include code examples
- Show expected output
- Highlight common pitfalls
- Link to related guides

### Screenshots

Some guides include screenshots. Recommended dimensions:

- **Desktop**: 1024px × 768px at 100% zoom
- **Mobile**: 412px × 915px (Google Pixel 7)

To capture screenshots:
- All at once

All the images are generated with proper data and format. This is the simplest way.
If you need to add or modify an image, do it in one of the `test/guides/capture_*.exs` files.

Run `mix assets.build` first, so the images show the current UI.

```bash
mix assets.build
mix test test/guides/capture_*.exs
```

The `prepare-release` skill (`.claude/skills/prepare-release/`) runs this as part of release preparation.

- Manually
Start the [test server](#server-under-test-environment)

```bash
# Open Firefox Desktop Size
/Applications/Firefox.app/Contents/MacOS/firefox \
  -width 1024 -height 768 -new-instance "http://localhost:4001/guides-overview/products"

# Open Firefox Mobile Size
/Applications/Firefox.app/Contents/MacOS/firefox \
  -width 412 -height 915 -new-instance "http://localhost:4001/guides-overview/products"

# Capture with Screenshot app or use browser extensions
```

We use [FireShot](http://getfireshot.com/) for some manual page captures.

---
## Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/) for clear, readable history.

### Format

```
type(scope): subject

body

footer
```

### Types

- `feat`: New feature for users
- `fix`: Bug fix for users
- `docs`: Documentation changes only
- `style`: Code style (formatting, whitespace)
- `refactor`: Code refactoring (no feature/fix)
- `test`: Adding or updating tests
- `chore`: Maintenance, dependencies, build tasks
- `build`: Build system changes
- `ci`: CI configuration changes
- `perf`: Performance improvements

### Scope (Optional)

Specify the affected area:
- `core`, `layouts`, `fields` — Major components
- `docs` — Documentation
- `test` — Testing infrastructure

### Subject

- Use imperative mood: "add" not "added" or "adds"
- Don't capitalize first letter
- No period at end

### Examples

**Good commits:**
```
feat: add support for custom field renderers
fix(layouts): correct section spacing on mobile
docs: update installation guide for Elixir 1.19
refactor(core): simplify resource metadata processing
test: add edge case coverage for associations
ci: add Dialyzer to consistency checks
```

**Bad commits:**
```
Added new feature                    # Missing type
fixed a bug                          # Wrong mood/capitalization
feat: stuff                          # Too vague
feat(auth): Add login endpoint.      # Capitalization and period
```

---
## Pull Request Process

### Before Submitting

- [ ] Code passes `mix consistency`
- [ ] Tests added for new functionality
- [ ] Documentation updated if needed
- [ ] Commits follow [Conventional Commits](#commit-conventions)
- [ ] Branch is up-to-date with `main`

### PR Description

Include:
- **What** — What does this PR do?
- **Why** — Why is this change needed?
- **How** — How does it work?
- **Related issues** — Links to issues (e.g., "Fixes #123")

### Review Process

- Maintainers will review your code
- We may request changes or ask questions
- Once approved, your PR will be merged
- Monitor [CHANGELOG.md](CHANGELOG.md) for release notes

---
## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](https://github.com/wadvanced/.github/blob/main/CODE_OF_CONDUCT.md).

By participating, you agree to uphold this code. Please report unacceptable behavior to [contact@wadvanced.com](mailto:contact@wadvanced.com).

---
## Questions?

- **GitHub Discussions** — [Ask questions](https://github.com/wadvanced/aurora_uix/discussions)
- **GitHub Issues** — [Report problems](https://github.com/wadvanced/aurora_uix/issues)
- **Email** — [contact@wadvanced.com](mailto:contact@wadvanced.com)

Thank you for contributing! 🚀
