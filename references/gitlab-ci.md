# GitLab CI Reference

## Pipeline Structure

```yaml
stages:
  - build
  - test
  - deploy

variables:
  KEY: value

job:
  stage: build
  script:
    - echo "Hello"
```

## Caching

```yaml
# Cache by lock file hash
cache:
  key:
    files:
      - package-lock.json
    paths:
      - node_modules/

# Global default
default:
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths:
      - node_modules/
```

## Artifacts

```yaml
build:
  artifacts:
    paths:
      - dist/
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    expire_in: 7 days
```

## Matrix Builds

```yaml
test:
  parallel:
    matrix:
      - NODE_VERSION: ["18", "20", "22"]
      - OS: [alpine, debian]
  image: node:${NODE_VERSION}-${OS}
```

## Rules

```yaml
job:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
    - when: never
```

## Workflow Rules

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_TAG
```

## Services (Docker-in-Docker)

```yaml
test:
  image: docker:24
  services:
    - docker:24-dind
  variables:
    DOCKER_HOST: tcp://docker:2376
  script:
    - docker build -t myapp .
```

## Environments

```yaml
deploy_staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - deploy-to-staging

deploy_production:
  stage: deploy
  environment:
    name: production
    url: https://example.com
  when: manual
  script:
    - deploy-to-production
```

## Coverage Regex

```yaml
test:
  script:
    - npm test
  coverage: '/Statements\s*:\s*(\d+\.?\d*)%/'
```

## Include (reusable configs)

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - local: '.gitlab/ci/build.yml'
  - project: 'my-group/my-project'
    file: '/templates/deploy.yml'
```
