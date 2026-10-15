#!/usr/bin/env bash
# case-map 一致性校验（只读）。由 generate-ai-reviewer-functional-fixtures.sh --check 调用，也可单独运行。
#   bash scripts/check-case-map.sh            # 离线校验
#   bash scripts/check-case-map.sh --issue N  # 另外校验总回归 Issue 中的 FT 集合（需要 gh 登录，只读）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIX="$ROOT/functional-tests/ai-reviewer-fixtures"
MAP="$FIX/case-map.tsv"
IDS="$FIX/ft-ids.txt"
MAIN="$ROOT/scripts/generate-ai-reviewer-functional-fixtures.sh"
ISSUE=""
SKIP_DRYRUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --issue) ISSUE="${2:-}"; shift ;;
    --skip-dry-run) SKIP_DRYRUN=1 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
  shift
done

errs=0
fail() { echo "FAIL: $*"; errs=$((errs+1)); }
ok() { echo "ok:   $*"; }

[ -f "$MAP" ] || { echo "缺少 $MAP" >&2; exit 2; }
[ -f "$IDS" ] || { echo "缺少 $IDS" >&2; exit 2; }

echo "== check-case-map =="

# 1. 列数
cols="$(awk -F'\t' 'NR==1 {print NF}' "$MAP")"
[ "$cols" = 17 ] && ok "表头 17 列" || fail "表头应为 17 列，实际 $cols"
bad_rows="$(awk -F'\t' 'NR>1 && NF!=17 {print NR": "$1" ("NF" 列)"}' "$MAP")"
[ -z "$bad_rows" ] && ok "每行 17 列" || fail "列数不对的行:
$bad_rows"

# 2. ID 合法、唯一，且 == 清单
dups="$(awk -F'\t' 'NR>1 {print $1}' "$MAP" | sort | uniq -d)"
[ -z "$dups" ] && ok "ID 唯一" || fail "重复 ID: $dups"
bad_ids="$(awk -F'\t' 'NR>1 && $1 !~ /^FT-[0-9][0-9][0-9]$/ {print $1}' "$MAP")"
[ -z "$bad_ids" ] && ok "ID 格式合法" || fail "非法 ID: $bad_ids"
if diff <(awk -F'\t' 'NR>1 {print $1}' "$MAP" | sort) <(sort "$IDS") >/dev/null; then
  ok "FT 集合 == ft-ids.txt（$(wc -l < "$IDS" | tr -d ' ') 项）"
else
  fail "case-map 与 ft-ids.txt 的 FT 集合不一致"; diff <(awk -F'\t' 'NR>1 {print $1}' "$MAP" | sort) <(sort "$IDS") | head -n 10
fi

# 3. cases/*.md 存在且四个小节齐全
missing_md=""
for id in $(awk -F'\t' 'NR>1 {print $1}' "$MAP"); do
  f="$FIX/cases/$id.md"
  if [ ! -f "$f" ]; then missing_md="$missing_md $id(缺文件)"; continue; fi
  for h in generatedFiles manualSteps expectedResult requiredEvidence; do
    grep -qx "## $h" "$f" || missing_md="$missing_md $id(缺$h)"
  done
done
[ -z "$missing_md" ] && ok "cases/FT-XXX.md 齐全" || fail "用例详情缺失:$missing_md"

# 4. 枚举取值
bad_enum="$(awk -F'\t' '
  NR>1 {
    if ($3 !~ /^(local-validation|fixture|multi-phase|manual-command|external-observation|manual-security|external-gitlab)$/) print $1": type="$3
    if ($9 !~ /^(e2e|unit-evidence|needs-injection)$/) print $1": coverage="$9
    if ($16 !~ /^(yes|no)$/) print $1": baselineMeaningful="$16
    if ($17 !~ /^(yes|no)$/) print $1": requiresIsolatedEnv="$17
    if ($13 !~ /^(yes|no)$/) print $1": destructive="$13
  }' "$MAP")"
[ -z "$bad_enum" ] && ok "枚举取值合法" || fail "非法取值:
$bad_enum"

