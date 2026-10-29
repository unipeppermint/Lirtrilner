# 素材来源与复现记录

维修页最新修订 v4：新增障碍和金色机器人交付标识，源图及完整提示词保存在 `design/repair-v4`；目标、补给与棋盘复用同一组零件。圆形操作控件为 UIKit 原生绘制。详见 [整页核对记录](09-repair-visual-audit.md)。

零件最新修订：齿轮与电池已更新为 v3，源图、完整内置 imagegen 提示词和实际页面对比保存在 `design/parts-v3`。应用引用 `Lirtrilner-gear-v3`、`Lirtrilner-battery-v3`，移除旧设计的金边与做旧，使用接近原型的珊瑚红、薄荷绿及原生衬线罗马等级字。可用 `python3 tools/Lirtrilner-package-parts-v3.py` 重新打包。

当前版本：2026-10-29 视觉 v2。12 件玩具、工坊背景、齿轮、电池、木纹和应用图标已改为内置 imagegen 生成素材。完整提示词保存在 `design/visual-v2/prompts/manifest.json`，原始输出在 `design/visual-v2/source`，应用使用经过尺寸优化的 Asset Catalog 资源。详见 [视觉升级记录](08-visual-v2.md)。音频仍为本项目脚本合成，系统图标与字体仍由 Apple 框架提供。

## 历史记录：2026-10-28 程序化视觉 v1

以下表格和生成命令描述旧版；旧玩具、零件代码及图标已保存在 `design/visual-v1`，不是当前运行素材。不要运行旧图标脚本覆盖当前图标。

| 内容 | 源文件 | 最终使用方式 |
| --- | --- | --- |
| 12 件玩具：机器人、火车、音乐盒、飞机、小鸭、相机、汽车、小熊、小鼓手、木马、小狗、摩天轮 | `Lirtrilner/LirtrilnerToyView.swift` | 原创几何矢量插画，0～3 阶段绘制；同一代码用于工坊、详情、结算和收藏；背景与角色独立变换 |
| 工坊背景 | 同上 | 窗户、工具架、工作台和工具箱程序绘制；可缩放，无嵌入文本 |
| 棋盘与零件 | `Lirtrilner/LirtrilnerBoardView.swift`、`Lirtrilner/LirtrilnerPartView.swift` | 5×5 原生按钮、障碍、交付框、补给框；齿轮和电池独立绘制，I～IV 等级明确显示 |
| 应用图标 | `tools/Lirtrilner-generate-icon.swift` | `Assets.xcassets/AppIcon.appiconset/Lirtrilner-icon.png`，1024×1024 RGB，无 alpha；独立机器人构图 |
| 音乐和五类效果 | `tools/Lirtrilner-generate-audio.py` | `Lirtrilner-{music,move,merge,deliver,complete,fail}.wav`；自制正弦波叠加与包络，22,050 Hz 单声道 |
| 控件图标与字体 | Apple UIKit / SF Symbols / 系统字体 | 系统运行时调用，未打包外部字库 |
| 视觉参考 | `assets/Lirtrilner-Clockwork-prototype-v1.png` 及原提示词 | 既有 imagegen 设计参考，仅留在 docs，不进入应用资源，不作为运行截图 |
| 运行页面核验图 | `verification/iphone17pro`、`verification/iphone-se3` | 实际 UIKit 页面渲染，Debug 专用核验；不是外部生成图，也不是正式商店截图 |

复现命令（在项目根目录）：

```sh
python3 tools/Lirtrilner-generate-content.py
python3 tools/Lirtrilner-generate-audio.py
swift -module-cache-path /private/tmp/Lirtrilner-module-cache \
  tools/Lirtrilner-generate-icon.swift \
  Lirtrilner/Assets.xcassets/AppIcon.appiconset/Lirtrilner-icon.png
```

题库重新生成后必须运行 `bash tools/Lirtrilner-verify.sh`。正式资产不是占位图。最终素材权利声明、开发者署名与账号内容权利勾选仍由发布主体确认；本记录只说明本次产出过程。
