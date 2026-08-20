# AIGC Interactive Character Simulator Unity Client

这是旧版 Unity 前端骨架，主线已切换到 Godot。这个目录保留作参考：

- 主菜单
- 角色显示
- Chat UI
- API 调用

## 结构

```text
unity-client/
  Packages/
    manifest.json
  ProjectSettings/
    ProjectVersion.txt
    EditorBuildSettings.asset
    ProjectSettings.asset
  Assets/
    Scenes/
      Main.unity
    Editor/
      CharacterSimulatorProjectSetup.cs
    Scripts/
      CharacterSimulator/
        CharacterApiClient.cs
        CharacterModels.cs
        CharacterSimulatorBootstrap.cs
        JsonHelper.cs
        UiFactory.cs
```

## 使用方式

1. 打开 Unity Hub。
2. 点击 `Add` / `Add project from disk`。
3. 选择这个文件夹：`unity-client`。
4. 用 Unity 2022.3 LTS 或更新版本打开。
5. 打开场景：`Assets/Scenes/Main.unity`。
6. 确认 Backend 在运行，默认地址是 `http://127.0.0.1:8000`。
7. 点击 Play。

如果场景没有自动出现，可以在 Unity 顶部菜单点击：

```text
AIGC Simulator > Rebuild Main Scene
```

它会重新创建一个最小可运行场景，里面已经挂好启动脚本。

## 运行后的流程

- 在主菜单输入 Backend 地址
- 在 Provider Settings 填 DeepSeek 和图片 API 配置
- 点击 Connect
- 角色列表会从 FastAPI 读取
- 选中角色后进入聊天界面
- 发送消息会调用 `/characters/{id}/chat`
- 角色资料和记忆会从 Backend 拉取并显示

## 说明

- 这个版本不依赖额外 JSON 插件，直接使用 Unity 自带的 `JsonUtility`
- UI 是运行时动态生成的，不需要先手工搭复杂 Canvas
- API Key 输入框留空会保留后端已有配置，不会从接口明文读回
- 当前还不是最终游戏画面，它是可以运行的 Client 骨架
- 下一阶段建议做：角色生成流程、角色立绘显示、固定动作按钮、图片 API 调用界面
