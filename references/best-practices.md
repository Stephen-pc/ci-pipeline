# CI/CD Best Practices

## Caching

**Why:** Caches reduce build times by 50-80% for dependency-heavy projects.

**Rules:**
- Always cache package manager directories (node_modules, .npm, ~/.cache/pip, .go/pkg/mod)
- Use lock file hash as cache key for precise invalidation
- Set `restore-keys` for partial cache hits
- Don't cache build outputs (use artifacts instead)

## Security

### Pin Dependencies
- Pin GitHub Actions to full SHA, not tag (e.g., `@abc123` not `@v4`)
- Pin Docker images to digest (e.g., `node:20@sha256:...`)
- Use `permissions:` to limit token scope

### Secrets Management
- Never hardcode secrets in workflow files
- Use environment-level secrets for production
- Rotate secrets regularly
- Use OIDC for cloud provider auth instead of long-lived keys

### Dependency Scanning
- Enable Dependabot/Renovate for action version updates
- Run `npm audit` / `pip audit` / `go mod verify` in CI
- Use SAST tools (CodeQL, Semgrep, SonarQube)

## Performance

### Parallelism
- Run lint, test, build as separate jobs
- Use matrix builds for multi-version testing
- Set `fail-fast: true` to stop early on failure

### Concurrency
- Use `concurrency` groups to cancel redundant runs
- Don't cancel in-progress deploys (`cancel-in-progress: false`)

### Caching vs Artifacts
- **Cache**: dependencies, tools (survives across runs)
- **Artifacts**: build outputs, test reports (per-run, downloadable)

## Reliability

### Timeouts
```yaml
jobs:
  test:
    timeout-minutes: 15  # Prevent hung jobs
```

### Retries (network operations)
```yaml
- name: Install dependencies
  run: |
    for i in 1 2 3; do
      npm ci && break
      echo "Retry $i..."
      sleep 10
    done
```

### Cleanup
```yaml
- name: Cleanup
  if: always()
  run: |
    docker stop $(docker ps -q) || true
    rm -rf /tmp/build-*
```

## Notifications

### Slack
```yaml
- uses: slackapi/slack-github-action@v1
  if: failure()
  with:
    channel-id: 'ci-alerts'
    slack-message: 'Build failed: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}'
```

### GitHub Status Checks
- Use `actions/github-script` for custom status reporting
- Set commit status via GitHub API

## Environment Promotion

```
main → staging (auto)
tag v* → production (manual approval)
```

Use GitHub Environments with protection rules:
- Required reviewers for production
- Wait timer before deploy
- Branch restrictions

## Monorepo Strategies

### Path Filtering
```yaml
on:
  push:
    paths:
      - 'packages/api/**'
      - '!packages/api/**/*.md'
```

### Turborepo / Nx
```yaml
- run: npx turbo run test --filter=...[HEAD^1]
```

## Docker Best Practices

### Multi-stage Builds
```dockerfile
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

### Layer Caching in CI
```yaml
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```
