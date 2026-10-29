# 发条修理铺技术方案

采用 Swift + UIKit 原生开发，规则、状态和渲染分离。棋盘规模固定为 25 格，使用二维美术与系统动画实现玩具修理铺效果。首版无需第三方运行依赖、账号或业务服务器。

## 工程初始基线（实施前）

实施前的 Lirtrilner 工程包含 AppDelegate、SceneDelegate、默认 ViewController 和 Storyboard，尚无玩法代码。App Target 的 Debug 与 Release 均设置 iOS 15.0、iPhone 单设备族和竖屏；Project 层存在 iOS 26.5 默认值，构建时应核对 Target 的最终有效设置。

当前 Swift 语言设置为 5.0，默认 actor 隔离为 MainActor。实现时保留既有 App 构建设置，不以升级语言模式作为前置步骤。Bundle ID 为 com.ztmpa.Lirtrilner；不改动 Bundle ID、签名团队或发布配置。

页面改用纯代码创建，在实现阶段配套调整 SceneDelegate 和 Main Storyboard 的入口引用，保留 LaunchScreen。防止代码根页面与 Storyboard 同时初始化。

当前实现与基线的对应关系、共享 Core 测试方式及已验证结果见 [实施报告](05-implementation.md)。本文件保留设计要求；不得把目标指标视为已测量结果。

## 模块结构

| 模块或文件 | 职责 |
| --- | --- |
| LirtrilnerAppCoordinator | 主页、游戏、结算、收藏与设置导航 |
| LirtrilnerWorkshopViewController | 工坊主页与当前维修进度 |
| LirtrilnerGameViewController | 订单、棋盘、操作栏和暂停入口 |
| LirtrilnerCollectionViewController | 玩具列表与详情 |
| LirtrilnerSettingsViewController | 设置、规则、隐私与支持 |
| LirtrilnerBoardView | 格子布局、轨道手势、可交付状态 |
| LirtrilnerBoardAnimator | 根据引擎事件播放移动、合并和交付 |
| LirtrilnerGameSession | 状态协调、事务历史、撤销、续玩 |
| LirtrilnerBoardEngine | 纯规则计算，无 UIKit、音频或文件读写 |
| LirtrilnerHintSolver | 对当前状态搜索已验证的通关路线 |
| LirtrilnerLevelRepository | JSON 加载、版本与结构校验 |
| LirtrilnerSaveStore | 串行存档、备份与迁移 |
| LirtrilnerAudioService | 音效预加载与播放，尊重静音和用户偏好 |
| LirtrilnerFeedbackService | 触觉反馈及设备能力降级 |

规则、模型和求解器建议放入项目内本地 Swift Package“LirtrilnerCore”，不引入远程依赖。Core 使用非 UI 的隔离设置和可发送值类型；App 的默认 MainActor 设置不应让后台搜索意外运行在主线程。先做最小编译验证，确认工具链与 iOS 15 兼容。

## 数据模型

| 模型 | 必要字段 |
| --- | --- |
| LevelDefinition | schemaVersion、levelID、contentVersion、mode、toyID、stageIndex、initialBoard、objectives、moveLimit、supplySequence、referenceActions |
| Cell | 坐标、terrain（normal/obstacle/delivery）、可选 tile |
| Tile | 稳定 ID、kind（gear/battery）、level（1～4） |
| Objective | ID、kind、level、requiredCount、deliveredCount |
| GameState | 关卡 ID 与内容版本、棋盘、订单状态、剩余步数、补给指针、pendingSupply、status、revision |
| Action | slide(axis/index/direction)、deliver；undo/restart 由 Session 协调 |
| Transition | before、after、events、是否有效、原因 |
| SaveEnvelope | schemaVersion、递增 revision、主线与每日局、有限撤销历史、关卡成绩、收藏进度、设置版本 |

格子地形与占用分离；交付格允许零件经过和停留，不自动吸收。初始棋盘必须校验坐标、类型等级、障碍占用、唯一 ID、订单与补给入口是否合法。首版 JSON schema 固定 5×5，任何不支持的字段或版本都不能静默忽略。

Tile ID 由关卡前缀与递增序号确定，不在纯引擎内读取时间或产生随机数。合并生成稳定新 ID，并由事件指明旧 ID 去向。相同初始状态与操作序列必须得到相同结果。

## 操作事务

有效滑动处理顺序：检查状态与步数 → 提取轨道和障碍片段 → 按方向压缩与合并 → 扣一步 → 尝试一次补给 → 计算是否可交付和终局 → 生成完整 Transition。

交付处理顺序：验证交付格零件与订单 → 消耗零件并更新需求 → 若有等待补给则尝试一次 → 优先判断订单全完成 → 再判断步数和卡住情况。每次指令最多投放一枚，完整恢复逻辑必须包含 pendingSupply。

无效操作不产生历史记录。撤销保留最近 100 次有效操作的前置快照；达到上限丢弃最早记录，界面提示最多撤销 100 步。上限按实际每关步数复核，若任一关可能超出需增加预算。重开清除当前关历史，重新生成确定性初始状态。

Session 在主线程确认指令并设置新状态，递增 revision；立即将存档快照提交给串行写入队列，同时驱动动画。规则正确性不依赖动画完成。切后台请求尽快落盘并清理动画，系统突然终止时允许回退至最后一份成功写入的快照。

