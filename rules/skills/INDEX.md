# Skills Index

## Code Review

| Skill | 触发场景 | 文件 |
|-------|----------|------|
| go-review-swarm | 多 agent 并行做 Go code review | `go-review-swarm.md` / `go-review-swarm/` |
| linus-reviewer | Linus 风格严苛 code review | `linus-review.md` / `linus-reviewer/` |
| multi-agent-reviewer | 多 agent 协作 review | `multi-agent-reviewer/` |
| review-pr | 通用 PR review（当前分支 vs master） | `review-pr.md` |

## Speckit 开发工作流

完整的 spec → plan → implement 流水线，按顺序使用：

| Skill | 作用 |
|-------|------|
| `speckit.constitution.md` | 创建/更新项目 constitution（原则和模板） |
| `speckit.specify.md` | 从自然语言描述生成 feature spec |
| `speckit.clarify.md` | 对 spec 提问澄清，补充细节 |
| `speckit.plan.md` | 生成技术实现 plan |
| `speckit.tasks.md` | 生成有依赖顺序的 tasks.md |
| `speckit.implement.md` | 执行 tasks.md 中的任务 |
| `speckit.analyze.md` | 跨 artifact 一致性分析（spec/plan/tasks） |
| `speckit.checklist.md` | 为当前 feature 生成 checklist |
| `speckit.taskstoissues.md` | 将 tasks 转为 GitHub issues |

## Git / PR

| Skill | 触发场景 | 文件 |
|-------|----------|------|
| pr-description | 生成结构化 PR 描述 | `pr-description.md` |
| update-branch | 用 master merge 更新目标分支 | `update-branch.md` |
| bench_result | benchmark 对比（当前改动 vs master） | `bench_result.md` |

## 运维 / 监控

| Skill | 触发场景 | 文件 |
|-------|----------|------|
| orphan-check | 查 orphan block 状态和 orphan rate | `orphan-check.md` / `orphan-check/` |
| loki-logcli | Loki 日志查询 | `loki-logcli/` |
| deploy-pr-to-staging | 部署 PR 到 staging 环境 | `deploy-pr-to-staging/` |
