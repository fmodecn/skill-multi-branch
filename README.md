# skill-multi-branch · 沟通/执行分层编排

> **Hermes 负责沟通，专业任务派发给执行层（Claude Code / Codex / Agent profile），状态全程上报**——数字生命的多任务工作框架。
> 本技能内含一条被真实事故验证的**执行层纪律**（ Orchestrator 亲自干活=框架失效），是它的灵魂章节。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 解决什么

单 Agent 既当沟通者又当执行者时必然出现：用户问话没人答、长任务静默死亡、"以为在跑其实在躺"、Orchestrator 亲自干专业活导致质量与纪律双输。本技能把三层职责显式分开：

```
用户 ⇄ 沟通层(Hermes) —— 有问必答、先回执后派发
              ↓ 任务书(落盘)
        调度层(multi-branch) —— ack→running→done/failed + 心跳
              ↓
        执行层(Claude Code / Codex / profile) —— 专业产出，会话痕迹可查
```

## 快速用

```bash
bash skills/fmode-multi-branch/scripts/dispatch.sh <项目目录> <任务书.md> [模型] [DONE标记]
```

状态日志：`/tmp/mb-status.log`（ack/done/failed 时间线）。

## 执行层纪律（详见 SKILL.md 〇章）

- 专业工作必须派发，Orchestrator 只出任务书+验收
- "任务琐碎/CLI 慢"不是绕过理由
- 验收先查**执行痕迹**（项目 `.claude/projects/` 会话 jsonl），无痕迹=违规产出，重做

## 各工具安装

### Hermes Agent
```bash
git clone https://git.fmode.cn/fmode/skill-multi-branch.git
cp -r skill-multi-branch/skills/fmode-multi-branch ~/.hermes/skills/
```

### Claude Code / Codex
本技能主要服务 Hermes 侧调度；Claude Code 侧只需任务书规范（SKILL.md 一章）——可直接把 SKILL.md 并入项目 CLAUDE.md。

### WorkBuddy / 其他
复制 `skills/fmode-multi-branch` 到对应技能目录。

## 凭据

`FMODE_API_KEY` 环境变量 或 `~/.fmode/config.json`（与家族其他技能同链）。

## License

MIT
