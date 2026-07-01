# ai-reviewer SaaS 化：Webhook Server 模式调研

## 背景

当前 ai-reviewer 采用 GitHub Actions workflow 模式，每个接入项目需要：
- 手动添加 `.github/workflows/ai-reviewer.yml`
- 配置 3 个 secrets（APP_ID、APP_PRIVATE_KEY、OPENAI_API_KEY）
- 维护 action 参数

接入成本高，无法规模化推广。

---

## 目标模式：GitHub App + Webhook Server

参考 CodeRabbit 的实现路径，将"逻辑分散在用户仓库跑"改为"逻辑集中在服务器跑"。

用户侧接入成本降为：**组织级安装一次 GitHub App → 所有仓库自动生效**。

---

## 核心架构

```
用户安装 GitHub App
       ↓
GitHub 推送 webhook 事件到我们的服务器
(pull_request / pull_request_review_comment / issue_comment)
       ↓
服务器处理：获取 diff → 调用 LLM → 生成 review
       ↓
通过 GitHub API 回写 review comment
```

目标仓库里不需要任何文件，零侵入。

---

## 关键机制

### 1. 安装跳转与账号绑定

GitHub App 设置页配置 `Setup URL`，安装完成后 GitHub 强制跳转：

```
https://your-service.com/github/setup?installation_id=12345&setup_action=install
```

服务器在此端点完成：
- 接收并存储 `installation_id`
- 绑定到当前登录用户（需提前 OAuth 登录，或在此处触发 OAuth 流程）

### 2. 两个 URL 的分工

| 字段 | 时机 | 用途 |
|---|---|---|
| `Setup URL` | 安装完成后 | 绑定 installation 到账号 |
| `Callback URL` | OAuth 授权后 | 获取用户 GitHub identity |

### 3. 租户隔离

`installation_id` 是 GitHub 全局唯一的数字 ID，天然作为租户标识：

```
installations 表
  installation_id → account_id + plan + quota

accounts 表
  account_id → billing_status + plan_tier
```

每次 webhook 进来：
```
payload.installation.id → 查表 → 账号 → plan → 是否允许处理
```

### 4. GitHub API 调用凭证

两种 token，不要混淆：

| token | 签发方 | 用途 | 有效期 |
|---|---|---|---|
| App JWT | 自己用 private key 签 | 向 GitHub 证明 App 身份 | 10 分钟 |
| Installation Access Token | GitHub 签发 | 实际调用 GitHub API | 1 小时 |

生成 App JWT 需要两样东西，均来自 GitHub App 设置页：
- `APP_ID`：设置页直接显示的数字
- `PRIVATE_KEY`：设置页生成并下载的 `.pem` 文件

```javascript
const payload = {
  iat: Math.floor(Date.now() / 1000) - 60,
  exp: Math.floor(Date.now() / 1000) + 600,
  iss: APP_ID
}
const appJwt = jwt.sign(payload, privateKey, { algorithm: 'RS256' })

// 用 App JWT 换 Installation Access Token
POST https://api.github.com/app/installations/{installation_id}/access_tokens
Authorization: Bearer {appJwt}
```

这个逻辑等同于现在 workflow 里 `actions/create-github-app-token@v1` 做的事。

### 5. Webhook 安全验证

每条 webhook payload 带 `X-Hub-Signature-256` 签名，服务器必须验签防伪造：

```javascript
const sig = req.headers['x-hub-signature-256']
const expected = 'sha256=' + crypto
  .createHmac('sha256', WEBHOOK_SECRET)
  .update(req.rawBody)
  .digest('hex')
if (sig !== expected) return res.status(401).end()
```

---

## 与现有方案的对比

| | 现在（Actions） | SaaS Webhook Server |
|---|---|---|
| 计算在哪跑 | 用户的 GitHub Actions 配额 | 自己的服务器 |
| 密钥存在哪 | 每个仓库的 secrets | 服务器环境变量 |
| 用户接入 | 每仓库配置 workflow + secrets | 安装一次 App |
| 多租户隔离 | 无 | installation_id 天然隔离 |
| 计费/限流控制 | 无 | 查表限流 |
| 运维成本 | 低（GitHub 跑计算） | 需要维护服务器 |
| 私有化部署 | 容易 | 需要额外工作 |

---

## 仓库侧可选配置

用户不需要 workflow，但可以在仓库根目录放一个配置文件覆盖默认行为（对标 `.coderabbit.yaml`）：

```yaml
# .ai-reviewer.yaml
path_filters:
  - "**/*.ts"
  - "!node_modules/**"
review_simple_changes: false
```

服务器处理 webhook 时读取这个文件，合并到默认配置。

---

## 实施路径

1. 部署 webhook server，暴露公网 HTTPS 端点
2. 创建/更新 GitHub App，填入 Setup URL、Callback URL、Webhook URL
3. 实现 `/github/setup` 端点（账号绑定）
4. 实现 `/github/webhook` 端点（事件处理主逻辑）
5. 将现有 workflow 里的 action 逻辑（diff 获取、LLM 调用、comment 回写）移入服务器
6. 实现账号/计费/配额管理（可最小化：先只做免费配额限制）

---

## 参考

- CodeRabbit、Graphite、Mergify 均采用此模式
- GitHub Apps 文档：安装流程、webhook 事件格式、Installation Access Token 获取
