# Memory Observations

这是三层记忆系统的 L1/L2 层。每日观察由 `periodic_jobs/ai_heartbeat/src/v0/observer.py` 自动写入，每周由 `reflector.py` 整理和蒸馏。

## 格式说明

每个日期条目格式如下：

```
Date: YYYY-MM-DD

🔴 High: [方法论/约束] 描述
🟡 Medium: [项目状态/决策] 描述
🟢 Low: [任务流水] 描述
```

### 优先级定义

- **🔴 High**：跨项目通用的经验教训、硬性约束、影响系统架构的重大决策。永久保留，候选晋升为 axiom 或 skill。
- **🟡 Medium**：活跃项目的关键进展、技术决策背景、未来几周仍需参考的信息。
- **🟢 Low**：日常任务流水、瞬时 debug 记录、临时上下文。定期垃圾回收。

## 如何加载记忆

不要全文加载这个文件（可能很大）。按需检索：

```bash
# 搜索特定主题
grep -n "关键词" contexts/memory/OBSERVATIONS.md

# 搜索最近 N 天
grep -A 20 "Date: $(date -v-7d +%Y-%m-%d)" contexts/memory/OBSERVATIONS.md
```

或使用语义搜索（`rules/skills/semantic_search.md`）做跨日期语义检索。

---

<!-- 以下是记录区域，由 observer.py 自动追加 -->

Date: 2026-05-08

🔴 High: [架构决策] BAC-1215 池分配配置管理采用乐观锁（`expected_version` 字段）+ 追加不可变版本记录的设计模式，彻底避免并发覆写；适用于任何需要全量替换且要求审计追溯的配置管理场景。
🔴 High: [架构决策] HashrateCoordinator 扩展采用 AllocationGetter 接口（pull 模型）将调度逻辑与分配数据解耦，runCycle() 每 tick 主动读取而非通过 channel 推送，避免因分配变更阻塞 snapshot 发布。
🟡 Medium: [项目进展] progressive2/specs/003-pool-allocation-config — BAC-1215 规格设计完成（spec.md、plan.md、data-model.md、tasks.md、quickstart.md、api.proto），分 9 个 Phase 共 50 个任务，当前处于 Phase 1 启动前状态，尚无代码实现。
🟡 Medium: [配置变更] flux-cairo/apps/bitcoin 两个配置文件（bitcoin-coordinator-config.yaml、bitcoin-proxy-config.yaml）今日被修改；Cairo 集群 nicehash_1eh 池目标算力配置为 1050000 TH/s（1 EH/s），antpool-bitfufu 为 2170500 TH/s，proxy 与 coordinator 通过相同 name/url/username 三元组计算 pool_digest 确保一致性。
🟡 Medium: [配置变更] flux-cairo/apps/energy-workflow/config.yaml 被修改；energy-workflow 使用 Temporal（namespace=energy）+ PostgreSQL + journalpublisherapi/pool-service OAuth 的标准微服务配置栈。
🟢 Low: [工具] aiup 项目新建/更新于 workspace 根目录，是一个 macOS-first 的 AI CLI & 桌面应用批量升级脚本，支持 Claude Code、Codex、Gemini CLI、Cursor 等工具，通过 npm/uv/brew/vendor-native 等渠道自动检测安装方式并升级。
🟢 Low: [配置] context-infrastructure/.claude/settings.local.json 今日被更新（具体内容未展开，属 Claude Code 本地权限配置）。
