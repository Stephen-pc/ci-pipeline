# ci-pipeline

一个 Claude Code Skill，自动生成优化的 CI/CD 流水线配置，支持 GitHub Actions 和 GitLab CI。

[English](README.md) | 中文

## 功能

自动检测项目技术栈，生成生产级 CI/CD 配置：

- **自动检测** — 识别语言、包管理器、测试框架、代码检查工具
- **双平台支持** — GitHub Actions 和 GitLab CI
- **内置最佳实践** — 缓存、安全加固、性能优化、可靠性保障
- **多种工作流** — CI 测试、部署发布、PR 检查
- **配置验证** — 自动检查语法错误和安全问题

## 安装

```bash
# 复制到 Claude Code skills 目录
cp -r ci-pipeline ~/.claude/skills/
```

或项目级安装：
```bash
cp -r ci-pipeline .claude/skills/
```

## 使用

在 Claude Code 中输入：

```
/ci-pipeline                    # 自动检测技术栈，生成 CI 工作流
/ci-pipeline github             # 生成 GitHub Actions 配置
/ci-pipeline gitlab deploy      # 生成 GitLab CI 部署流水线
/ci-pipeline both ci deploy     # 同时生成两个平台的 CI + 部署
```

## 支持的技术栈

| 语言 | 包管理器 | 测试框架 | 代码检查 |
|------|----------|----------|----------|
| Node.js | npm, yarn, pnpm | jest, vitest, mocha | eslint, prettier |
| Python | pip, poetry | pytest, unittest | ruff, flake8, mypy |
| Go | go modules | go test | golangci-lint |
| Rust | cargo | cargo test | clippy |

## 生成的文件

根据参数生成对应配置：

**GitHub Actions：**
```
.github/
└── workflows/
    ├── ci.yml          # 检查 → 测试 → 构建
    ├── deploy.yml      # 构建 → 推送镜像 → 部署
    └── release.yml     # 构建 → 更新日志 → 发布
```

**GitLab CI：**
```
.gitlab-ci.yml          # 完整流水线配置
```

## 项目结构

```
ci-pipeline/
├── SKILL.md                    # Skill 主定义文件
├── README.md                   # 英文说明
├── README.zh-CN.md             # 中文说明（本文件）
├── LICENSE                     # MIT 许可证
├── references/
│   ├── github-actions.md       # GitHub Actions 模式参考
│   ├── gitlab-ci.md            # GitLab CI 模式参考
│   └── best-practices.md       # CI/CD 最佳实践
├── templates/
│   ├── github-actions/
│   │   ├── node-ci.yml         # Node.js CI 模板
│   │   ├── python-ci.yml       # Python CI 模板
│   │   ├── go-ci.yml           # Go CI 模板
│   │   └── deploy.yml          # Docker 部署模板
│   └── gitlab-ci/
│       ├── node-ci.yml         # Node.js CI 模板
│       ├── python-ci.yml       # Python CI 模板
│       └── go-ci.yml           # Go CI 模板
├── scripts/
│   └── validate-config.sh      # 配置验证脚本
└── evals/
    └── evals.json              # 测试用例
```

## 内置最佳实践

### 缓存优化
- Node.js：自动缓存 `node_modules` 或全局包管理器存储
- Python：缓存 `~/.cache/pip` 或 poetry 虚拟环境
- Go：缓存 `~/go/pkg/mod` 和构建缓存
- 基于锁文件哈希精准失效

### 安全加固
- GitHub Actions 使用 SHA 固定版本（避免供应链攻击）
- 最小权限原则配置 `permissions`
- 禁止硬编码密钥，使用 `${{ secrets.* }}` 或 CI/CD 变量
- 集成依赖扫描和 SAST 工具

### 性能优化
- 矩阵构建并行测试多版本
- 独立任务并行执行
- `concurrency` 控制取消冗余运行
- `fail-fast: true` 快速失败

### 可靠性保障
- 设置合理的 `timeout-minutes`
- `if: always()` 确保清理步骤执行
- 网络操作自动重试

## 配置验证

使用内置脚本验证生成的配置：

```bash
bash ~/.claude/skills/ci-pipeline/scripts/validate-config.sh .github/workflows/ci.yml
```

检查内容：
- YAML 语法正确性
- 必需字段完整性
- 安全最佳实践
- 常见错误检测

## 许可证

MIT
