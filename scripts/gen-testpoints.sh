#!/usr/bin/env bash
#
# gen-testpoints.sh — 生成 CodeSentinel AI Reviewer 全功能「测试点」代码
# =============================================================================
#
# 目的：
#   针对 ai-reviewer 的 **每一项功能**，在基线项目之上生成对应的测试变更代码，
#   并打印「如何用这些变更触发该功能、以及预期观察到什么」的操作指引。
#
#   本脚本 **只生成文件 + 打印指引**，不做任何 git 操作。分支创建、commit、
#   push、建 PR、发评论全部由你手动执行（见每个域末尾打印的指引）。
#
# 覆盖的 8 大功能域（与 src/ 模块一一对应）：
#   A  基础审查流程       review.ts 四阶段：摘要→合并→审查→行级评论 + 发布说明
#   B  增量审查           review.ts 基于 last_reviewed_sha 的增量 diff
#   C  文件过滤与限制     options.ts path_filters / max_files
#   D  跨文件依赖分析     dependency-analyzer.ts 导入解析 + 引用搜索（含 Vue/Nuxt）
#   E  命令系统           commands/ 解析/权限/限流/幂等 + help/resolve/review/pause…
#   F  对话追问 + 噪音控制 conversation.ts + noise-control.ts + review-dedup.ts
#   G  Lint / SAST 集成   lint/ ESLint + Biome + tsc + Prettier + Semgrep
#   H  Web 搜索 + Shell    bot.ts enableWebSearch / enableShell
#
# 用法：
#   cd /path/to/ai-reviewer-test
#   bash scripts/gen-testpoints.sh              # 生成全部域
#   bash scripts/gen-testpoints.sh A D G        # 只生成指定域
#   bash scripts/gen-testpoints.sh --list       # 列出所有域
#   bash scripts/gen-testpoints.sh --force      # 覆盖已存在文件
#
# 生成物统一位于  test_cases/<域字母>-<域名>/  下。
# 详见配套文档  scripts/TEST-POINTS.md。
# =============================================================================

set -euo pipefail

FORCE=0
DOMAINS=()
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --list)
      echo "可用功能域："
      echo "  A  基础审查流程"
      echo "  B  增量审查"
      echo "  C  文件过滤与限制"
      echo "  D  跨文件依赖分析"
      echo "  E  命令系统"
      echo "  F  对话追问 + 噪音控制"
      echo "  G  Lint / SAST 集成"
      echo "  H  Web 搜索 + Shell"
      exit 0
      ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    [A-Ha-h]) DOMAINS+=("$(echo "$arg" | tr '[:lower:]' '[:upper:]')") ;;
    *) echo "未知参数: $arg（用 --help 查看用法）" >&2; exit 1 ;;
  esac
done

