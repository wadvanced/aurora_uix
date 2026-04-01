---
name: consistency
description: To ensure proper lints and documentation rules
---

Run the complete precommit workflow to ensure code quality:
- Execute `mix consistency` alias to run all checks and fix pending issues
- Address any linting, formatting, or test failures
- Ensure all code meets project standards
- If NO errors or warnings, prepare and perform several commits separating the stages according to 'conventional commits'.


