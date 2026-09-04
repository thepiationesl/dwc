# GitHub Actions 配置说明

> dwc 仓库的 CI / 自动化 pipeline 依赖以下 GitHub 配置。缺一个就跑不全。

---

## ⚙️ 必需的 Secrets

进 **Settings → Secrets and variables → Actions → New repository secret** 配下面两个:

| Secret 名 | 说明 | 示例 |
|---|---|---|
| `KILOCODE_BASE_URL` | Kilocode-compatible OpenAI endpoint 根 URL(**不带 `/chat/completions`**)| `https://orc.ntbsd.eu.org/custom-kaig/api/gateway/v1` |
| `KILOCODE_API_KEY` | Kilocode Bearer token | `klc_...` 或你在 Kilocode 拿的 token |

没设这两个 → 涉及 LLM 的 step 静默跳过(workflow 不失败),其他 step 正常跑。

---

## 🚦 3 个 workflows 概览

| 文件 | 触发 | 干啥 | 需要 secrets |
|---|---|---|---|
| `.github/workflows/manual-run.yml` | 手动 `workflow_dispatch` | 13 镜像 × 4 mode(test/build/lint/audit) | 不需要 |
| `.github/workflows/auto-test-fix.yml` | push / PR | 静态检查 + jump/lite/browser build + smoke;失败时 sed 自动修复并 commit | **KILOCODE_*** 用于 LLM commit enrich |
| `.github/workflows/code-audit.yml` | 每周一 09:00 UTC + 手动 | inventory + shell lint + docs/code drift + env drift + secret scan + (有 findings)开 issue | **KILOCODE_*** 用于 LLM summary |

---

## 📋 设置流程(一次性)

1. 进 https://github.com/thepiationesl/dwc/settings/secrets/actions
2. `New repository secret` 两次:
   - `KILOCODE_BASE_URL` = 你的 base URL
   - `KILOCODE_API_KEY` = 你的 API key
3. 等 5 分钟,GitHub 会校验
4. 跑 `Actions → Manual Run → Run workflow → image=jump, mode=test` 验证 pipeline 跑通

---

## 🧪 Kilocode LLM 集成细节**

两个 workflow 都用 `kilo-auto/free` 路由的免费模型(steps 自动 wrap curl + jq):

```bash
curl -fsS "$KILOCODE_BASE_URL/chat/completions" \
  -H "Authorization: Bearer $KILOCODE_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -nc --arg p "$PROMPT" '{model:"kilo-auto/free",messages:[{role:"user",content:$p}],temperature:0.3,max_tokens:N}')"
```

**要求**(OpenAI Chat Completions 标准):
- endpoint 必须支持 `POST /chat/completions`
- Body 字段:`{model, messages:[{role,content}], max_tokens?, stream?`

Kilocode 默认 model `kilo-auto/free` 路由到 `stepfun/step-3.7-flash`(我跑过 200 OK)。

---

## 🧰 手动跑 pipeline**(无需 secrets)**

`Actions → Manual Run → Run workflow`:
- **mode=test**: build 单镜像 + 容器内 smoke(`echo OK + ls dwc-*`)
- **mode=build**: build 单镜像(空=全部 Alpine/Debian 跳过 Kali)
- **mode=lint**: shellcheck 全脚本(可能没装 shellcheck 静默通过)
- **mode=audit**: secrets 扫 + docs port 漂移检测

---

## 🔁 Auto-fix 行为说明

`auto-test-fix.yml` 失败时会**自动 sed + commit + push**:
- `alpine:latest` → `alpine:3.24`
- `10022` → `2222`、 `5999` → `5901`、 `10089` → `3389`(只 docs)

推上去后会**重新触发 workflow**,如果还是失败就再来一次。**循环到稳态**(3 次 retries 默认)。

---

## 🛡 安全注意

- 不要 commit 真实 Kilocode token,只用 GitHub Secrets
- `KILOCODE_API_KEY` 通过 `secrets.*` 注入,**不进 workflow logs**(GitHub 自动 redact)
- `code-audit.yml` 的 secret scan **不含** Kilocode token 模式,因为那不是 AWS/GitHub 风格

---

## 🔗 相关链接

- GitHub Secrets 文档: https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions
- Kilocode: https://kilocode.ai (或你的自定义 proxy URL)
- Repo Actions 页: https://github.com/thepiationesl/dwc/actions