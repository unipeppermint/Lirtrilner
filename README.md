# 发条修理铺 · Lirtrilner

Swift + UIKit 的离线玩具维修解谜游戏。36 个主线关卡、12 件三阶段玩具、30 题循环每日挑战，无广告、无内购、无远程依赖。

## 当前视觉版本

维修页整页统一 v4：障碍、交付标识、目标与补给预览、圆形操作按钮及木质背景已一并对照原型更新。[最新整页对比](design/repair-v4/preview.html) · [逐项核对记录](docs/release-v1/09-repair-visual-audit.md)。当前未签名归档为 `build-artifacts/Lirtrilner-1.0-repair-v4-unsigned.xcarchive`。

最新零件校正：维修棋盘的齿轮和电池已进一步按原型调整为珊瑚红与薄荷绿，移除厚金边和做旧，并改用衬线罗马等级字。[查看最新零件对比](design/parts-v3/preview.html)。源图与提示词在 `design/parts-v3`。

2026-10-29 已按原型更换 12 件玩具、工坊、棋盘零件与应用图标。使用内置 imagegen 生成独立素材，文字与操作仍由 UIKit 绘制。[视觉升级记录](docs/release-v1/08-visual-v2.md) · [实际页面对比](design/visual-v2/preview.html)。

## 运行

用 Xcode 打开 `Lirtrilner.xcodeproj`，选择 `Lirtrilner` Scheme 和 iPhone 模拟器后运行。实际 App Target 为 iOS 15.0 起、iPhone 竖屏，Bundle ID 保持 `com.ztmpa.Lirtrilner`。如需真机，使用账号持有者已有的正确签名配置；本次未设置或修改签名团队。

## 验证

```sh
bash tools/Lirtrilner-verify.sh
```

脚本运行共享 Core 的 Swift 测试、模拟器构建和**未签名** Release archive。脚本生成的未签名归档位于 `/private/tmp/Lirtrilner-1.0.xcarchive`；旧版副本保存在 `build-artifacts/Lirtrilner-1.0-unsigned.xcarchive`；视觉升级版归档见 `build-artifacts/Lirtrilner-1.0-visual-v2-unsigned.xcarchive`。它不等同于可上传或可分发包。

```sh
xcrun simctl list devices available
bash tools/Lirtrilner-render-audit.sh <已启动的模拟器UUID> <报告目录名>
```

渲染检查仅在 Debug 中存在，实例化实际页面并使用引擎验证过的状态，不模拟触摸，不修改玩家存档；Release 不包含该入口。它不能替代手势、屏幕阅读器、音频和性能实测。

## 代码结构

- `Lirtrilner/Core`：纯 Swift 确定性规则、关卡校验、参考路线与有界搜索、存档及日历映射。App 与根目录 Swift Package 共用同一份源文件。
- `Lirtrilner/Lirtrilner…swift`：纯代码 UIKit 页面、棋盘、原生零件等级、12 件立体玩具美术、音频服务。
- `Lirtrilner/Lirtrilner-levels.json`：全部正式范围题库，附参考解。
- `Tests/LirtrilnerCoreTests`：14 项规则和持久化测试。
- `tools`：可复现的内容、图标、原创音频生成脚本与构建脚本。

## 交付状态

见 [实施与验证报告](docs/release-v1/05-implementation.md)、[素材记录](docs/release-v1/06-assets.md)、[发布缺项](docs/release-v1/07-release-gaps.md) 和 [页面渲染目录](docs/release-v1/verification/index.html)。

本次已实现全部题库和主要页面并构建成功，尚未完成首版发布验收。没有连接真机；图形界面控制未获授权；5 人试玩、真实触摸及 VoiceOver、最低系统、长时性能、签名与上传校验尚待完成。用户已确认发行主体、地区与公开网址稍后补齐。未提交审核或公开发布。
