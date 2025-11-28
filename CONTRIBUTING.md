# Contributing to Aurora UIX

Thank you for considering contributing to Aurora UIX!

## How Can I Contribute?

### Reporting Bugs

- **Ensure the bug was not already reported** by searching on GitHub under [Issues](https://github.com/wadvanced/aurora_uix/issues).
- If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/wadvanced/aurora_uix/issues/new). Be sure to include a **title and clear description**, as much relevant information as possible, and a **code sample** or an **executable test case** demonstrating the expected behavior that is not occurring.

### Suggesting Enhancements

- Open a new issue to discuss your enhancement. Please provide a clear description of the enhancement and its potential benefits.

### Pull Requests

1. **Fork the repository** and create your branch from `main`.
2. **Set up the development environment** as described below.
3. **Make your changes** and ensure that the test suite passes.
4. **Add tests** for any new functionality.
5. **Update the documentation** if you've changed the API.
6. **Ensure your code lints** by running `mix consistency`.
7. **Issue that pull request!**

### Development Setup

- **Elixir** (check with `elixir --version`)
- **PostgreSQL** (default: localhost:5432, user: postgres, db: aurora_uix_test)
- **UUID Extension** in PostgreSQL:
  ```sql
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  ```

1. Clone the repo:
   ```shell
   git clone https://github.com/wadvanced/aurora_uix.git
   cd aurora-uix
   ```
2. Install dependencies:
   ```shell
   mix deps.get
   ```
3. Install and build assets:
   ```shell
   mix uix.test.assets.install
   mix uix.test.assets.build
   ```
4. Create and migrate the test database:
   ```shell
   mix uix.test.task ecto.create
   mix uix.test.task ecto.migrate
   ```
5. **(Optional) Custom Test Config**  
   - Copy `test/config/test.exs` to `config/test.exs` in your project root:
     ```shell
     cp test/config/test.exs config/test.exs
     ```
   - Edit `config/test.exs` as needed for your local environment.  
   - This file is not under version control.

## Style Guides

### Git Commit Messages

We adhere to the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. This leads to a more readable commit history and allows for automated changelog generation.

The commit message should be structured as follows:
```
type(scope): subject

body

footer
```

**Types**

The `type` must be one of the following:

- `feat`: A new feature for the user.
- `fix`: A bug fix for the user.
- `docs`: Changes to documentation only.
- `style`: Code style changes (e.g., formatting, white-space).
- `refactor`: A code change that neither fixes a bug nor adds a feature.
- `test`: Adding missing tests or correcting existing tests.
- `chore`: Routine tasks, maintenance, or changes to the build process.
- `build`: Changes that affect the build system or external dependencies (e.g., `mix.exs`).
- `ci`: Changes to our CI configuration files and scripts.

**Scope**

The `scope` provides context for the commit. It's an optional part of the message that can be used to specify the area of the codebase affected by the change. In Elixir projects, common scopes include:

- **Contexts**: `accounts`, `billing`, `posts`
- **Features**: `auth`, `search`, `notifications`
- **Umbrella Apps**: `my_app_web`, `my_app_data`

**Note on Scopes**: In single-context projects, the scope is often omitted. It is most useful in larger applications with clearly separated domains or in umbrella projects where changes might be specific to one of the child apps.

**Subject**

The subject contains a succinct description of the change:

- Use the imperative, present tense: "add" not "added" nor "adds".
- Don't capitalize the first letter.
- No dot (.) at the end.

**Examples**

Here are some examples of good and bad commit messages:

**Good Commit Messages**
```
feat: add user profile page
fix(auth): correct password reset token validation
docs: update installation guide
refactor(billing): simplify subscription model
chore: update dependencies
ci: add credo to the build pipeline
```

**Bad Commit Messages**
```
# BAD: No type
Added a new feature

# BAD: Imperative mood not used
fixed a bug

# BAD: Subject is too vague
fix: stuff

# BAD: Capitalization and period
feat(auth): Add login endpoint.

# BAD: Wrong type
feat: fix typo in the documentation
```

### Elixir Style Guide

We follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide) and enforce code quality using the following tools:

- **`mix format`**: Ensures a consistent code format. Please run this before committing your changes.
  ```bash
  mix format
  ```
- **`mix credo`**: A static code analysis tool to ensure code consistency and quality. It checks for code smells, best practices, and potential issues.
  ```bash
  mix credo --strict
  ```
- **`mix dialyzer`**: A static analysis tool that identifies type specification discrepancies. It helps in finding subtle bugs that the compiler might not catch.
  ```bash
  mix dialyzer
  ```
- **`mix doctor`**: A tool that checks for documentation coverage and other common issues.
  ```bash
  mix doctor
  ```

Please ensure that your changes pass all these checks before submitting a pull request.

**Note:** The Elixir projects include a `mix consistency` alias that runs all of these styling tools at once.

## Testing

