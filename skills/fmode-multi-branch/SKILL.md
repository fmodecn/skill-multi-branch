---
name: fmode-multi-branch
description: "多分支任务编排：Hermes（沟通层）把专业任务派发 Claude Code / Codex / 子 Agent profile 执行，含任务书落盘、执行层纪律、状态上报（ack→running→done/failed + 心跳）、中断续跑与完成验收。适用：(1) 多任务并行调度 (2) 专业内容生产必须走执行层的团队 (3) 需要\"先沟通后派发\"响应模式的 Agent 协作。"
description_en: "Multi-branch orchestration: Hermes (communication layer) dispatches professional tasks to Claude Code / Codex / agent profiles, with task briefs, execution-layer discipline, status reporting (ack→running→done/failed + heartbeat), resume-after-interrupt, and acceptance checks."
---

# Fmode Multi Branch — 沟通/执行分层编排技能

## 〇、执行层纪律（★ 本技能的灵魂，违反=框架失效）

> 教训来源（2026-09-12 实例）：课纲修订任务被 Orchestrator 以"任务琐碎/CLI 慢"为由亲手完成——用户复查发现项目目录下**无 Claude Code 会话痕迹**，判定违规，产出重做。

**分层铁则**：

1. **内容/课件/措辞/方案/代码类专业工作 → 必须派发执行层**（Claude Code / Codex / profile），Orchestrator 只做：任务书 + 验收
2. **允许亲自处理的例外**：单点字符串替换、配置文件行级修改、纯机械部署命令（无创作成分）——判断标准：**这活需要"判断"吗？需要判断就必须派发**
3. **"任务琐碎"“CLI 慢”“上次中断过”都不是绕过的理由**——那是框架要防的人因缺陷；正确动作是派发+监控，不是自己上
4. **验收必查执行痕迹**：`ls ~/.claude/projects/-opt-data-<项目路径>/ | 近时段 jsonl`——**没有会话痕迹的"CC 产出"= 违规产出，重做**
5. **违规产出处理**：不辩论、不降级接受——出任务书让执行层重做（如 1.0.5→1.0.6 实例），并沉淀教训

## 一、任务派发协议

### 1.1 接任务（沟通层职责）

- **先回执后派发**：收到任务先一句话回应用户（"收到，派发执行层做 X，预计 N 分钟"），再 spawn
- 任务书**落盘**（防止超长与上下文丢失）：写到项目 `docs/task-*.md` 或 `/tmp/task-*.md`

### 1.2 任务书模板（要素齐全才可派发）

```markdown
# <任务名> 任务书
你是<角色>。仓库/输入路径：...
## 基准学习（★ 硬性字段——涉及样式/交互/排版必填）
- 基准仓库绝对路径：<如 /opt/data/git-repos/skill-present>（先深读其 deck.js/tokens.css/base.css/page-craft 规则再动手）
- 素材缺失处理：直接从基准仓库复制 lib/ 到本课程仓复用，禁止凭想象写样式
- lib 路径自检：写完第一页即 curl 验证 tokens.css 引用路径线上可达（404=路径错，重算相对层级）
## 你要做的（编号清单，逐条可验收）
## 纪律（不可动项/措辞口径/品牌规则）
## 交付（文件+部署+commit push）
完成后只输出一行：<DONE-标记> <关键字段>
```

> **事故案例（2026-09-12 gpt6-warmup）**：任务书只写"skill-present 级交互"形容词，未给基准仓库路径与 lib 自检要求 → CC 凭想象产出，lib 引用 404 → 全站裸文本无样式无翻页。规则：**凡涉及视觉/交互的任务书，"基准路径+机制深读+路径自检"三字段缺一不可。**

### 1.3 派发（执行层）

```bash
cd <项目目录>   # 会话痕迹落在该项目的 .claude/projects/ 下（验收依据）
export ANTHROPIC_BASE_URL=<api> ANTHROPIC_AUTH_TOKEN=$FMODE_API_KEY
<claude|codex> -p "$(cat 任务书路径摘要指令)" --model <model> --dangerously-skip-permissions
```

- **后台运行 + notify_on_complete**（完成通知挂钩）
- 派发时附带：`先检查现状再续做，勿重复已完成部分`（中断续跑保险）

### 1.4 状态上报（与 reporter 同表）

| 状态 | 触发 | 记录 |
|---|---|---|
| ack | 接任务回执时 | 任务名/执行层/预计时长 |
| running | spawn 成功 | PID/会话目录 |
| done | DONE-标记 收到+验收过 | 交付物/commit |
| failed | 进程退出无标记/超时/验收不过 | 根因/重试次数 |

**心跳**：running 状态 30s 无心跳 = 疑似死亡 → 主动查进程与产物，不靠"以为还在跑"。

## 二、验收协议

1. **执行痕迹**（见 〇-4）
2. **DONE 标记核对**：输出行是否符合任务书格式
3. **产物独立验证**：线上 URL 逐个 curl / 文件字节级抽查 / diff 对照（内容类：只许更好不许丢内容）
4. **不过关处理**：定点问题回执执行层修；结构性问题重出任务书

## 三、已知故障与对策

| 故障 | 症状 | 对策 |
|---|---|---|
| API 403/中断 | CLI 中途死 | 充值确认后**续跑指令**（先查现状续做勿重复） |
| gateway 重启连带 | CLI 子进程全灭+notify 丢失 | 重启前盘点在跑任务；重启后巡检+补 spawn |
| 自报 200 假阳性 | hash MATCH 但内容旧/缺 | 验收永远独立 curl+内容特征词 |
| obsutil 目录 cp 嵌套 | lib/lib/ 双层目录 | **逐文件指定目标键**，禁目录递归 cp |
| CDN 缓存顽固 | 改完还回旧版 | 带 ?v= 参数验证 + OBS 源字节级核对 |
| 中文 URL 不可点 | 用户点不开 | 发送前 encodeURI；线上文件名用英文 |

## 四、脚本

`scripts/dispatch.sh`：标准派发器（任务书路径+项目目录+模型 → 后台 spawn+状态记录）
`scripts/status-reporter.mjs`：四态+心跳写 reporter 同表（AgentTaskStatus）
