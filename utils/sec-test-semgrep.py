"""
sec-test-semgrep.py — 专攻 Semgrep p/default 规则集的测试 fixture

每个函数刻意触发一类 SAST 问题（与 OWASP Top 10 高度相关），
用于验证：
  - Semgrep 适配器装包成功并跑通
  - Finding 注入 LLM Prompt，AI 评论里能命名 Semgrep
  - 跨工具去重：与 ESLint/Biome 各管各的（Semgrep 跑的是 .py，互不重叠）
  - PR 摘要表里多一行 Semgrep <version>

各 bug 间隔 ≥ 5 行，避免被 ±3 变更行窗口聚簇。

⚠️ 不要在生产代码里复制这些反模式 —— 它们故意是漏洞。
"""

import os
import subprocess
import hashlib
import pickle
import yaml
from flask import request


# ────────────────────────────────────────────────────────────────────────
# Bug 1：shell=True 命令注入
#   - Semgrep: python.lang.security.audit.dangerous-system-call
#   - 用户传入字符串直接拼到 shell，典型 RCE
# ──────────────────────────────────────────────────────────────────────
def run_user_cmd(user_input: str) -> None:
    subprocess.call("echo " + user_input, shell=True)


# ────────────────────────────────────────────────────────────────────────
# Bug 2：硬编码的弱算法 MD5（用于密码 / 鉴权场景）
#   - Semgrep: python.lang.security.audit.weak-hashes-md5
# ──────────────────────────────────────────────────────────────────────
def password_hash(pw: str) -> str:
    return hashlib.md5(pw.encode()).hexdigest()


# ────────────────────────────────────────────────────────────────────────
# Bug 3：pickle.loads 反序列化用户输入
#   - Semgrep: python.lang.security.deserialization.avoid-pickle.avoid-pickle
#   - 任意代码执行的经典 sink
# ──────────────────────────────────────────────────────────────────────
def load_user_state(payload: bytes):
    return pickle.loads(payload)


# ────────────────────────────────────────────────────────────────────────
# Bug 4：yaml.load 不指定 SafeLoader
#   - Semgrep: python.lang.security.audit.dangerous-yaml-load
# ──────────────────────────────────────────────────────────────────────
def parse_config(raw: str):
    return yaml.load(raw)


# ────────────────────────────────────────────────────────────────────────
# Bug 5：eval(用户输入)
#   - Semgrep: python.lang.security.audit.eval-detected.eval-detected
# ──────────────────────────────────────────────────────────────────────
def compute_expression(expr: str):
    return eval(expr)


# ────────────────────────────────────────────────────────────────────────
# Bug 6：os.system 拼字符串（命令注入的另一面）
#   - Semgrep: python.lang.security.audit.dangerous-os-system
# ──────────────────────────────────────────────────────────────────────
def remove_user_file(filename: str) -> None:
    os.system("rm -rf " + filename)


# ────────────────────────────────────────────────────────────────────────
# Bug 7：Flask 路由里直接拼 SQL（SQL 注入）
#   - Semgrep: python.flask.security.audit.sqli (取决于规则版本，可能不全在 p/default)
# ──────────────────────────────────────────────────────────────────────
def get_user_by_id():
    user_id = request.args.get("id")
    query = "SELECT * FROM users WHERE id = " + user_id
    return query


# ────────────────────────────────────────────────────────────────────────
# Bug 8：硬编码密钥/凭据
#   - Semgrep: generic.secrets.security.detected-generic-api-key
#   - p/default 通常带 secrets 规则，能识别"看起来像 API key 的字符串"
# ──────────────────────────────────────────────────────────────────────
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"  # noqa


# ────────────────────────────────────────────────────────────────────────
# Bug 9：路径遍历（用户输入直接拼到 open 路径）
#   - Semgrep: python.lang.security.audit.path-traversal.open
# ──────────────────────────────────────────────────────────────────────
def read_user_file(filename: str) -> str:
    with open("/var/data/" + filename) as f:
        return f.read()
