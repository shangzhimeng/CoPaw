# CoPaw 项目说明文档

## 一、项目概述

CoPaw（Co Personal Agent Workstation）是一个开源的**个人 AI 助手**，可以在本地或云端部署运行。它通过多种聊天应用（钉钉、飞书、QQ、Discord、iMessage、Telegram 等）与用户交互，支持定时任务、心跳摘要，并通过 **Skills（技能）** 扩展能力。

### 核心特性

- **多渠道接入**：支持钉钉、飞书、QQ、Discord、iMessage、Telegram、企业微信、Matrix 等多种聊天平台
- **本地优先**：所有数据和任务都在您的机器上运行，无需第三方托管
- **灵活扩展**：通过 Skills 系统扩展能力，内置 cron、PDF/Office 处理、新闻摘要、文件读取等
- **本地模型支持**：支持 llama.cpp、MLX、Ollama 等本地大模型，无需 API Key
- **云端模型兼容**：支持 DashScope、OpenAI、Gemini、DeepSeek、Kimi、MiniMax 等云端模型
- **MCP 协议**：支持 Model Context Protocol，动态发现和热插拔工具
- **多工作空间**：支持多工作空间架构和 Agent 选择器

---

## 二、技术架构

### 2.1 目录结构

```
src/copaw/
├── agents/                    # Agent 核心实现
│   ├── react_agent.py         # 主 Agent 类（继承 ReActAgent）
│   ├── skills/                # 内置技能
│   │   ├── cron/              # 定时任务
│   │   ├── pdf/               # PDF 处理
│   │   ├── docx/              # Word 文档处理
│   │   ├── xlsx/              # Excel 处理
│   │   ├── pptx/              # PowerPoint 处理
│   │   ├── news/              # 新闻摘要
│   │   ├── file_reader/       # 文件读取
│   │   └── browser_visible/   # 浏览器控制
│   ├── skills_manager.py      # 技能加载管理
│   ├── memory/                # 记忆管理（ReMe 集成）
│   └── tools/                 # 内置工具
│       ├── shell.py           # Shell 命令执行
│       ├── file_io.py         # 文件读写
│       ├── browser_control.py # 浏览器控制
│       └── ...
├── app/                       # FastAPI 应用
│   ├── _app.py                # 应用工厂
│   ├── channels/              # 聊天渠道实现
│   │   ├── base.py            # BaseChannel 抽象基类
│   │   ├── manager.py         # 渠道生命周期管理
│   │   ├── dingtalk/          # 钉钉渠道
│   │   ├── feishu/            # 飞书渠道
│   │   ├── qq/                # QQ 渠道
│   │   ├── discord_/          # Discord 渠道
│   │   ├── telegram/          # Telegram 渠道
│   │   └── ...
│   ├── routers/               # FastAPI 路由
│   ├── mcp/                   # MCP 客户端管理
│   └── workspace/             # 多工作空间支持
├── cli/                       # 命令行接口
│   ├── main.py                # 入口点
│   ├── init_cmd.py            # copaw init
│   ├── app_cmd.py             # copaw app
│   ├── channels_cmd.py        # copaw channels
│   └── ...
├── providers/                 # LLM 提供商集成
│   └── registry.py            # 提供商注册表
├── config/                    # 配置处理
├── security/                  # 安全模块
│   ├── tool_guard/            # 工具守卫
│   └── skill_scanner/         # 技能扫描器
└── local_models/              # 本地模型支持
```

### 2.2 核心组件

#### Agent（智能体）

`CoPawAgent` 是核心智能体类，继承自 `ReActAgent`，具备：

- **内置工具**：Shell 命令、文件操作、浏览器控制、时间获取等
- **动态技能加载**：从工作目录自动加载用户自定义技能
- **记忆管理**：与 ReMe 集成，支持长期记忆和自动压缩
- **安全拦截**：通过 `ToolGuardMixin` 实现工具调用安全检查

#### Channels（渠道）

所有聊天平台通过 `BaseChannel` 抽象类实现统一接口：

- 消息标准化为 `content_parts`（TextContent、ImageContent、FileContent 等）
- 通过 `AgentRequest` 传递给 Agent 处理
- `ChannelManager` 管理生命周期、消息队列和路由

内置渠道注册在 `channels/registry.py`，自定义渠道从工作目录的 `custom_channels/` 自动加载。

#### Skills（技能）

每个技能是一个目录，包含：

