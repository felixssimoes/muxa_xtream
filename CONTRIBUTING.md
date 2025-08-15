# Contributing

Thanks for contributing! Please follow these non-negotiable rules:

- Analyzer must be 100% clean (no warnings, infos, or errors) before committing.
- Use Conventional Commits (type(scope): subject) with a wrapped, informative body.
- Update `example/main.dart` and docs when adding or changing public APIs.
- Always run `bash tool/verify.sh` locally before committing.

Helpful docs:
- Development guidelines: `AGENTS.md`
- Plan and tasks: `doc/DEVELOPMENT_PLAN.md`

## Pre-commit Hook (recommended)

Install a pre-commit hook to block commits if verify fails:

```bash
chmod +x tool/hooks/pre-commit
ln -sf ../../tool/hooks/pre-commit .git/hooks/pre-commit
```

## Strict Verify

`tool/verify.sh` fails fast on any formatting, analyzer, or test issue. Use it as your single entrypoint for local checks.
