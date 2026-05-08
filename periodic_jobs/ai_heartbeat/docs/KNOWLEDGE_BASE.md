# AI Heartbeat Knowledge Base (SOP)

## 0. 高层目标与设计哲学

- **终极意义**：从每天的工作变动中提纯有持久价值的"认知结晶"，对抗"上下文腐烂（Context Rot）"。
- **信息密度**：像资深架构师一样思考。如果一条信息在未来 3 个月内不会产生复用价值，果断丢弃。宁可少记，绝不凑数。

## 1. 核心执行准则

- **WORKSPACE_ROOT**: `/Users/wym/Desktop/code-work`（所有项目的根目录）
- **CONTEXT_INFRA**: `/Users/wym/Desktop/code-work/context-infrastructure`
- **文件持久化**: 最终交付物是修改文件，不只是回答问题。
- **自主加载**: 执行前先读 `AGENTS.md` 和 `rules/` 下的规范文件（L3 约束）。

## 2. 扫描规则 (L1 Observer)

### 2.1 扫描方法论

- **优先使用系统工具**：`find /Users/wym/Desktop/code-work -mtime -1 -type f` 扫描过去 24 小时的变动。
- **嵌套 Git 仓库**：workspace 下每个项目都是独立 git repo，可以在各子目录内使用 `git log --since="1 day ago"` 获取更精准的变动。
- **忽略噪音**：`.git/`、`node_modules/`、`vendor/`、`__pycache__/`、编译产物等无需处理。

### 2.2 路径过滤

- **重点关注**：各项目的源代码、配置文件、文档变动
- **忽略**：`contexts/daily_records/`（机械重复性数据）

## 3. 记忆分级规范

观测记录必须严格遵循交通灯打标逻辑：

- **🔴 High**：跨项目通用的经验和方法论、硬性约束、影响架构方向的重大决策
- **🟡 Medium**：活跃项目的关键技术进展、核心技术难点与权衡、架构局部变更
- **🟢 Low**：日常任务流水、瞬时 debug 记录、临时性上下文

## 4. 持久化规范

### 4.1 观测记录 (L1 Observer)

- **目标文件**: `/Users/wym/Desktop/code-work/context-infrastructure/contexts/memory/OBSERVATIONS.md`
- **操作**: Append-only，在文件末尾追加。
- **日期格式**: `Date: YYYY-MM-DD`（首字母大写，冒号后空格，ISO 日期）。
- **格式**: 每条记录单行，严格遵循 🔴🟡🟢 格式。

### 4.2 反思与晋升 (L2 Reflector)

- **规则层 (L3)**: 将有效规律更新到 `rules/` 下对应文件（`SOUL.md`、`USER.md`、`COMMUNICATION.md`、`WORKSPACE.md`、`skills/`）。
- **记忆层**: 重写 `OBSERVATIONS.md`，执行垃圾回收——删除已固化进 rules 的内容及过期的 🟢 记录。

## 5. 角色隔离

- **Observer (L1)** 只记录，不修改 `rules/` 目录。
- **Reflector (L2)** 才做规则晋升，两个阶段严格隔离。

## 6. 汇报

完成文件写入后，在 chat 中给出简短 summary：
- **Observer**: 扫描了哪些项目，过滤掉了多少噪音，写入了几条观测。
- **Reflector**: 哪些观测点晋升成了正式规则，删除了多少过期记录。
