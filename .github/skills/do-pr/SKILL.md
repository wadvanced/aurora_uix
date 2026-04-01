---
name: do-pr
description: Create a pull request with proper formatting and pre-merge checks
---

Create a pull request with proper conventional commit formatting and automation:
- Run consistency skill to ensure all checks pass before pushing
- Push commits to origin remote
- Create a GitHub PR with:
  - Title derived from branch name in conventional commit format
  - Auto-generated description:with summarizing all commits with key changes
  - Base branch set to main
- Display confirmation with PR URL

## Validation Checks
1. Ensure current branch is not main (safety check)
2. Ensure that chromedriver 'headless' config in test.exs is set to true
3. Verify all uncommitted changes are staged
4. Run precommit validation for code quality
5. Confirm git push succeeds
6. Generate and review PR details before creation

## Title Generation
The PR title is automatically derived from the branch name:
- Extract feature part after the username/first dash
- Identify conventional commit type (feat, fix, build, refactor, etc.) or default to feat
- Format as: `<type>: <description>`

Example: `federicoalcantara-adopt_spark_library` → `feat: adopt spark library`

## Description Generation
Auto-generated from recent commits with:
- Each commit shown with its message
- Key changes extracted from commit bodies
- Summary format for easy review

## Usage
Run this skill after:
1. Making all code changes
2. Committing with proper conventional commit messages
3. Running local tests and precommit checks

The skill handles the remaining workflow: final validation, push, and PR creation.
