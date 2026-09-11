#!/usr/bin/env bash
# dispatch.sh — multi-branch 标准派发器
# 用法: dispatch.sh <项目目录> <任务书路径> [模型] [DONE标记]
# 职责: ack 记录 → 后台 spawn 执行层 → 状态可查
set -euo pipefail
PROJECT_DIR="${1:?用法: dispatch.sh <项目目录> <任务书路径> [模型] [DONE标记]}"
BRIEF="${2:?缺任务书路径}"
MODEL="${3:-deepseek-v4-flash}"
DONE_TAG="${4:-DONE}"
TS=$(date +%Y%m%d-%H%M%S)
LOG="/tmp/mb-${TS}.log"

cd "$PROJECT_DIR"

echo "[ack] $(date '+%F %T') 任务书=$BRIEF 执行层=claude 模型=$MODEL" >> /tmp/mb-status.log

export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.fmode.cn}"
export ANTHROPIC_AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:-$FMODE_API_KEY}"

/opt/data/npm-global/bin/claude -p "$(cat "$BRIEF")" --model "$MODEL" --dangerously-skip-permissions 2>&1 | tee "$LOG" | tail -3

if grep -q "$DONE_TAG" "$LOG"; then
  echo "[done] $(date '+%F %T') $BRIEF" >> /tmp/mb-status.log
  exit 0
else
  echo "[failed] $(date '+%F %T') $BRIEF (无DONE标记, 需续跑: 加'先检查现状续做勿重复'重派)" >> /tmp/mb-status.log
  exit 1
fi
