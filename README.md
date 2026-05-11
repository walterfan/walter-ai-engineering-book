# AI 时代的软件工程：从敏捷开发到氛围编程

> AI-Era Software Engineering: From Agile Development to Vibe Coding

📖 **在线阅读**：<https://walterfan.github.io/walter-ai-engineering-book/>

本书系统性地探讨了 AI 时代软件工程的深刻变革。从传统的瀑布模型到敏捷开发，再到如今的
AI 辅助编程和氛围编程（Vibe Coding），软件开发的方法论、工具链和工程师的角色都在经历前所未有的转变。

本书不仅回顾历史、分析现状，更着眼未来，帮助每一位软件工程师在 AI 浪潮中找到自己的位置，顺势而为。

---

## 目录结构

- **第一部分** 回顾与反思 — 软件工程的前世今生（Ch. 1–5）
- **第二部分** 变革之风 — AI 如何重塑软件开发（Ch. 6–10）
- **第三部分** 氛围编程 — 新范式的崛起（Ch. 11–15）
- **第四部分** AI Agent 开发深度解析（Ch. 16–22）
- **第五部分** 工程师的自我进化（Ch. 23–27）
- **第六部分** 展望未来（Ch. 28–30）
- **附录 A** 实战项目：AI Coach（虚拟学习教练，源码在 [`examples/ai-coach/`](examples/ai-coach/)）
- **附录 B** 实战项目：AI Editor（虚拟书稿编辑，源码在 [`examples/ai-editor/`](examples/ai-editor/)）

---

## 本地构建

本书使用 [Sphinx](https://www.sphinx-doc.org/) + [MyST-Parser](https://myst-parser.readthedocs.io/)，
依赖通过 [Poetry](https://python-poetry.org/) 管理。Python 虚拟环境位于项目根目录的 `./.venv`。

### 一次性环境准备

```bash
# 安装 Poetry（如未安装）
pipx install poetry

# 安装本书的构建依赖到 ./.venv
make install
```

### 常用命令

| 命令 | 作用 |
| --- | --- |
| `make html` | 生成 HTML 到 `build/html/` |
| `make serve` | 在 <http://127.0.0.1:7800/> 静态托管 `build/html/` |
| `make livehtml` | 实时预览，文件改动自动重建 |
| `make pdf` | 生成 PDF（需要 `xelatex` + `xeCJK`） |
| `make clean` | 清空 `build/` 输出 |
| `make lint` | 运行链接检查（`sphinx linkcheck`） |
| `make check` | `lint` + `html`，CI 入口 |
| `make publish` | 构建并强制推送 `build/html/` 到 `gh-pages` 分支 |
| `make publish-status` | 打印 GitHub Pages 配置和已部署站点的 URL |
| `make help` | 列出所有可用 target |

完整 target 列表运行 `make help`。所有命令默认都通过 `poetry run` 包装，
也支持先 `poetry shell` 进入虚拟环境后直接运行。

---

## 发布到 GitHub Pages

发布走 **gh-pages 分支** 模式（避免 Actions 部署权限问题）：

1. 在 GitHub 仓库 **Settings → Pages** 把 Source 设为
   *Deploy from a branch*，Branch 选 `gh-pages` / `(root)`（首次发布前完成此步）。
2. 本地运行：

   ```bash
   make publish
   ```

   该 target 会先 `make html`，然后把 `build/html/` 强制推送到远端的
   `gh-pages` 分支。`.nojekyll` 自动添加，确保以下划线开头的资源
   （如 `_static/`）能被正确服务。
3. 几十秒后访问 <https://walterfan.github.io/walter-ai-engineering-book/>。

CI（`.github/workflows/publish.yml`）只做构建验证，不做部署 —— 在每次推送
`master` 时跑一次 `make install && make html`，并把 `build/html/` 上传为
工作流 artefact，方便对照本地构建是否一致。

---

## 实战项目示例

本书附录的两个全栈项目可以独立运行：

### AI Coach — 基于 RAG + Agent 的个人学习督导系统
源码：[`examples/ai-coach/`](examples/ai-coach/)
技术栈：FastAPI + LangChain + ChromaDB + Vue 3 + Tailwind CSS
快速启动：`cd examples/ai-coach && docker-compose up`

### AI Editor — 多 Agent 协作的书稿编辑系统
源码：[`examples/ai-editor/`](examples/ai-editor/)
技术栈：FastAPI + 多 Agent + Diff 可视化 + Vue 3
快速启动：`cd examples/ai-editor && docker-compose up`

---

## 项目结构

```
walter-ai-engineering-book/
├── source/                 # Sphinx 源 (MyST Markdown)
│   ├── conf.py             # Sphinx 配置
│   ├── index.md            # 目录入口
│   ├── chapter01.md ... chapter30.md
│   └── appendix_a.md, appendix_b.md
├── examples/
│   ├── ai-coach/           # 附录 A 项目源码
│   └── ai-editor/          # 附录 B 项目源码
├── build/                  # 构建产物（git ignored）
├── pyproject.toml          # Poetry 元数据 + 依赖
├── poetry.lock             # 依赖锁
├── poetry.toml             # 虚拟环境配置（in-project）
├── Makefile                # 构建 / 预览 / 发布入口
└── .github/workflows/
    └── publish.yml         # CI 验证（无部署）
```

---

## 贡献

发现错别字、内容错误或想要建议改进？欢迎提交 [Issue](https://github.com/walterfan/walter-ai-engineering-book/issues)
或 [Pull Request](https://github.com/walterfan/walter-ai-engineering-book/pulls)。

---

## 许可（双重许可 / Dual License）

本仓库采用双重许可，请按内容类型对照适用：

| 内容范围 | 许可 | 文件 |
| --- | --- | --- |
| **书稿内容** —— `source/` 下的所有 Markdown / 插图、`README.md`、构建产物（`build/`、已发布的 HTML/PDF） | [Creative Commons BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) | [`LICENSE`](LICENSE) |
| **示例代码** —— `examples/` 下的所有源代码（AI Coach、AI Editor 等附录项目） | [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) | [`LICENSE-CODE`](LICENSE-CODE) |

**书稿（CC BY-NC-ND 4.0）的关键约束**：
- ✅ 允许：自由阅读、非商业目的的复制和传播，前提是注明作者并附上本仓库链接
- ❌ 禁止：商业用途；以任何形式发布修改版（翻译、改编、二次创作均不允许公开分发）
- 如需商业授权或衍生授权，请通过 [Issue](https://github.com/walterfan/walter-ai-engineering-book/issues) 联系作者

**示例代码（Apache-2.0）**：可自由用于商业和非商业项目，需保留版权声明和许可文本。

Copyright © 2026 **Walter Fan**

