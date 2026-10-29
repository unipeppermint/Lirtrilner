# 实施与验证报告

日期：2026-10-28（Asia/Shanghai）。版本：1.0（1）。本报告描述实际实现与证据，不表示已完成发布验收或获准上架。

## 已实施

- Swift + UIKit、纯代码入口，移除未使用的 Main Storyboard 和默认控制器，保留奶油色 LaunchScreen。
- 5×5 局部行列移动、障碍分段、两种零件 I～IV、单次合并限制、精确手动交付、零步交付、堵塞补给重试、终局判断。
- 引擎返回确定性的位移事件。棋盘使用独立零件层及 200 ms 位移、120 ms 合并反馈；动画输入锁定，后台中断与撤销会清理旧动画。
- 最近 100 次事务撤销、重开、独立主线/每日存档、原子文件替换、上一份备份、坏文件隔离保留、保存失败提示和重试。
- 工坊、36 关选择、阶段结算、12 件玩具收藏及故事详情、每日挑战和历史、规则、设置、离线隐私与帮助。
- 每件玩具对应连续 3 关。前两阶段显示维修进展，第三阶段才增加收藏；复玩只改进最佳步数。全部 36 关后不显示不存在的下一关。
- 30 道每日题库使用本地公历与固定锚点循环；保存当天 ID，昨天未完成局可继续；替换旧每日局前确认。
- 提示优先匹配已验证参考路线的当前状态；否则后台搜索最多 12,000 节点/450 ms，未知返回明确措辞。取消任务和 revision/generation 检查阻止旧建议显示。
- 中英即时语言切换、系统圆角字体、可滚动大字页面、44 pt 以上常用操作区、形状+等级识别、25 格 VoiceOver 自定义四方向操作、减弱动态效果分支。
- 12 件原创程序化矢量玩具、工作台插画、独立齿轮与电池绘制、1024 px 无 alpha 图标、原创合成背景音乐及五类音效。没有第三方依赖。

## 验证结果

| 项目 | 已获得证据 | 范围和限制 |
| --- | --- | --- |
| Core 测试 | `verification/core-tests.log`，14 项，0 失败 | macOS 上运行同一份 App Core 源码，不等于 iOS 触摸测试 |
| 关卡 | 36 主线 + 30 每日逐步参考解全部通过；66 个布局/订单/补给组合唯一 | 每步有效、状态不变量、最终胜利、撤销及重放确定性；参考解不保证最优 |
| 合并/交付 | 四方向、障碍、IV 上限、异类不合并、重复订单顺序、错误交付、最后一步交付 | 自动测试 |
| 补给/撤销 | 堵塞等待、交付重试、每指令最多一枚、耗尽、无效动作不推进、完整撤销 | 自动测试 |
| 提示 | 66 条初始提示重放、非参考位置完整路线、预算未知、取消 | 旧任务通过 UI generation 与 revision 拦截；UI 快速切换尚未触摸实测 |
| 存档 | 双模式及历史 Codable 往返、顺序写入拒绝旧 revision、备份恢复、损坏隔离、写入失败、重置 | 初版没有已发布旧 schema；未知 schema 拒绝并尝试备份，不虚构迁移结果 |
| Debug 构建 | `verification/simulator-build.log`，BUILD SUCCEEDED | arm64/x86_64 模拟器构建；已安装启动 |
| Release 归档 | `verification/release-archive.log`，ARCHIVE SUCCEEDED | generic iOS arm64，**未签名**，不能直接上传或真机安装 |
| 大屏渲染 | iPhone 17 Pro / iOS 26.5 / 402×874 pt | 52 个实际页面状态，中英各 26；布局歧义检测为 0 |
| 小屏渲染 | iPhone SE 第三代 / iOS 26.5 / 375×667 pt | 同一套 52 个页面状态；布局歧义检测为 0，基础字号完整棋盘与操作栏可同时显示 |
| Release 启动 | `verification/release-simulator-build.log` 与 `release-launch-se3.png` | 最终 Release 模拟器包正常安装启动，无 Debug 渲染入口 |
| 真实首次启动 | `verification/first-launch.png` | 早期构建截图；发现底部操作挤出后已修正，以后续渲染图为准 |
| 真机 | `xcrun devicectl list devices` 返回 No devices found | **未测试** |
| UI 图形控制 | 模拟器窗口控制未获授权 | 没有模拟手指事件；不宣称完成触摸、拖动、回退手势或 VoiceOver 实测 |

渲染核验入口仅编译进 Debug。它直接实例化生产页面，用同一规则引擎生成合法进度，截图与布局检查期间不持久化测试进度。截图没有系统状态栏，因此属于开发核验材料，不能直接当作最终 App Store 截图。并非独立试玩，也没有覆盖每个滚动页面的所有离屏区域。

图像可从 [渲染目录](verification/index.html) 浏览。逐题数值见 [关卡索引](verification/content-index.md)。

## 最终有效工程设置

证据：`verification/release-settings.log`。

- Bundle ID：`com.ztmpa.Lirtrilner`，未改动。
- App Target：iOS 15.0、iPhone（TARGETED_DEVICE_FAMILY=1）、竖屏。
- Project 层原有 26.5 保留，App Target 最终有效值为 15.0。
- 签名方式保留 Automatic。原工程没有配置 DEVELOPMENT_TEAM；未添加或修改团队。
- Swift 5 语言模式、默认 MainActor 保留。Core 类型显式 nonisolated，后台提示不在主线程求解。
- Xcode 26.6 / build 17F113，iOS SDK/可用模拟器 runtime 26.5。

## 实现取舍及尚待验收

- 素材采用可缩放原创矢量风格，保持奶油、珊瑚红、薄荷绿、黄铜和玩具修理铺主题。没有使用三屏原型整图；当前画风不是原型的拟真 3D 渲染。
- 图像阶段由同一角色绘制函数和维修部件状态表达，不存 48 份重复位图；图标使用独立源脚本。背景音乐与提示音为自制合成旋律。
- Core 用项目根部 Swift Package 测试同一组源码，不添加本地 Package 链接和新 App Target，避免改变原构建配置。
- 偏好与进度一起存储 Codable 文件，没有使用 UserDefaults，所以未声明该 API 的理由代码。隐私清单中的追踪、数据收集、Required Reason API 列表为空；最终仍应检查签名分发包与 App Store 标签。
- 当前题库为确定性编排并变换布局的正式范围内容。步数参考解为 1～8 次滑动，预算为 3～12；尚未通过 5 人独立试玩。2～5 分钟单局目标、后期难度与内容吸引力不能据自动测试宣布达标。
- iOS 15 真机/模拟器、当前发布时最新稳定系统、触觉/静音/打断、VoiceOver、最大动态字体、30 分钟持续运行与 Instruments 性能尚未验证。

以上尚未验收项目是发布前门槛。具体外部依赖见 [发布缺项](07-release-gaps.md)。

## 本地交付物

未签名归档已复制到项目的 `build-artifacts/Lirtrilner-1.0-unsigned.xcarchive`。App 文件逻辑总大小 1,297,952 字节（约 1.30 MB），不代表压缩 IPA 或商店下载大小。`verification/build-manifest.json` 记录 Bundle ID、最低系统、设备族、14 项测试、104 个渲染状态以及最终二进制/源文件 SHA-256。

可复现命令为项目根目录的 `bash tools/Lirtrilner-verify.sh`；渲染核验使用 `bash tools/Lirtrilner-render-audit.sh <已启动模拟器UUID> <输出目录名>`。脚本不上传或操作 App Store Connect。
