# ci-pipeline

A Claude Code skill that generates optimized CI/CD pipeline configurations for GitHub Actions and GitLab CI.

English | [中文](README.zh-CN.md)

## What It Does

Automatically detects your project's tech stack and generates production-ready CI/CD configs with:

- **Auto-detection** of language, package manager, test framework, and linter
- **Multi-platform support** for GitHub Actions and GitLab CI
- **Best practices** baked in — caching, security, performance, reliability
- **Multiple workflows** — CI, deploy, release, PR checks
- **Validation** to catch config errors before they hit your pipeline

## Installation

```bash
# Copy to your Claude Code skills directory
cp -r ci-pipeline ~/.claude/skills/
```

Or for project-level installation:
```bash
cp -r ci-pipeline .claude/skills/
```

## Usage

In Claude Code:

```
/ci-pipeline                    # Auto-detect and generate CI workflow
/ci-pipeline github             # Generate GitHub Actions workflow
/ci-pipeline gitlab deploy      # Generate GitLab CI deploy pipeline
/ci-pipeline both ci deploy     # Generate both platforms, CI + deploy
```

## Supported Tech Stacks

| Language | Package Manager | Test Framework | Linter |
|----------|----------------|----------------|--------|
| Node.js | npm, yarn, pnpm | jest, vitest, mocha | eslint, prettier |
| Python | pip, poetry | pytest, unittest | ruff, flake8, mypy |
| Go | go modules | go test | golangci-lint |
| Rust | cargo | cargo test | clippy |

## Generated Files

Depending on arguments, creates:

```
.github/
└── workflows/
    ├── ci.yml          # Lint → Test → Build
    ├── deploy.yml      # Build → Push → Deploy
    └── release.yml     # Build → Changelog → Publish
```

or

```
.gitlab-ci.yml          # Complete pipeline config
```

## What's Included

```
ci-pipeline/
├── SKILL.md                    # Main skill definition
├── README.md                   # This file
├── LICENSE                     # MIT license
├── references/
│   ├── github-actions.md       # GitHub Actions patterns
│   ├── gitlab-ci.md            # GitLab CI patterns
│   └── best-practices.md       # CI/CD best practices
├── templates/
│   ├── github-actions/
│   │   ├── node-ci.yml         # Node.js CI template
│   │   ├── python-ci.yml       # Python CI template
│   │   ├── go-ci.yml           # Go CI template
│   │   └── deploy.yml          # Docker deploy template
│   └── gitlab-ci/
│       ├── node-ci.yml         # Node.js CI template
│       ├── python-ci.yml       # Python CI template
│       └── go-ci.yml           # Go CI template
├── scripts/
│   └── validate-config.sh      # Config validation script
└── evals/
    └── evals.json              # Test cases
```

## Best Practices Applied

- **Caching**: Automatic cache configuration for dependencies
- **Security**: Pinned action versions, minimal permissions, no hardcoded secrets
- **Performance**: Matrix builds, parallel jobs, concurrency control
- **Reliability**: Timeouts, cleanup steps, retry for network operations

## License

MIT