# 5. 前置用例存在且无环（反复剥离无入边的节点）
cyc="$(awk -F'\t' '
  NR>1 { id[$1]=1; n=split($7, p, ","); for (i=1;i<=n;i++) if (p[i] ~ /^FT-/) { dep[$1] = dep[$1] " " p[i] } }
  END {
    for (k in id) for (d in id) {}
    for (k in dep) { m=split(dep[k], a, " "); for (j=1;j<=m;j++) if (!(a[j] in id)) print "MISSING " k " -> " a[j] }
    changed=1
    for (k in id) alive[k]=1
    while (changed) {
      changed=0
      for (k in alive) {
        ok=1; m=split(dep[k], a, " ")
        for (j=1;j<=m;j++) if (a[j] in alive) ok=0
        if (ok) { delete alive[k]; changed=1 }
      }
    }
    for (k in alive) print "CYCLE " k
  }' "$MAP")"
[ -z "$cyc" ] && ok "前置用例存在且无环" || fail "前置用例问题:
$cyc"

# 6. 生成器要么 print_*，要么在主脚本中有实现
bad_gen=""
for g in $(awk -F'\t' 'NR>1 {print $6}' "$MAP" | sort -u); do
  case "$g" in
    print_*) ;;
    *) grep -qE "^$g\(\)" "$MAIN" || bad_gen="$bad_gen $g" ;;
  esac
done
[ -z "$bad_gen" ] && ok "生成器均已实现" || fail "未实现的生成器:$bad_gen"
bad_fixture="$(awk -F'\t' 'NR>1 && $3=="fixture" && $6 !~ /^generate_/ {print $1}' "$MAP")"
[ -z "$bad_fixture" ] && ok "fixture 用例均使用 generate_* 生成器" || fail "fixture 用例缺少生成器: $bad_fixture"

# 7. 变体文档
bad_variant=""
for v in $(awk -F'\t' 'NR>1 {print $10}' "$MAP" | sort -u); do
  [ -f "$FIX/config-variants/$v.md" ] || bad_variant="$bad_variant $v"
done
[ -z "$bad_variant" ] && ok "workflowVariant 均有说明文档" || fail "缺少变体文档:$bad_variant"

# 8. baselineMeaningful=no 的约束
bad_bm="$(awk -F'\t' 'NR>1 && $16=="no" && ($10=="baseline" || $17!="yes") {print $1}' "$MAP")"
[ -z "$bad_bm" ] && ok "baselineMeaningful=no 的用例均指定非基线变体且 requiresIsolatedEnv=yes" || fail "baselineMeaningful=no 约束不满足: $bad_bm"

# 9. 每个 --case 都能 --dry-run 并输出合法 Result
if [ "$SKIP_DRYRUN" = 1 ]; then
  echo "skip: --case dry-run 遍历"
else
  bad_dry=""
  for id in $(awk -F'\t' 'NR>1 {print $1}' "$MAP"); do
    out="$(bash "$MAIN" --case "$id" --dry-run 2>&1 || true)"
    res="$(printf '%s\n' "$out" | grep -E '^Result: ' | tail -n1 | awk '{print $2}')"
    case "$res" in
      LOCAL_CHECK_PASS|LOCAL_CHECK_FAIL|FIXTURE_READY|ALREADY_READY|MANUAL_ACTION_REQUIRED|EXTERNAL_EVIDENCE_REQUIRED|BLOCKED|CONFLICT) ;;
      *) bad_dry="$bad_dry $id" ;;
    esac
  done
  [ -z "$bad_dry" ] && ok "全部 $(wc -l < "$IDS" | tr -d ' ') 个 --case --dry-run 都输出合法 Result" || fail "--case --dry-run 异常:$bad_dry"
fi

# 10. 可选：总回归 Issue（含分区评论）中的 FT 集合
if [ -n "$ISSUE" ]; then
  if command -v gh >/dev/null 2>&1; then
    tmp="$(mktemp "${TMPDIR:-/tmp}/ft-issue.XXXXXX")"
    trap 'rm -f "$tmp"' EXIT
    gh issue view "$ISSUE" --repo CodesSentinels/ai-reviewer-test --json body,comments --jq '.body, (.comments[].body)' > "$tmp" 2>/dev/null || fail "无法读取 Issue #$ISSUE"
    if diff <(grep -oE '^- \[[ x]\] FT-[0-9]{3}' "$tmp" | grep -oE 'FT-[0-9]{3}' | sort -u) <(sort "$IDS") >/dev/null; then
      ok "Issue #$ISSUE 中的 FT 集合 == ft-ids.txt"
    else
      fail "Issue #$ISSUE 中的 FT 集合与 ft-ids.txt 不一致"
    fi
  else
    fail "未安装 gh，无法校验 Issue"
  fi
fi

echo
if [ "$errs" -eq 0 ]; then echo "check-case-map: 全部通过"; exit 0; fi
echo "check-case-map: $errs 项失败"; exit 1
