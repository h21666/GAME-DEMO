# AIGC Interactive Character Simulator Godot Client

这是当前前端主线，已经加入“出租屋 -> 街道 -> AI 伴侣商店 -> 回家互动”的基础剧情流程。开场先看剧情，再进入商店生成角色，最后回到出租屋开始互动。

## 当前功能

- 游戏风格主菜单
- 出租屋开场背景
- 弹出式剧情对话
- 街道过渡章节
- AI 伴侣商店背景
- 角色生成与配置入口
- 角色列表和角色资料
- 回家后开启 Chat UI
- FastAPI API 调用
- 模块化剧情 pack

## 结构

```text
godot-client/
  project.godot
  assets/
    backgrounds/
      home.png
      aic_shop.png
  scenes/
    main.tscn
  scripts/
    main.gd
    story/
      story_pack_base.gd
      base_game_pack.gd
```

## 打开方式

1. 安装 Godot 4.2 或更新版本。
2. 用 Godot 打开 `godot-client` 文件夹。
3. 运行主场景。
4. 确认 Backend 在运行，默认地址是 `http://127.0.0.1:8000`。

## 基础剧情流程

1. 出租屋：弹出对话介绍主角和目标。
2. 街道：显示出门前往商店的过渡对白。
3. AI 伴侣商店：开启角色创建和 API 配置。
4. 选择角色：创建或选择 AI 伴侣。
5. 回到出租屋：确认带回角色。
6. Chat：开始和生成的 AI 角色互动。

## 剧情模块

基础剧情在：

```text
scripts/story/base_game_pack.gd
```

后续 DLC 可以新增自己的剧情 pack，按照 `StoryPackBase` 提供章节数据，再由主场景加载。每个章节可以独立配置：

- 背景图
- 标题
- 说话者
- 对话文本
- 是否显示游戏功能
- 章节结束后的按钮文字
- 进入哪个功能页面

## 素材

当前使用：

- `assets/backgrounds/home.png`：主角出租屋
- `assets/backgrounds/aic_shop.png`：AI 伴侣商店

图片来自本次提供的参考素材，已复制进工程，不依赖 Downloads 文件夹。