Aurora UIX includes several views for interacting with. There are the ones provided by the phoenix server,
and there are the ones created when starting the server under the test environment.

Testing involve making sure that every intended behaviour is met, but also that elements are rendered according
to design. Visual validation can be done either using any of the environments.

### Starting the Phoenix Server
```bash
# Normal start
mix phx.server

# With iex
iex -S mix phx.server

```

See [router](https://github.com/wadvanced/aurora_uix/blob/main/lib/aurora_uix_web/routes.ex) for available routes under `dev` environment.


### Starting the Phoenix Server in the TEST environment

There are a lot of user interface tested, all of them can be visually validate using a browser. 

```bash
MIX_ENV=test iex --dot-iex "test/start_test_server.exs" -S mix
```

Test routes includes the routes in the `dev` environment.

All the available routes for the test environment can be found (and updated) in the [test/support/app_web/routes.ex](https://github.com/wadvanced/aurora_uix/blob/main/test/support/app_web/routes.ex)

> [!NOTE]
> Be careful when updating existing test routes, some tests might fail.

### Testing environment
Testing coverage is extensive, and any new functionality should appropriately covered. 
Focus on testing **ONLY** the new parts, and don't bloat the tests with unnecessary or redundant cases.

By default, test configuration is defined in file [/test/config/test.exs](https://github.com/wadvanced/aurora_uix/blob/main/test/config/test.exs).
You can partially or completely override these settings by creating a `/config/test.exs` file. 
This file, and `/config/dev.exs` are not under version control, feel free to do as you need with them.

* Most tests write and/or read from database, sandboxing all of the transactions (meaning that no changes are retained in the db).
* Some tests use [wallaby](https://hexdocs.pm/wallaby/Wallaby.html) follow its [setup](https://hexdocs.pm/wallaby/readme.html#setup) instructions to allow all tests to be locally run.

### Running the tests

* You need the database and tables to be created. Run the following commands the first time or after a git pull:
    
```bash
mix ecto.create 
mix ecto.migrate
```
* To run all the tests:

```bash
mix test
```

* To run all the tests, excluding those requiring wallaby:

```bash
mix test test/cases*

```
> [!IMPORTANT]
> Even though you can skip running the wallaby dependant tests, 
> the CI action will run them anyway on every pull request lifecycle (creation, update, merge).
> Therefore, it is recommended that you enable wallaby / browser.


### Creating sample data

You might need data, either to test or validate your code. 
There is a helper module with some bits that can assist in the manipulation of the data.

If you enter the iex as explained in the section [`Starting the Phoenix Server in the TEST environment`](#starting-the-phoenix-server-in-the-test-environment)

```bash
## Create 100 sample products with 3 transactions each
Aurora.Uix.Test.Helper.create_sample_products_with_transactions(100, 3, :use_any_prefix)

## Create 1 sample user with a couple of email
Aurora.Uix.Test.Helper.create_sample_users(1, %{emails: [%{email: "one@test.com", name: "work"}, %{email: "home@yahoo.com", name: "home"}]})

## Delete all sample data (inventory and accounts) 
Aurora.Uix.Test.Helper.delete_all_sample_data()

```

Browse the module [`Aurora.Uix.Test.Helper`](https://github.com/wadvanced/aurora_uix/blob/main/test/support/helper.ex) 
for learning about the functions that can be used to handle the sample data.


## Documentating and Authoring GUIDES

This kind of library requires extensive documentation and examples. Several of the current documentation were authored with the assistance of AI.
Since the documentation is bound to be constantly improved, feel free to modify and enhance its contents.

For authoring the examples, you can start the Phoenix Server under any of the environments according to your documentation needs.


### Screenshots

Some examples require screenshots to demonstrate its output. 
Screenshots can be any size, but for full page desktop media size, we recommend 1024px x 768px browser setting at 100%.
For mobile visible screenshots, 412px x 915px (Google Pixel 7 mobile).

Any browser will do, however we found that firefox was the easiest to open with a predefined size.
After launching Phoenix Server, you can try in a Mac:

```bash
# For desktop
/Applications/Firefox.app/Contents/MacOS/firefox -width 1024 -height 768 -new-instance "http://localhost:4001/guide-overview-products"

# For mobile
/Applications/Firefox.app/Contents/MacOS/firefox -width 412 -height 915 -new-instance "http://localhost:4001/guide-overview-products"

```

You can capture the image with the tool of your preference, in the MacOS there is the included `Screenshot` application.

The included screenshots were captured using the Firefox add-ons [`Awesome Screenshot & Screen Recorder`](https://addons.mozilla.org/en-US/firefox/addon/screenshot-capture-annotate/?utm_source=addons.mozilla.org&utm_medium=referral&utm_content=search).


## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](https://github.com/wadvanced/.github/blob/main/CODE_OF_CONDUCT.md). 
By participating, you are expected to uphold this code. Please report unacceptable behavior to contact@wadvanced.com.