- **SKILL.md**：YAML 前言 + Markdown 格式的技能说明
- **references/**（可选）：参考文档
- **scripts/**（可选）：脚本或工具

内置技能位于 `agents/skills/`，用户技能从 `customized_skills/` 加载，运行时合并为 `active_skills`。

#### Providers（模型提供商）

支持多种 LLM 后端：

| 类型 | 提供商 |
|------|--------|
| 云端 API | DashScope、OpenAI、Gemini、DeepSeek、Kimi、MiniMax 等 |
| 本地运行 | Ollama、llama.cpp、MLX（Apple Silicon） |
| 自定义 | 任何 OpenAI 兼容 API |

提供商定义在 `providers/registry.py`，用户可通过 Console 或 `providers.json` 添加自定义提供商。

---

## 三、开发指南

### 3.1 环境准备

```bash
# 克隆仓库
git clone https://github.com/agentscope-ai/CoPaw.git
cd CoPaw

# 构建前端（必需）
cd console && npm ci && npm run build
cd ..

# 复制前端构建产物
mkdir -p src/copaw/console
cp -R console/dist/. src/copaw/console/

# 安装 Python 包（开发模式）
pip install -e ".[dev,full]"
```

### 3.2 开发命令

#### Python 后端

```bash
# 运行测试
pytest                              # 所有测试
pytest tests/unit/                  # 单元测试
pytest tests/integrated/            # 集成测试
pytest -m "not slow"                # 跳过慢测试
pytest tests/unit/providers/test_ollama_provider.py  # 单个测试文件

# 代码质量检查
pre-commit install                  # 安装 Git 钩子
pre-commit run --all-files         # 运行所有检查
```

#### 前端（Console）

```bash
cd console
npm ci                              # 安装依赖
npm run build                       # 生产构建
npm run dev                         # 开发服务器
npm run format                      # Prettier 格式化
```

#### 文档网站

```bash
cd website
pnpm install                        # 安装依赖
pnpm build                          # 构建静态站点
pnpm dev                            # 开发服务器
```

### 3.3 本地运行

```bash
# 初始化（使用默认配置）
copaw init --defaults

# 启动服务
copaw app

# 访问控制台
# 打开浏览器访问 http://127.0.0.1:8088
```

### 3.4 代码风格

- **Python**：Black（行宽 79）、flake8、mypy、pylint（通过 pre-commit）
- **TypeScript/React**：Prettier、ESLint
- **提交信息**：遵循 Conventional Commits 规范
  - `feat(scope): description` - 新功能
  - `fix(scope): description` - Bug 修复
  - `docs(scope): description` - 文档更新
  - `refactor(scope): description` - 代码重构

---

## 四、部署方式

### 4.1 pip 安装

```bash
pip install copaw
copaw init --defaults
copaw app
```

### 4.2 脚本安装（推荐）

**macOS / Linux：**
```bash
curl -fsSL https://copaw.agentscope.io/install.sh | bash
```

**Windows（PowerShell）：**
```powershell
irm https://copaw.agentscope.io/install.ps1 | iex
```

### 4.3 Docker 部署

```bash
docker pull agentscope/copaw:latest
docker run -p 127.0.0.1:8088:8088 \
  -v copaw-data:/app/working \
  -v copaw-secrets:/app/working.secret \
  agentscope/copaw:latest
```

### 4.4 桌面应用

从 [GitHub Releases](https://github.com/agentscope-ai/CoPaw/releases) 下载：
- Windows: `CoPaw-Setup-<version>.exe`
- macOS: `CoPaw-<version>-macOS.zip`

---

## 五、配置说明

### 5.1 工作目录

默认位于 `~/.copaw/`，包含：

```
~/.copaw/
├── agent.json          # Agent 主配置
├── providers.json      # LLM 提供商设置
├── env.json            # 环境变量
├── customized_skills/  # 用户自定义技能
├── custom_channels/    # 用户自定义渠道
└── memory/             # 记忆存储
```

### 5.2 API Key 配置

**方式一：Console 配置（推荐）**
1. 访问 http://127.0.0.1:8088
2. 进入 **设置 → 模型**
3. 选择提供商，输入 API Key

**方式二：环境变量**
```bash
# DashScope
export DASHSCOPE_API_KEY=your_key

# OpenAI
export OPENAI_API_KEY=your_key
```

### 5.3 本地模型

无需 API Key，支持：

| 后端 | 适用平台 | 安装方式 |
|------|---------|---------|
| llama.cpp | 跨平台 | `pip install 'copaw[llamacpp]'` |
| MLX | Apple Silicon | `pip install 'copaw[mlx]'` |
| Ollama | 跨平台（需服务） | `pip install 'copaw[ollama]'` |

---

## 六、扩展开发

### 6.1 添加新渠道

1. 在 `src/copaw/app/channels/` 创建新目录
2. 实现 `BaseChannel` 子类：

```python
from copaw.app.channels.base import BaseChannel

class MyChannel(BaseChannel):
    channel = "my_channel"  # 唯一渠道标识

    def __init__(self, process, **kwargs):
        super().__init__(process, **kwargs)
        # 初始化代码

    async def consume_one(self, payload):
        # 处理消息，调用 self._process()
        pass
```

3. 在 `registry.py` 注册（内置渠道）或放入 `custom_channels/`（用户渠道）

### 6.2 添加新技能

在 `customized_skills/my_skill/` 创建目录：

```
customized_skills/my_skill/
├── SKILL.md           # 必需
└── references/        # 可选
```

**SKILL.md 示例：**

```yaml
---
name: my_skill
description: "Use this skill when user wants to [功能描述]. Trigger when user mentions: [触发关键词]"
---

# My Skill

详细的使用说明...
```

### 6.3 添加新模型提供商

**自定义提供商（无需改代码）：**
通过 Console 或 `providers.json` 添加任何 OpenAI 兼容 API。

**内置提供商（代码贡献）：**
1. 在 `providers/registry.py` 添加 `ProviderDefinition`
2. 如需新协议，实现 ChatModel 子类
3. 更新文档

---

## 七、CLI 命令参考

```bash
copaw init              # 初始化工作目录
copaw app               # 启动服务器
copaw channels          # 管理聊天渠道
copaw models            # 配置 LLM 提供商
copaw skills            # 管理技能
copaw cron              # 管理定时任务
copaw update            # 更新 CoPaw
copaw shutdown          # 优雅关闭
copaw uninstall         # 卸载
```

---

## 八、相关链接

- **官方文档**：https://copaw.agentscope.io/
- **GitHub 仓库**：https://github.com/agentscope-ai/CoPaw
- **问题反馈**：https://github.com/agentscope-ai/CoPaw/issues
- **Discord 社区**：https://discord.gg/eYMpfnkG8h
- **许可证**：Apache License 2.0