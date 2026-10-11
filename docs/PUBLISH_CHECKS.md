# 发布副本验证（2026-10-11）

本记录来自实际执行，Windows / Godot 4.7.2 / NVIDIA RTX 3070 Ti Laptop GPU。

- 无缓存副本完成 Godot 编辑器资源导入；两个工程导入退出码均为 0。
- 旧规则 15,985 次断言；扩展 14 项；三战 874 次检查；策略模拟 7,961 次检查；真实 UI 三战 105 项；三分辨率视觉交互 139 项。
- 上述最终测试退出码为 0，日志未检出 ERROR、SCRIPT ERROR 或 WARNING。初次沙箱运行遇到用户日志／编辑器设置写入限制；允许本地引擎运行后重新执行，最终记录以重跑结果为准。
- 三种分辨率为 1280×720、1600×900、1920×1080。
- README 使用既有 2026-10-10 实际 GPU 渲染截图；本次逐张打开六张 PNG，确认非黑屏、非报错画面。
- 游戏运行脚本与数值未改变；公开副本排除缓存、输出、个人绝对路径诊断脚本及许可不明且未使用的旧坦克素材／场景。保留 .gd.uid 与导入设置。
- 六份既有 ZIP／MP4 均存在；四个 ZIP 均通过 CRC 校验。Windows 附件包含引擎、game.pck、启动脚本、Godot 与字体许可。
- 两份视频为实际游戏的自动化输入实录，非真人用户测试。坦克录像前两关获胜、第三关失败。
- 本次未重新导出或替换既有 Windows ZIP／MP4，也未进行跨设备试玩；既有便携包启动及录像验证见原测试记录。
- 发布前扫描未检出常见 GitHub token、私钥头、私人绝对路径或单个大于 100 MiB 的源文件；该扫描不是所有秘密类型的形式化证明。

运行方法示例（Godot 控制台可执行程序）：

```text
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/battle_rules_test.gd
godot --path . --script res://tests/campaign_ui_test.gd
godot --path . --script res://tests/visual_ui_test.gd
```

界面及碰撞测试需要图形环境；坦克流程验收使用隔离物理场景，不等同真人三关自然通关。
