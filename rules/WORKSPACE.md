# WORKSPACE.md - 目录路由速查

目标：让 AI 每轮 session 都能快速知道"去哪里找/放什么"。**找任何文件前先查这里。**

## 路由规则

### 项目与代码
- 一次性脚本 / 临时项目：`adhoc_jobs/<project>/`
- 工具脚本（通用）：`tools/`
- 定时任务：`periodic_jobs/`

### 知识与记录
- 调研报告：`contexts/survey_sessions/`
- 思考 / 复盘 / 方法论：`contexts/thought_review/`
- 每日日志：`contexts/daily_records/`
- 记忆积累：`contexts/memory/OBSERVATIONS.md`

### 系统与规则
- Skills（可复用工作流）：`rules/skills/`
- Axioms（决策公理）：`rules/axioms/`
- 身份与偏好：`rules/SOUL.md`、`rules/USER.md`、`rules/COMMUNICATION.md`
- 记忆系统实现：`periodic_jobs/ai_heartbeat/`

## 命名规则
- 目录和文件名：小写 + 连字符 (kebab-case) 或下划线 (snake_case) 均可
- 临时项目：`tmp_<name>/`

## 快速查询

<!-- 随着项目增长，在这里添加活跃项目的快捷路由 -->
<!-- 格式：- `project-name` → `adhoc_jobs/project_name/` (说明) -->
