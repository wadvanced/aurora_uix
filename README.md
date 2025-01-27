# aurora-uix
Low code UI for the elixir's Phoenix Framework.

## Contributing
PR are welcomed, we encourage code quality, so PR must pass the mix consistency task. It do:
* Re-formats code with mix `format`.
* Compiles with `--warnings-as-errors`.
* Applies strict credo analysis using mix `credo` --strict.
* Runs dialyzer with mix `dialyzer`.
* Verify documentation healthness with mix `doctor`.

The formatter credo and doctor have configuration files have been authored according to this project code quality checks. However rules changes can be accepted.