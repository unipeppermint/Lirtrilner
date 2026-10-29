# 视觉升级 v2

后续零件修订 v3：用户指出维修零件仍偏离原型，因此单独重做齿轮与电池，去掉厚金边、划痕和锈迹，调整圆角倒角、高光与衬线罗马等级字。[查看零件最新对比](../../design/parts-v3/preview.html)。两个尺寸各 54 个页面状态重新渲染，布局歧义计数为 0；Debug 和未签名 Release 构建日志在 `verification/parts-v3`。新归档为 `build-artifacts/Lirtrilner-1.0-parts-v3-unsigned.xcarchive`。

日期：2026-10-29。用户反馈旧版图片与图标过于简陋，与原型的精细玩具质感有明显差距。本次将几何矢量玩具替换为独立的立体玩具素材，并接入真实 UIKit 页面。

## 当前效果

[前后页面对比](../../design/visual-v2/preview.html) · [完整页面渲染](verification/index.html)

- 12 件玩具统一采用搪瓷、黄铜和温暖光照：机器人、火车、旋转木马音乐盒、飞机、小鸭、相机、汽车、小熊、小鼓手、木马、小狗、摩天轮。
- 工坊采用独立背景与透明角色叠加，保留原生维修进度、柔和投影和角色庆祝动画。
- 棋盘增加木质底板、立体齿轮与电池；I～IV 等级由原生文字显示。
- 应用图标改为机器人近景；按钮增加原生渐变、边缘高光与阴影。
- 每件玩具使用一张主体美术图，各维修阶段以原生状态标签与透明度区分，并非 36 张独立维修状态图。

## 素材与复现

使用内置 imagegen，以原型为风格参考，生成 17 项独立素材。没有把整张原型当作可交互页面。

| 内容 | 路径 |
| --- | --- |
| 完整生成提示词、透明背景标记与原始来源 | `design/visual-v2/prompts/manifest.json` |
| 保存的原始输出 | `design/visual-v2/source/Lirtrilner-*-v2.png` |
| 应用尺寸优化资源 | `Lirtrilner/Assets.xcassets` |
| 旧版玩具、零件代码与图标备份 | `design/visual-v1` |
| 素材导入脚本 | `tools/Lirtrilner-package-art.py`、`tools/Lirtrilner-import-art.swift` |

运行 `python3 tools/Lirtrilner-package-art.py` 可从保存的源图重新打包。玩具与零件保留透明通道；应用图标为 1024×1024 RGB 无 alpha；背景导出为 JPEG。图片生成不保证像素级复现，因此原始输出也已保存。来源记录说明制作过程，不代表版权或 App Store 审核保证。

## 验证结果

- Debug 模拟器构建成功；Release 未签名归档成功。仅有未依赖 AppIntents 的元数据提取提示。
- iPhone 17 Pro 与 iPhone SE 第三代、iOS 26.5，各渲染 54 个中英文页面状态，共 108 张，布局歧义计数均为 0。
- 人工查看玩具轮廓、工坊构图、结算、大小屏棋盘与按钮文字；修复了渐变背景遮挡按钮文字的问题。
- 规则 Core 和题库与此前通过 14 项测试、66 条参考解的版本哈希一致。本次视觉修改未重复运行规则测试。
- 新版 Release 应用文件逻辑大小约 17.35 MB，尚非商店下载体积。
- Bundle ID `com.ztmpa.Lirtrilner`、iOS 15.0 最低版本和 iPhone 目标保持一致。

归档：`build-artifacts/Lirtrilner-1.0-visual-v2-unsigned.xcarchive`。构建日志、哈希与配置在 `verification/visual-v2`。旧版归档独立保留。

上述为实际页面渲染检查，不包含触摸、真机、VoiceOver、最大字体或长时性能验收。未提交审核。公开隐私与支持网址等发布资料按用户要求待后续补齐，其他缺项见 [发布缺项](07-release-gaps.md)。
