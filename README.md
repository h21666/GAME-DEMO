# AI Interactive Character Simulator

这是一个 AI 虚拟角色互动 Demo，目前包含：

- FastAPI Backend
- Godot 2D Client 工程骨架

## 功能

Backend 已支持：

- 创建和查询 AI 虚拟角色
- 根据角色 personality、background、memory、对话历史生成回复
- 保存重要对话、用户偏好、关系状态等记忆
- 支持 OpenAI-compatible LLM API
- 没有配置 API Key 时，会返回本地开发模式回复，方便先跑通接口
- 文本默认走 DeepSeek
- 图片支持玩家自定义接入
- 角色视觉设定与固定动作图资产接口

Godot Client 已支持：

- 主菜单
- Backend 地址连接
- Provider 设置界面
- 创建角色
- 角色列表与角色资料显示
- Chat UI
- 调用 FastAPI 聊天接口
- 出租屋开场剧情
- AI 伴侣商店剧情节点
- 回家后解锁角色互动
- 模块化剧情 pack，方便添加 DLC

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

godot-client/
  project.godot
  assets/
    backgrounds/
  scenes/
    main.tscn
  scripts/
    story/
    main.gd
```

## Backend 运行方法

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

如果要调用真实文本模型，在 `.env` 中填入：

```env
DEEPSEEK_API_KEY=your_deepseek_key_here
DEEPSEEK_BASE_URL=https://api.deepseek.com
DEEPSEEK_MODEL=deepseek-v4-pro
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
- `GET /providers` 获取文本和图片 provider 设置
- `PUT /providers` 更新文本和图片 provider 设置
- `GET /health` 健康检查

## Godot Client

Godot 2D Client 已经补成可直接打开的工程骨架。

打开方式：

1. 安装 Godot 4.2 或更新版本。
2. 用 Godot 打开 `godot-client` 文件夹。
3. 打开主场景并运行。
4. 确认 Backend 在运行。

详细说明见：

- [godot-client/README.md](./godot-client/README.md)

## 旧版 Unity

`unity-client/` 现在作为旧骨架保留，主线不再继续在那边开发。

## Character Visual Identity

角色视觉系统会保存：

- 性别与成年年龄
- 画风
- 外貌描述
- 参考图片
- 主形象图片
- 动作图片资产

文本默认使用 DeepSeek。你可以通过 `PUT /providers` 保存自己的图片 API 配置，图片会保存在 Backend 的 `media/` 目录，并通过 `/media/...` 提供给 Godot Client。

当前默认行为：

- 文本：DeepSeek，没填 Key 时回退到本地开发回复
- 图片：玩家自行接入，没填 Key 时回退到本地占位图

如果你要省成本，建议优先使用 `action-pack/generate` 先批量生成固定动作，游戏内只切换已生成的图，不做每次即时生成。

## 剧情主线

Godot 当前基础流程：

```text
出租屋 -> 街道 -> AI 伴侣商店 -> 角色生成/配置 -> 回到出租屋 -> AI 互动
```

基础剧情数据在：

```text
godot-client/scripts/story/base_game_pack.gd
```

后续 DLC 可以新增独立剧情 pack，不需要把所有剧情继续堆进主界面脚本。
