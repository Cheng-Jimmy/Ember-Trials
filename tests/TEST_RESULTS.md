# 本轮实际验证（2026-10-10）

Godot 4.7.2，Windows，RTX 3070 Ti Laptop GPU，D3D12 Mobile。

phase_check 通过；battle_rules_test 15,985 次断言；extension_rules_test 14 项；campaign_test 874 次检查；balance_test 7,961 次检查、120 次三战模拟；ui_smoke 33 项；campaign_ui_test 105 项真实 Viewport 输入检查。

两条路线经真实卡牌、按钮输入完成三战、两次奖励、最终结算与重开。图形测试检查 1600×900、1920×1080、1280×720。便携包使用包内引擎验证启动、进入战斗、返回菜单和实际 GPU 渲染，退出码 0。最终 outputs 日志无 ERROR/WARNING。

防守路线 60/60 通关、16.75 总回合、20.25 最终生命；灼烧 59/60 通关、12.05 总回合、11.78 最终生命。统计含失败，失败生命为 0。固定策略读取真实敌人意图数值，因此不能当作真人胜率。

日志和截图位于 outputs，CSV 同时在 outputs/balance.csv 与 tests/artifacts/balance.csv。没有执行跨机器、移动端或真人手动通关。
