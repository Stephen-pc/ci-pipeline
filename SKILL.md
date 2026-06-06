---
name: ci-pipeline
description: >
  Generate optimized CI/CD pipeline configurations for GitHub Actions or GitLab CI.
  Use when: setting up CI/CD, adding automated tests/lint/build/deploy workflows,
  creating GitHub Actions workflows, configuring GitLab CI pipelines, optimizing
  existing CI configs, or when a project has no CI/CD setup. Detects project tech
  stack automatically and applies best practices for caching, security, and performance.
version: 1.0.0
license: MIT
---

# CI/CD Pipeline Generator

Generate production-ready CI/CD configurations tailored to your project.

## Project Detection

Scan the project to identify the tech stack before generating configs:

- **Node.js**: `package.json` → check for npm/yarn/pnpm (lock files), framework (Next.js, React, Vue, etc.)
- **Python**: `requirements.txt`, `pyproject.toml`, `Pipfile` → check for Django, Flask, FastAPI
- **Go**: `go.mod` → check module name and dependencies
- **Rust**: `Cargo.toml`
- **Docker**: `Dockerfile`, `docker-compose.yml`
- **Monorepo**: Multiple package.json or workspace configs

## Dynamic Context

```markdown
## Detected Project State
- Package manager: !`ls package-lock.json yarn.lock pnpm-lock.yaml 2>/dev/null | head -1 || echo "none"`
- Python deps: !`ls requirements.txt pyproject.toml Pipfile 2>/dev/null | head -1 || echo "none"`
- Go module: !`head -1 go.mod 2>/dev/null || echo "none"`
- Has Dockerfile: !`test -f Dockerfile && echo "yes" || echo "no"`
- Has tests: !`ls -d __tests__ tests test spec 2>/dev/null | head -1 || echo "none"`
- Node version: !`node -v 2>/dev/null || echo "not installed"`
- Git branch: !`git branch --show-current 2>/dev/null || echo "unknown"`
```

## Workflow

### 1. Detect Stack

Read the dynamic context above. Identify:
- Primary language and version
- Package manager
- Test framework (infer from scripts in package.json, or common patterns)
- Linter/formatter (eslint, prettier, ruff, golangci-lint, etc.)
- Whether Docker is used

### 2. Determine Platform

Ask the user or infer from `.github/` or `.gitlab-ci.yml` presence:
- **GitHub Actions** → generate `.github/workflows/ci.yml`
- **GitLab CI** → generate `.gitlab-ci.yml`
- **Both** → generate both if requested

### 3. Select Workflows

Based on `$ARGUMENTS` or project needs, include:

| Workflow | Triggers | What it does |
|----------|----------|--------------|
| **ci** | push, PR | lint → test → build (default) |
| **deploy** | push to main/tag | build → push image → deploy |
| **release** | tag push | build → changelog → publish |
| **pr-check** | PR opened/updated | lint → test → size check |

### 4. Generate Config

Apply these best practices automatically:

**Caching:**
- Node: Cache `node_modules` or global store based on lock file hash
- Python: Cache `~/.cache/pip` or poetry virtualenv
- Go: Cache `~/go/pkg/mod` and build cache
- Use `actions/cache@v4` or GitLab cache directives

**Security:**
- Pin action versions to SHA (e.g., `actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11`)
- Use `permissions:` to limit GITHUB_TOKEN scope
- Add `CODEOWNERS` review for workflow changes
- Never hardcode secrets; use `${{ secrets.* }}` or CI/CD variables

**Performance:**
- Use matrix builds for multi-version testing
- Run independent jobs in parallel
- Use `concurrency` to cancel redundant runs
- Fail fast with `fail-fast: true` in matrix

**Reliability:**
- Set reasonable `timeout-minutes`
- Use `if: always()` for cleanup steps
- Add retry for flaky network operations

### 5. Validate

Run the validation script on generated configs:
```bash
bash scripts/validate-config.sh <generated-file>
```

### 6. Output

Write the generated file(s) to the correct location and report:
- Files created
- What each workflow does
- Any manual steps needed (secrets to configure, environments to set up)

## Template Reference

Use templates in `templates/` as starting points. Customize based on detected stack:
- `templates/github-actions/node-ci.yml` — Node.js CI
- `templates/github-actions/python-ci.yml` — Python CI
- `templates/github-actions/go-ci.yml` — Go CI
- `templates/github-actions/deploy.yml` — Docker deploy
- `templates/gitlab-ci/node-ci.yml` — Node.js CI for GitLab
- `templates/gitlab-ci/python-ci.yml` — Python CI for GitLab
- `templates/gitlab-ci/go-ci.yml` — Go CI for GitLab

## Arguments

`$ARGUMENTS` can specify:
- Platform: `github`, `gitlab`, `both`
- Workflows: `ci`, `deploy`, `release`, `pr-check`
- Example: `/ci-pipeline github deploy` → generate GitHub Actions deploy workflow

If no arguments, detect platform from repo and generate the default `ci` workflow.

## References

For detailed patterns, see:
- [GitHub Actions patterns](references/github-actions.md)
- [GitLab CI patterns](references/gitlab-ci.md)
- [Best practices](references/best-practices.md)