# 未指定域 → 全部
if [[ ${#DOMAINS[@]} -eq 0 ]]; then
  DOMAINS=(A B C D E F G H)
fi

BASE="test_cases"

# ---- 工具函数 ---------------------------------------------------------------
write_file() {
  local path="$1"
  if [[ -e "$path" && "$FORCE" -ne 1 ]]; then
    echo "  跳过（已存在，用 --force 覆盖）: $path"
    cat >/dev/null
    return
  fi
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  echo "  写入: $path"
}

want() {
  local d="$1"
  for x in "${DOMAINS[@]}"; do [[ "$x" == "$d" ]] && return 0; done
  return 1
}

hr() { echo "-------------------------------------------------------------"; }

echo "==> 测试点生成目录: $(pwd)/$BASE"
echo "==> 选定功能域: ${DOMAINS[*]}"
echo ""

# =============================================================================
# 域 A —— 基础审查流程
# =============================================================================
if want A; then
  echo "### 域 A：基础审查流程 ###"
  D="$BASE/A-basic-review"

  write_file "$D/insecure-handler.ts" << 'EOF'
// 域 A 测试文件：故意植入多类问题，触发四阶段审查 + 行级评论。
// 预期 Bot 指出：SQL 注入 / eval / 未 await / 循环内建正则。
export function handleRequest(req: any, res: any) {
  const userId = req.query.id
  const query = `SELECT * FROM users WHERE id = '${userId}'` // SQL 注入
  const code = req.body.expression
  const result = eval(code) // 任意代码执行

  async function saveData(data: any) {
    fetch('/api/save', {method: 'POST', body: JSON.stringify(data)}) // 缺少 await
  }

  function filterItems(items: string[], pattern: string) {
    return items.filter(item => {
      const regex = new RegExp(pattern) // 循环内重复构造正则
      return regex.test(item)
    })
  }

  void saveData(query)
  void filterItems([], userId)
  res.end(JSON.stringify({result}))
}
EOF

  write_file "$D/PR-BODY.md" << 'EOF'
# 域 A 基础审查 —— PR 描述模板

将以下内容作为 PR 描述，用于验证发布说明写回（A4）：

---
本 PR 引入一个包含多类问题的请求处理函数，用于验证 AI Reviewer 的基础审查能力。

预期 Bot 会：
- 产出顶部摘要评论（Walkthrough + Changes 表格）
- 对 SQL 注入 / eval / 未 await / 循环内正则产出行级评论
- 在 PR 描述末尾追加 "Summary by CodeSentinel" 发布说明
---
EOF

  write_file "$D/IGNORE-PR-BODY.md" << 'EOF'
# 域 A（A6）—— @codesentinel: ignore 跳过审查

将以下内容作为 PR 描述，验证 Bot 完全跳过审查（无任何评论）：

---
这个 PR 不需要 AI 审查。

@codesentinel: ignore
---
EOF

  hr
  echo "域 A 操作指引："
  echo "  A1 自动触发    : 从基准分支拉 feature 分支，提交 $D/insecure-handler.ts → 建 PR，等 1~3 分钟"
  echo "  A2 摘要格式    : 检查 Bot 首条评论含 Walkthrough + Changes 表格"
  echo "  A3 行级评论定位: 对比评论行号与 insecure-handler.ts 中问题行（±2 行内）"
  echo "  A4 发布说明    : PR 描述末尾应出现 'Summary by CodeSentinel'"
  echo "  A5 disable_review: 临时在 workflow 设 disable_review: true → 新 PR 应仅有摘要、无行级评论"
  echo "  A6 ignore 跳过 : 用 $D/IGNORE-PR-BODY.md 作 PR 描述 → Bot 无任何评论"
  echo ""
fi

# =============================================================================
# 域 B —— 增量审查
# =============================================================================
if want B; then
  echo "### 域 B：增量审查 ###"
  D="$BASE/B-incremental"

  write_file "$D/step1-math.ts" << 'EOF'
// 域 B 第 1 次提交：先 push 触发首次审查。
export function add(a: number, b: number): number {
  return a + b
}

export function multiply(a: number, b: number): number {
  return a * b
}
EOF

  write_file "$D/step2-math-append.ts" << 'EOF'
// 域 B 第 2 次提交：在 Bot 审完 step1 后，把这些函数【追加】到 step1-math.ts，
// 再 push。预期 Bot 仅评论 divide/power，不重复评论 add/multiply。
export function divide(a: number, b: number): number {
  return a / b // 问题：未检查除零
}

export function power(base: number, exp: number): number {
  let result = 1
  for (let i = 0; i < exp; i++) {
    result *= base // 问题：负指数处理不当
  }
  return result
}
EOF

  hr
  echo "域 B 操作指引："
  echo "  B1 增量 diff   : 提交 step1-math.ts → 建 PR → 等审查完 → 把 step2 内容追加到同文件 → 再 push"
  echo "                   预期：第二次评论仅针对 divide/power，不重复 add/multiply"
  echo "  B2 已审 commit : 检查摘要评论 HTML 隐藏标签含 <!-- commit_ids_reviewed -->，列出已审 SHA"
  echo "  B3 full review : 在已审 PR 评论区发 '@codesentinel full review' → 覆盖 base..HEAD 全部变更"
  echo ""
fi

# =============================================================================
# 域 C —— 文件过滤与限制
# =============================================================================
if want C; then
  echo "### 域 C：文件过滤与限制 ###"
  D="$BASE/C-file-filter"

  write_file "$D/keep/version.ts" << 'EOF'
// 应被审查：匹配 path_filters 的 **/*.ts
export const VERSION = '1.0.0'

export function bug(x: number): number {
  return 100 / x // 未处理除零，作为「确实被审查」的信号
}
EOF

  write_file "$D/skip/styles.css" << 'EOF'
/* 应被过滤：.css 不在 path_filters 白名单中，Bot 不应审查此文件 */
.button { color: #f00; }
EOF

  write_file "$D/skip/data.json" << 'EOF'
{ "note": "应被过滤：*.json 在默认黑名单中，不应被审查" }
EOF

  write_file "$D/gen-many-files.sh" << 'EOF'
#!/usr/bin/env bash
# 域 C（C3 max_files）：生成 6 个 TS 文件，配合 workflow 中 max_files: 3 验证跳过统计。
set -euo pipefail
OUT="${1:-test_cases/C-file-filter/many}"
mkdir -p "$OUT"
for i in $(seq 1 6); do
  cat > "$OUT/module${i}.ts" << TS
export function fn${i}(x: number): number {
  return 100 / x // 未处理边界
}
TS
done
echo "已生成 6 个 TS 文件到 $OUT（配合 max_files: 3 验证 C3）"
EOF
  chmod +x "$D/gen-many-files.sh" 2>/dev/null || true

  hr
  echo "域 C 操作指引："
  echo "  C1 二进制排除 : PR 同时含图片(.png)与 keep/version.ts → 仅 TS 被审查"
  echo "  C2 path 过滤  : 提交 skip/styles.css + skip/data.json + keep/version.ts → 仅 version.ts 出现在审查中"
  echo "  C3 max_files  : 运行 $D/gen-many-files.sh，临时设 workflow max_files: 3 → 摘要显示只审 3 个、记录跳过"
  echo "  C4 lock 排除  : PR 含 pnpm-lock.yaml/package-lock.json 变更 → lock 文件不出现在审查中"
  echo ""
fi

# =============================================================================
# 域 D —— 跨文件依赖分析
# =============================================================================
if want D; then
  echo "### 域 D：跨文件依赖分析 ###"
  D="$BASE/D-cross-file"

  write_file "$D/CHANGE-formatPrice.ts" << 'EOF'
// 域 D：用此内容【替换基线的 utils/formatPrice.ts】，改签名 + 改默认值 + 新增参数。
// 预期 Bot 在审查评论/摘要中提及引用方：useCart.ts / ProductCard.vue /
// CartSummary.vue / server/api/products.ts。
export function formatPrice(
  amount: number,
  currency = 'USD', // 改默认值 CNY → USD（破坏性）
  locale = 'en-US' // 新增参数
): string {
  if (amount < 0) return 'N/A' // 新增负数处理
  return new Intl.NumberFormat(locale, {style: 'currency', currency}).format(
    amount
  )
}

export function parsePrice(text: string): number {
  const cleaned = text.replace(/[^0-9.]/g, '')
  const value = Number.parseFloat(cleaned)
  return Number.isFinite(value) ? value : 0
}
EOF

  write_file "$D/CHANGE-useCart.ts" << 'EOF'
// 域 D：用此内容【替换基线的 composables/useCart.ts】，把 total 返回类型
// 从 number 改为对象（破坏性）。预期 Bot 提及 pages/cart.vue、CartSummary.vue
// 的 total 使用方式可能受影响。
import {ref, computed} from 'vue'
import {formatPrice} from '~/utils/formatPrice'

export interface CartItem {
  id: string
  name: string
  price: number
  qty: number
}

export function useCart() {
  const items = ref<CartItem[]>([])
  const total = computed((): {amount: number; formatted: string} => {
    const amount = items.value.reduce((s, i) => s + i.price * i.qty, 0)
    return {amount, formatted: formatPrice(amount)}
  })
  function addItem(item: CartItem): void {
    items.value.push(item)
  }
  function removeItem(id: string): void {
    items.value = items.value.filter(i => i.id !== id)
  }
  // 移除 formattedTotal 单独导出（破坏性）
  return {items, total, addItem, removeItem}
}
EOF

  hr
  echo "域 D 操作指引（依赖基线已含 utils/formatPrice.ts + composables/useCart.ts）："
  echo "  D1 修改导出函数: 用 CHANGE-formatPrice.ts 替换基线 utils/formatPrice.ts → 审查提及引用方文件名"
  echo "  D2 TS import   : 摘要应列出 named import 引用方（ProductCard.vue / products.ts 等）"
  echo "  D3 Vue/Nuxt    : 用 CHANGE-useCart.ts 替换基线 composables/useCart.ts → 提及 cart.vue / CartSummary.vue"
  echo "  D4 开关关闭    : 临时设 workflow enable_dependency_analysis: false → 摘要无跨文件段落"
  echo "  D5 max 限制    : 设 max_dependency_files: 2，修改被 3+ 文件引用的符号 → 最多分析 2 个引用方"
  echo ""
fi

# =============================================================================
# 域 E —— 命令系统
# =============================================================================
if want E; then
  echo "### 域 E：命令系统 ###"
  D="$BASE/E-commands"

  write_file "$D/command-anchor.ts" << 'EOF'
// 域 E：含问题的代码，先让 Bot 产出行级评论，供 resolve 命令批量解决。
export function unsafeQuery(table: string, id: string): string {
  return `SELECT * FROM ${table} WHERE id = '${id}'` // SQL 注入
}

export function weakToken(): string {
  return Math.random().toString(36).slice(2) // 弱随机
}
EOF

  write_file "$D/command-sequence.md" << 'EOF'
# 域 E 命令测试序列（在 PR 评论区依次执行）

> 已注册命令：help / resolve / review / full review / summary / pause / resume / configuration
> mention 别名：@codesentinel 与 @ai-reviewer（均大小写不敏感）
> 权限：多数命令 minPermission=write；help 与 configuration 为 read

## E1 解析与路由（P0）
1. `@codesentinel help`              → 回帖展示所有命令用法
2. `@ai-reviewer help`               → 别名同样触发（E1 别名）
3. `@CodeSentinel HELP`              → 大小写不敏感，同样触发
4. `@codesentinel xyz`               → 回帖提示无效命令（UNKNOWN_COMMAND）
5. `这是一条普通评论，不含 mention`   → Bot 无任何响应
6. (观察) Bot 自身回帖后无二次触发（无死循环）

## E2 权限与限流（P0）
7. write 权限用户 `@codesentinel review`        → 执行成功
8. read 权限用户 `@codesentinel review`         → 回帖 FORBIDDEN
9. read 权限用户 `@codesentinel configuration`  → 执行成功（minPermission=read）
10. 快速连发 5+ 次 `@codesentinel help`          → 第 N 次被限流，提示重试时间
11. (通过 Actions 重跑同一条评论) 观察第二次判为 DUPLICATE（幂等）

## E3 resolve（P0）
12. 等 command-anchor.ts 的行级评论产出后 `@codesentinel resolve` → 批量 resolve + 统计
13. 在无待解决评论的 PR 上 `@codesentinel resolve`               → 回帖「没有找到待解决的审查意见」

## E4 审查控制（P0/P1）
14. `@codesentinel review`         → 触发增量审查
15. `@codesentinel full review`    → 从 base 全量审查
16. `@codesentinel summary`        → 重新生成顶部摘要
17. `@codesentinel pause`          → PR 写入暂停标记
18. (pause 后 push 新 commit)      → 不自动触发审查
19. `@codesentinel resume`         → 恢复标记
20. (resume 后 push 新 commit)     → 触发审查
21. `@codesentinel configuration`  → 展示当前配置表格

## E5 ACK 与反馈（P1）
22. 发送任意有效命令 → 评论上出现 🚀 表情（command_ack_reaction）
23. 执行 review → 先回「正在执行」，完成后更新
24. 触发错误场景 → 错误信息清晰、含操作建议
EOF

  hr
  echo "域 E 操作指引："
  echo "  1. 提交 command-anchor.ts 建 PR，等 Bot 产出行级评论"
  echo "  2. 按 $D/command-sequence.md 在 PR 评论区依次执行命令序列"
  echo "  3. E2/E8 需两个不同权限的账号；限流(E10)与幂等(E11)需连发/重跑观察"
  echo ""
fi

# =============================================================================
# 域 F —— 对话追问 + 噪音控制
# =============================================================================
if want F; then
  echo "### 域 F：对话追问 + 噪音控制 ###"
  D="$BASE/F-conversation-noise"

  write_file "$D/conversation-anchor.ts" << 'EOF'
// 域 F 对话锚点：设计为「值得追问」的问题，供 3.1 对话测试。
export function processPayment(amount: number, userId: string) {
  if (amount) {
    const query = `UPDATE balance SET amount = ${amount} WHERE user = '${userId}'` // SQL 注入
    return executeQuery(query)
  }
}

declare function executeQuery(q: string): unknown
EOF

  write_file "$D/quality-mixed-severity.ts" << 'EOF'
// 域 F 噪音控制：混合各严重级别 + 同类重复（Math.random×5）验证合并/排序/截断。
import {readFileSync} from 'fs'

// ===== critical =====
export function login(username: string, password: string) {
  const query = `SELECT * FROM users WHERE name='${username}' AND pwd='${password}'`
  eval(query) // SQL 注入 + eval
}
export function renderHtml(userInput: string) {
  ;(document as any).body.innerHTML = userInput // XSS
}
export function executeCommand(cmd: string) {
  require('child_process').execSync(cmd) // 命令注入
}

// ===== major =====
export async function fetchData(url: string) {
  fetch(url) // 缺少 await
}
export function divide(a: number, b: number) {
  return a / b // 未检查除零
}
export function parseConfig(json: string) {
  return JSON.parse(json) // 未 try-catch
}

// ===== minor / nit（同类重复，应被合并）=====
export function getRandomId() {
  return Math.random().toString(36).slice(2)
}
export function getRandomToken() {
  return Math.random().toString(36).slice(2)
}
export function getRandomKey() {
  return Math.random().toString(36).slice(2)
}
export function getRandomValue() {
  return Math.random().toString(36).slice(2)
}
export function getRandomHash() {
  return Math.random().toString(36).slice(2)
}

export function unusedImportDemo() {
  const fs = readFileSync // 未使用
  return 'hello'
}
EOF

  write_file "$D/dedup-scenarios.ts" << 'EOF'
// 域 F AI 评论去重：连续同类违规应合并；不同类违规应各自保留。
export function processItems(items: string[]) {
  var item1 = items[0] // no-var（连续 5 行，应合并）
  var item2 = items[1] // no-var
  var item3 = items[2] // no-var
  var item4 = items[3] // no-var
  var item5 = items[4] // no-var

  eval(item1) // no-eval（安全，独立保留）
  console.log(item2) // no-console（风格，独立保留）
  return item3 == item4 ? item5 : null // eqeqeq（正确性，独立保留）
}
EOF

  write_file "$D/conversation-sequence.md" << 'EOF'
# 域 F 对话追问序列（在 processPayment 的行级评论 thread 中执行）

> 常量：MAX_CONVERSATION_TURNS=10，MAX_CHAIN_CHARS=12000
> 仅 pull_request_review_comment（行级 thread）支持对话；issue_comment 不支持

## F-对话（3.1 / 3.2）
1. `@codesentinel 为什么直接拼接 SQL 是个问题？可以说说攻击场景吗？` → 引用该行 + 解释
2. `@codesentinel 用参数化查询的话这段应该怎么改？`                  → 含修改建议，引用上一轮
3. (在 thread 中直接回复，不含 @) → Bot 不触发
4. (观察 Bot 回帖后无新 workflow run) → 无自触发循环
5. 循环追问至第 11 轮 → 第 11 轮提示「轮次已达上限」
6. 在 PR 主评论区（非行级）`@codesentinel 解释一下` → Bot 不回复（issue_comment 不支持对话）
EOF

  hr
  echo "域 F 操作指引："
  echo "  F-噪音(3.3): 提交 quality-mixed-severity.ts → 检查级别徽标(🚨严重/⚠️主要/📝建议/💡微调)、"
  echo "               critical 排前、评论数 ≤ max_review_comments(20)、Math.random×5 被合并"
  echo "  F-去重(3.5): 提交 dedup-scenarios.ts → 连续 no-var 合并为 1 条，eval/console/eqeqeq 各自保留"
  echo "  F-对话(3.1): 等 conversation-anchor.ts 产出行级评论后，按 conversation-sequence.md 在 thread 追问"
  echo "  F-截断    : 临时设 max_review_comments: 0 → 所有评论都展示、无截断提示"
  echo ""
fi

# =============================================================================
# 域 G —— Lint / SAST 集成
# =============================================================================
if want G; then
  echo "### 域 G：Lint / SAST 集成 ###"
  D="$BASE/G-lint-sast"

  write_file "$D/lint-violations.ts" << 'EOF'
// 域 G：触发 ESLint / tsc / Biome 多工具。预期 Bot 评论引用工具规则 + 底部「🧰 Tools」卡片。
import {readFileSync} from 'fs'

const unusedVariable = 42 // ESLint no-unused-vars

function callUndefined() {
  return undeclaredFunction() // tsc TS2304 / ESLint no-undef
}

function expectNumber(n: number): number {
  return n * 2
}
const result = expectNumber('hello' as any as number) // tsc 类型不匹配

export function unsafeAny(x: any): any {
  return x.foo.bar.baz // Biome noExplicitAny
}

export function shouldUseConst() {
  let value = 'never reassigned' // Biome useConst / ESLint prefer-const
  return value
}

void callUndefined
void result
void readFileSync
EOF

  write_file "$D/security-semgrep.ts" << 'EOF'
// 域 G（G7 Semgrep）：需 workflow 设 enable_semgrep: true。
// 预期 Bot 评论引用 Semgrep 规则 ID（注入 / XSS 等）。
import express from 'express'
import {execSync} from 'child_process'

const app = express()

// semgrep: express xss
app.get('/profile', (req, res) => {
  res.send(`<h1>Welcome ${req.query.name}</h1>`)
})

// semgrep: dangerous-exec
app.post('/run', (req, res) => {
  const output = execSync(req.body.command)
  res.json({output: output.toString()})
})
EOF

  hr
  echo "域 G 操作指引（依赖基线含 eslint.config.js / biome.json / tsconfig.json）："
  echo "  G1 ESLint     : 提交 lint-violations.ts → 评论引用 ESLint 规则名"
  echo "  G2 tsc        : 评论引用 TypeScript 错误码（如 TS2304 / TS2345）"
  echo "  G3 Biome      : 评论引用 Biome 规则（noExplicitAny / useConst）"
  echo "  G4 归因卡片   : 行级评论底部含「🧰 Tools」段落，列出参与工具"
  echo "  G5 总开关关闭 : 临时设 enable_lint_tools: false → 无规则引用、无 Tools 卡片"
  echo "  G6 单独禁用   : 设 enable_eslint: false → 无 ESLint 引用，但 tsc/Biome 仍在"
  echo "  G7 Semgrep    : 设 enable_semgrep: true，提交 security-semgrep.ts → 评论引用 Semgrep 规则 ID"
  echo ""
fi

# =============================================================================
# 域 H —— Web 搜索 + Shell
# =============================================================================
if want H; then
  echo "### 域 H：Web 搜索 + Shell ###"
  D="$BASE/H-websearch-shell"

  write_file "$D/websearch-trigger.ts" << 'EOF'
// 域 H：使用较新/冷门 API，诱导模型联网核实用法。
// 预期 Analysis chain 中出现 web_search 步骤（enable_web_search: true 时）。
export async function deriveKey(password: string): Promise<CryptoKey> {
  const baseKey = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveKey']
  )
  return crypto.subtle.deriveKey(
    {name: 'PBKDF2', salt: new Uint8Array(16), iterations: 100000, hash: 'SHA-256'},
    baseKey,
    {name: 'AES-GCM', length: 256},
    false,
    ['encrypt', 'decrypt']
  )
}

export function usesAbortTimeout(url: string): Promise<Response> {
  // AbortSignal.timeout 需 Node 17.3+，模型可能联网核实
  return fetch(url, {signal: AbortSignal.timeout(5000)})
}
EOF

  write_file "$D/shell-trigger.ts" << 'EOF'
// 域 H：含依赖/版本相关问题的代码，诱导模型请求执行 shell 辅助分析。
// 预期 Analysis chain 中出现 shell 步骤（enable_shell: true 时）。
import {exec} from 'child_process'

export function runDiagnostic(userInput: string): Promise<string> {
  return new Promise((resolve, reject) => {
    // 危险：用户输入直接拼接进 shell 命令（命令注入）
    exec(`echo ${userInput} | grep -c "ok"`, (error, stdout) => {
      if (error) reject(error)
      else resolve(stdout.trim())
    })
  })
}
EOF

  hr
  echo "域 H 操作指引（需查看 GitHub Actions 运行日志确认）："
  echo "  H1 Web 搜索   : 提交 websearch-trigger.ts → Analysis chain / 日志含 web_search 步骤"
  echo "  H2 Shell 执行 : 提交 shell-trigger.ts → 日志含 shell 调用记录"
  echo "  H3 关闭 web   : 临时设 enable_web_search: false → 日志无 [web_search_debug]"
  echo "  H4 关闭 shell : 临时设 enable_shell: false → 日志无 shell 调用"
  echo ""
fi

# ---- 收尾 -------------------------------------------------------------------
echo "============================================================="
echo "  ✅ 测试点代码已生成到 $BASE/"
echo "============================================================="
echo ""
echo "通用执行流程（每个域都适用）："
echo "  1. git checkout <基准分支> && git pull"
echo "  2. git checkout -b test/<域>-\$(date +%m%d)"
echo "  3. 按各域指引复制/替换文件（域 D/F 需替换基线文件；域 B 需两次提交）"
echo "  4. git add -A && git commit && git push -u origin <分支>"
echo "  5. gh pr create --base <基准分支> ...（或在网页建 PR）"
echo "  6. 等 1~3 分钟，按指引与 scripts/TEST-POINTS.md 核对 Bot 行为"
echo ""
echo "需临时改 workflow 配置的测试点：A5 / C3 / D4 / D5 / F-截断 / G5 / G6 / G7 / H3 / H4"
echo "（测试完记得恢复 .github/workflows/ai-reviewer.yml）"
echo ""
echo "完整验证点与预期结果见: scripts/TEST-POINTS.md"
