#!/usr/bin/env bash
#
# 迭代二 · 成员 D — 对话式追问"多轮评论交互"端到端测试脚本
#
# 它做什么:
#   在 Bot 的某条行级审查评论(thread)里，连续多轮 @ai-reviewer 追问，
#   每轮发出问题后轮询等待 Bot 在同一 thread 内的回复，验证：
#     - 追问意图识别（thread 内回复即触发，无需每条都 @）
#     - 上下文携带（回答与所评论的代码相关）
#     - 多轮对话连续性
#     - 对话轮次上限护栏（可选，把 ROUNDS 调到 > 上限观察终止提示）
#
# 用法:
#   PR=123 bash docs/run-iter2-member-d-test.sh                 # 默认 3 轮
#   PR=123 ROUNDS=12 bash docs/run-iter2-member-d-test.sh       # 触发轮次上限(10)
#   DRY=1 PR=123 bash docs/run-iter2-member-d-test.sh           # 仅打印不发送
#   PR=123 TIMEOUT=180 POLL=10 bash docs/run-iter2-member-d-test.sh
#
# 前置条件:
#   - gh CLI 已登录、jq 已安装
#   - 当前目录在 ai-reviewer-test 仓库内
#   - PR 已创建且自动 review 已产出**行级**评论（pull request review comments）
#   - 使用的 Action 分支包含成员 D 代码
#
set -euo pipefail

: "${PR:?请设置 PR 编号: PR=123 bash $0}"
DRY="${DRY:-0}"
ROUNDS="${ROUNDS:-3}"        # 追问轮数
TIMEOUT="${TIMEOUT:-150}"    # 每轮等待 Bot 回复的最长秒数
POLL="${POLL:-8}"           # 轮询间隔秒数

command -v jq >/dev/null || { echo "缺少 jq，请先安装"; exit 1; }
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# 每轮的追问内容（thread 内回复，首轮带 @ 召唤，后续可不带）
QUESTIONS=(
  "@ai-reviewer 这个问题为什么严重？可能造成什么实际后果？"
  "那推荐的修复方式是什么？请给出代码示例。"
  "如果改用你建议的方案，会影响其它调用方吗？"
  "性能上有额外开销吗？"
  "有没有对应的官方文档或最佳实践链接？"
  "总结一下这条 thread 的结论。"
)

echo "============================================="
echo "  迭代二 · 成员 D 多轮对话测试"
echo "  仓库:   ${REPO}"
echo "  PR:     #${PR}"
echo "  轮数:   ${ROUNDS}"
echo "  超时:   ${TIMEOUT}s / 轮（轮询 ${POLL}s）"
echo "  模式:   $( [[ "$DRY" == "1" ]] && echo 'DRY RUN（不发送）' || echo '实际发送' )"
echo "============================================="
echo ""

# 判定一条 review comment 是否为 Bot 产出（按自动生成标签 / bot 登录名）
BOT_FILTER='(.body | test("auto-generated (comment|reply) by AI Reviewer"))
            or (.user.login | endswith("[bot]"))'

# 列出 PR 的全部行级评论(review comments)
list_review_comments() {
  gh api --paginate "repos/${REPO}/pulls/${PR}/comments" 2>/dev/null
}

# 找到一条作为对话锚点的 Bot 顶层行级评论（无 in_reply_to_id 的 Bot 评论）
find_anchor() {
  list_review_comments | jq -r "
    [ .[] | select((.in_reply_to_id == null) and (${BOT_FILTER})) ]
    | sort_by(.id) | .[0] // empty
    | \"\(.id)\t\(.path):\(.line // .original_line)\"
  "
}

# 统计某 thread(root=ROOT) 内 Bot 回复条数（root 自身 + in_reply_to_id==root 的 Bot 评论）
count_bot_in_thread() {
  local root="$1"
  list_review_comments | jq "
    [ .[] | select(((.id == ${root}) or (.in_reply_to_id == ${root})) and (${BOT_FILTER})) ]
    | length
  "
}

# 在 thread 内回帖
reply_in_thread() {
  local root="$1"; local body="$2"
  gh api "repos/${REPO}/pulls/${PR}/comments/${root}/replies" \
    -f body="$body" >/dev/null
}

# 取 thread 内最新一条 Bot 回复正文（用于打印观察）
latest_bot_reply() {
  local root="$1"
  list_review_comments | jq -r "
    [ .[] | select(((.id == ${root}) or (.in_reply_to_id == ${root})) and (${BOT_FILTER})) ]
    | sort_by(.created_at) | last | .body // \"\"
  " | head -c 400
}

# ---- 0. 定位对话锚点 ----
echo "--- 0. 定位 Bot 行级评论锚点 ---"
ANCHOR="$(find_anchor || true)"
if [[ -z "${ANCHOR}" ]]; then
  echo "✗ 未找到 Bot 的行级审查评论。"
  echo "  请确认：自动 review 已完成，且在 diff 行上产生了 review comments（非仅 PR 摘要）。"
  exit 1
fi
ROOT_ID="$(echo "$ANCHOR" | cut -f1)"
ROOT_LOC="$(echo "$ANCHOR" | cut -f2)"
echo "✓ 锚点 thread: comment_id=${ROOT_ID}  位置=${ROOT_LOC}"
echo ""

# ---- 多轮追问 ----
PASS=0
for ((r = 1; r <= ROUNDS; r++)); do
  Q="${QUESTIONS[$(((r - 1) % ${#QUESTIONS[@]}))]}"
  echo "--- 第 ${r}/${ROUNDS} 轮追问 ---"
  echo "  Q: ${Q}"

  if [[ "$DRY" == "1" ]]; then
    echo "  (DRY) 将在 thread ${ROOT_ID} 内回帖，并等待 Bot 回复"
    PASS=$((PASS + 1))
    echo ""
    continue
  fi

  BEFORE="$(count_bot_in_thread "$ROOT_ID")"
  reply_in_thread "$ROOT_ID" "$Q"
  echo "  ✓ 已回帖，等待 Bot 回复（thread 内 Bot 评论数 ${BEFORE} → ?）"

  WAITED=0
  GOT=0
  while ((WAITED < TIMEOUT)); do
    sleep "$POLL"
    WAITED=$((WAITED + POLL))
    AFTER="$(count_bot_in_thread "$ROOT_ID")"
    if ((AFTER > BEFORE)); then
      GOT=1
      echo "  ✓ Bot 已回复（${BEFORE} → ${AFTER}，耗时 ~${WAITED}s）"
      echo "    回复预览: $(latest_bot_reply "$ROOT_ID" | tr '\n' ' ')"
      break
    fi
    echo "    …等待中（${WAITED}/${TIMEOUT}s，当前 ${AFTER}）"
  done

  if ((GOT == 1)); then
    PASS=$((PASS + 1))
  else
    echo "  ✗ 超时未见 Bot 回复"
    echo "    若此时已超过对话轮次上限(10)，属预期：Bot 会回复"
    echo "    『已达对话轮次上限』——请人工查看 thread 确认。"
  fi
  echo ""
done

echo "============================================="
echo "  完成：${PASS}/${ROUNDS} 轮收到 Bot 回复"
echo "  人工核对要点（见 docs/08-iteration2-member-d-test-case.md）:"
echo "   - 回答是否结合了被评论的代码上下文"
echo "   - 多轮之间是否保持了对话连贯性"
echo "   - 超过 10 轮后是否出现『轮次上限』终止提示"
echo "============================================="