状态包括 playing、awaitingDelivery、won、lost。动画和提示加载属于 UI 状态，不影响规则。胜利由一个存档事务同时记录通关、最佳成绩与阶段进度；重复回调或重播结算不可重复解锁收藏。

## 页面和渲染

外层页面使用 Auto Layout；棋盘在 layoutSubviews 中基于 bounds 和间距计算 25 格的 frame，零件层按 ID 映射到视图。只更新受影响的零件，避免动画时全盘重建。

主页和收藏使用 UICollectionView 展示可重复卡片。棋盘使用自定义 UIView，25 格不使用依赖 cell 复用的复杂动画方案。UIKit 动画与 Core Animation 足够完成视觉反馈。[UIViewPropertyAnimator](https://developer.apple.com/documentation/uikit/uiviewpropertyanimator)

所有文字与数值使用 UILabel、UIButton 等原生元素，不嵌入背景图。通用尺寸适配最小目标 iPhone 至大屏，棋盘保持方形；垂直空间不足时收缩装饰区域，保证主要操作可触达。文字使用本地化资源，中文与英文分别验收。

## 存档与数据保护

用户进度存于 Application Support，以 Codable 编解码；目录由 FileManager 查询，不硬编码沙盒路径。存档使用版本化结构、原子替换与上一份有效备份。[Apple 文件存储说明](https://developer.apple.com/documentation/foundation/using-the-file-system-effectively)

写入由单一串行执行器负责，依据 revision 忽略过期快照，避免较慢的旧写入覆盖新状态。写入失败保留内存局面和旧存档，展示“暂未保存”，允许重试，不把失败伪装成成功。

冷启动按“当前文件 → 备份 → 安全初始化”恢复；局部关卡不兼容时保留永久通关记录，仅解释并重开受影响关卡。更新关卡内容时保留进行中版本到结束，或提供明确的兼容重开提示。

设备系统备份与跨设备同步不同：首版不承诺云同步；删除应用可能失去本地进度。重置功能明确说明删除范围，并同时清理主文件和备份，避免下次启动恢复已删除记录。

UserDefaults 只存简单偏好。由于使用该 API，首版要在 PrivacyInfo.xcprivacy 中按真实用途声明对应 Required Reason API，其他涉及的 API 也逐项核对；不猜测或沿用不匹配的理由代码。[UserDefaults 官方说明](https://developer.apple.com/documentation/Foundation/UserDefaults) [隐私声明要求](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

## 关卡验证与提示

开发期验证工具复用 Core 引擎：逐条执行 referenceActions，证明参考解在预算内交付全部订单。所有 36 个主线及 30 个每日题目均必须通过。参考解验证不能只检查最后一个布尔标志，还要校验每步合法性和状态不变量。

提示优先查询当前状态是否位于已验证路线缓存中；否则在后台执行有界搜索，并且只在找到完整通关路线后给出下一步。状态 key 包含棋盘类型等级、订单、剩余步数、补给指针与等待标志，不包含与规则无关的 Tile ID。

初始搜索预算为 50,000 个节点、约 500 ms 或 32 MB 中最先达到者；这些是待低端真机校准的实现预算。不得阻塞主线程。搜索结果带起始 revision，玩家操作、撤销、重开或切关后取消旧任务，过期结果丢弃。

时间或资源耗尽返回 unknown，不返回 unsolvable。提示失败提供回退到最近已知可解状态或重开的选择，回退需用户主动点击。首版不宣称所有局面都有即时最优解。

## 每日挑战的稳定性

以公历本地日期与固定起始日期的天数差，对 30 题取非负模；明确闰年与跨时区行为。当天首次选择后在存档保存 dateKey、levelID 和 contentVersion，避免更新版本后同一天题目变化。昨天未完成的局面可继续，但成绩归属原始日期。

所有日期映射与题库更新都需要单元测试，不使用 hashValue 作为稳定种子。每日题库循环信息在产品界面可见。

## 测试与性能门槛

| 范围 | 发布验收 |
| --- | --- |
| 合并 | 四方向、单次合并限制、IV 上限、不同类型不合并、障碍分段 |
| 交付 | 精确类型等级、多个订单、失败点击、最后一步交付和复玩不重复奖励 |
| 补给 | 堵塞等待、交付后重试、序列耗尽、每指令最多一枚、撤销恢复 |
| 存档 | 编解码等价、坏文件恢复、写入失败、旧版本迁移、连续写入顺序 |
| 提示 | 结果可重放、预算退出、取消、旧结果不会应用到新局 |
| 关卡 | 66 关全部结构合法，参考解逐步重放成功 |
| UI | 首次体验、继续、暂停、失败恢复、收藏、全通关、语言切换 |
| 真机 | 小屏旧设备与现代大屏，切后台、来电中断、静音、减弱动态效果 |

性能目标为常规操作流畅达到 60 fps，后台提示不造成可感知卡顿；连续 30 分钟测试无崩溃或持续内存增长。安装包预算先按 150 MB 以内控制，素材产出后测量；目标不是已获得的性能结果。

## 首版明确不接入的服务

无广告、内购、推送、账号、在线排行榜、云存档、远程热更新或第三方用户追踪。支持与隐私链接可由用户主动打开外部网页；“核心玩法离线可用”不意味着外部支持页面无需网络。工程不请求相机、定位、通讯录或照片权限。

