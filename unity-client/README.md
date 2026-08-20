# AIGC Interactive Character Simulator Unity Client

这是第一版 Unity 2D Client，目标是把 FastAPI Backend 接进来，跑通：

- 主菜单
- 角色显示
- Chat UI
- API 调用

## 结构

```text
unity-client/
  Assets/
    Scripts/
      CharacterSimulator/
        CharacterApiClient.cs
        CharacterModels.cs
        CharacterSimulatorBootstrap.cs
        JsonHelper.cs
        UiFactory.cs
```

## 使用方式

1. 在 Unity 中创建一个新的 2D 项目，建议使用 2022.3 LTS 或更新版本。
2. 把 `unity-client/Assets/` 下的脚本复制到你的 Unity 工程 `Assets/` 目录。
3. 新建一个空场景，放一个空物体，挂上 `CharacterSimulatorBootstrap`。
4. 确认 Backend 在运行，默认地址是 `http://127.0.0.1:8000`。
5. 点击 Play。

## 运行后的流程

- 在主菜单输入 Backend 地址
- 点击 Connect
- 角色列表会从 FastAPI 读取
- 选中角色后进入聊天界面
- 发送消息会调用 `/characters/{id}/chat`
- 角色资料和记忆会从 Backend 拉取并显示

## 说明

- 这个版本不依赖额外 JSON 插件，直接使用 Unity 自带的 `JsonUtility`
- UI 是运行时动态生成的，不需要先手工搭复杂 Canvas
- 如果你想要下一阶段，我可以继续补：
  - 角色创建表单
  - 对话气泡美化
  - 记忆编辑
  - 场景化 Unity UI 预制体

