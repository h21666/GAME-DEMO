# AIGC Interactive Character Simulator Backend

第一阶段只实现 Backend：角色系统、聊天接口、记忆系统，以及基于 SQLite 的本地存储。

## 功能

- 创建和查询 AI 虚拟角色
- 根据角色 personality、background、memory、对话历史生成回复
- 保存重要对话、用户偏好、关系状态等记忆
- 支持 OpenAI-compatible LLM API
- 没有配置 API Key 时，会返回本地开发模式回复，方便先跑通接口

## 项目结构

```text
backend/
  app/
    __init__.py
    config.py
    database.py
    llm.py
    main.py
    schemas.py
  .env.example
  requirements.txt
```

## 运行方法

进入后端目录：

```bash
cd backend
```

创建虚拟环境并安装依赖：

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

复制环境变量文件：

```bash
copy .env.example .env
```

如果要调用真实 LLM，在 `.env` 中填入：

```env
OPENAI_API_KEY=your_api_key_here
LLM_MODEL=gpt-4o-mini
```

启动服务：

```bash
uvicorn app.main:app --reload
```

接口文档：

```text
http://127.0.0.1:8000/docs
```

## 示例请求

创建角色：

```bash
curl -X POST http://127.0.0.1:8000/characters ^
  -H "Content-Type: application/json" ^
  -d "{\"name\":\"Mira\",\"personality\":\"warm, curious, playful\",\"background\":\"A virtual guide from a near-future city.\",\"memory\":\"The user is building an AI character demo.\"}"
```

聊天：

```bash
curl -X POST http://127.0.0.1:8000/characters/1/chat ^
  -H "Content-Type: application/json" ^
  -d "{\"message\":\"Hi Mira, what do you remember about me?\"}"
```

添加记忆：

```bash
curl -X POST http://127.0.0.1:8000/characters/1/memories ^
  -H "Content-Type: application/json" ^
  -d "{\"type\":\"user_preference\",\"content\":\"The user prefers concise technical explanations.\",\"importance\":4}"
```

## API

- `POST /characters` 创建角色
- `GET /characters` 获取角色列表
- `GET /characters/{character_id}` 获取角色详情
- `POST /characters/{character_id}/chat` 发送消息并获取角色回复
- `GET /characters/{character_id}/messages` 获取对话历史
- `POST /characters/{character_id}/memories` 添加角色记忆
- `GET /characters/{character_id}/memories` 获取角色记忆
- `POST /characters/{character_id}/visual-profile` 保存角色视觉设定
- `GET /characters/{character_id}/visual-profile` 获取角色视觉设定
- `POST /characters/{character_id}/visual-profile/generate` 上传参考图并生成主形象
- `POST /characters/{character_id}/actions` 基于主形象生成动作图
- `GET /action-templates` 获取固定动作模板
- `POST /characters/{character_id}/action-pack/generate` 一次生成固定动作包
- `GET /characters/{character_id}/actions` 获取动作资产
- `GET /health` 健康检查

## Unity Client

Unity 2D Client 结构在 `unity-client/`，说明见：

- [unity-client/README.md](./unity-client/README.md)

## Character Visual Identity

角色视觉系统会保存：

- 性别与成年年龄
- 画风
- 外貌描述
- 参考图片
- 主形象图片
- 动作图片资产

配置 `OPENAI_API_KEY` 后，可以通过 `visual-profile/generate` 生成主形象，再通过 `actions` 生成“喝茶”“看书”等动作。图片会保存在 Backend 的 `media/` 目录，并通过 `/media/...` 提供给 Unity。

如果你要省成本，建议优先使用 `action-pack/generate` 先批量生成固定动作，游戏内只切换已生成的图，不做每次即时生成。
