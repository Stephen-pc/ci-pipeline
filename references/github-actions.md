# GitHub Actions Reference

## Essential Actions

| Action | Purpose | Pin |
|--------|---------|-----|
| `actions/checkout` | Clone repo | `@b4ffde65f46336ab88eb53be808477a3936bae11` |
| `actions/setup-node` | Install Node.js | `@60edb5dd545a775178f52524783378180af0d1f8` |
| `actions/setup-python` | Install Python | `@0a5c61591de30ef6bfbf4a79cf0b6a2d5b4b4d7a` |
| `actions/setup-go` | Install Go | `@0c52d547c9bc32b1c3d6f5b0bfc4d5c4f8b26b3a` |
| `actions/upload-artifact` | Store build outputs | `@5d5d22a31266ced268874388b861e4b58bb5c2f3` |
| `actions/cache` | Custom caching | `@68e4b5b2b0db1906b8fc87ab699be8a5c2b0a7e9` |
| `docker/build-push-action` | Build & push images | `@0565240e2d4ab85b6c1a0b3b1c2b3b4b5b6b7b8a` |
| `docker/login-action` | Registry login | `@343f7c4344506bcbf9b4de18042ae17996df046d` |

## Workflow Triggers

```yaml
on:
  push:
    branches: [main, develop]
    tags: ['v*']
    paths: ['src/**', '!src/**/*.test.*']  # path filtering
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * 1'  # Weekly Monday 2am
  workflow_dispatch:       # Manual trigger
```

## Caching Patterns

### Node.js (auto with setup-node)
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'  # auto-detects lock file
```

### Custom cache
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/pip
      ~/.cache/pre-commit
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-
```

## Matrix Builds

```yaml
strategy:
  fail-fast: true
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    node: [18, 20, 22]
    exclude:
      - os: windows-latest
        node: 18
    include:
      - os: ubuntu-latest
        node: 22
        experimental: true
  max-parallel: 6
```

## Environment & Secrets

```yaml
jobs:
  deploy:
    environment: production
    steps:
      - run: echo "Deploying to ${{ vars.DEPLOY_URL }}"
      - run: echo "Using key ${{ secrets.API_KEY }}"
```

## Reusable Workflows

```yaml
# .github/workflows/reusable-test.yml
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '20'
    secrets:
      api-key:
        required: true

# Caller workflow
jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '22'
    secrets:
      api-key: ${{ secrets.API_KEY }}
```

## Concurrency Control

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # Cancel old runs on same branch
```

## Permissions (least privilege)

```yaml
permissions:
  contents: read
  packages: write
  issues: write
  pull-requests: write
```
