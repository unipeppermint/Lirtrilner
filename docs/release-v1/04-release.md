# 发条修理铺上线验收与提审准备

首版完成条件是正式构建具备完整内容、通过功能与真机验收、商店资料准确且可提交审核。实际公开上架还取决于账号、发行地区资质和苹果审核结果。当前已完成核心实现、全题库参考解、构建与页面渲染检查；真实设备和体验验收、外部资料、签名与提审检查仍待完成。详见 [实施报告](05-implementation.md)。

## 开发里程碑

| 阶段 | 交付物 | 进入下一阶段的条件 |
| --- | --- | --- |
| M1 规则闭环 | Core 引擎、10 个内部关卡、撤销、交付、补给 | 边界测试通过，实际玩法可理解 |
| M2 正式体验 | 三个主页面、收藏、设置、正式机器人与小火车素材 | 可完成一整件玩具，全部页面可操作 |
| M3 完整内容 | 36 主线、30 每日、12 玩具、提示、双语与存档 | 全部参考解验证通过，素材无占位 |
| M4 发布候选 | 真机报告、性能记录、可分发构建、图标与商店截图 | 无已知阻断问题，存档与全流程稳定 |
| M5 提交准备 | 商店资料、隐私声明、支持网址、地区资料与审核备注 | 发布账户资料齐全，构建上传校验通过 |
| M6 上架 | 审核反馈处理和所选地区可用性检查 | 审核通过并按已确定发布方式发布 |

M1 的 10 关内部版本不作为正式首版交付，不在 App Store 中发布带占位或“开发中”页面的版本。

## 上线验收清单

| 编号 | 验收项 | 当前状态 | 完成证据 |
| --- | --- | --- | --- |
| R01 | 36 主线与 30 每日题目全部可解 | 自动验证通过，试玩待做 | 66 题逐步重放；core-tests.log；content-index.md |
| R02 | 12 件玩具三阶段修复完整 | 规则通过，体验待验收 | 三阶段计数与重复奖励测试；12 玩具双语渲染图 |
| R03 | 提示、撤销、失败恢复、重开正确 | 自动验证通过，触摸待验收 | 14 项测试及失败恢复页面；真实触摸未测 |
| R04 | 主线与每日存档互不覆盖 | 自动验证通过，真机待验收 | 双模式与历史 Codable 往返、日期映射测试 |
| R05 | 原型计数和等级问题全部修正 | 已实现并渲染检查 | 第 4 关为火车；等级、3/36、1/12 页面截图 |
| R06 | 简体中文与英文无缺失或截断 | 基础字号渲染检查 | 两尺寸、中英共 104 页面状态；全部离屏内容/大字待测 |
| R07 | 离线完成核心流程 | 代码无网络依赖，真机待验收 | 未连接真机，未声称飞行模式实测 |
| R08 | 小屏和大屏、安全区及基础无障碍通过 | 两尺寸渲染通过，交互待验收 | iPhone SE3 / 17 Pro，iOS 26.5；VoiceOver 实测待做 |
| R09 | 稳定性和性能达到目标 | 待实测 | 未进行 30 分钟游戏或 Instruments 采样 |
| R10 | 正式素材、应用图标和音效齐全 | 已实现，音频体验待验收 | 06-assets.md；原创矢量、图标及 WAV |
| R11 | 隐私清单和隐私标签符合实际行为 | 源码与归档初检 | 无追踪/收集；隐私清单已打包；最终签名包待复核 |
| R12 | 支持及隐私页面可公开访问 | 用户确认稍后补齐 | 仅提供有效离线隐私与帮助页，无空链接 |
| R13 | 名称、地区、年龄分级、内容权利资料就绪 | 待用户资料 | 地区、主体、名称及资质尚未确认 |
| R14 | 构建与商店截图一致 | 开发渲染有记录，商店图待拍 | 核验图含 Debug 状态，无系统栏，非正式商店图 |
| R15 | 上传与提审前校验通过 | 未签名归档通过，上传未执行 | release-archive.log；未修改团队、未上传 |

阻断级问题包括崩溃、数据丢失、关卡无法完成、关键按钮失效和错误收费入口，必须清零。影响规则理解的等级、订单和计数问题同样不得带入发布。其他轻微问题需记录影响与修复安排。

## 设备与发布验证

以 iOS 15 为最低支持目标，至少覆盖最小支持系统、小屏 iPhone、现代带安全区的大屏 iPhone和提交时当前稳定 iOS。系统组合依据可用真机和模拟器确定并留档，不能把模拟器覆盖写成真机结果。

Archive 前用 xcodebuild 的最终 build settings 确认实际 Deployment Target、设备族与资源打包，防止 Project 层 26.5 默认值影响新 target。构建工具和 SDK 是否满足提交要求，以发布当日的 [Apple 提交要求](https://developer.apple.com/app-store/submitting/) 为准。

## 商店信息草案

下面文案供功能完成后复核使用，不应在实现前作为已存在功能对外发布。

| 字段 | 草案或处理 |
| --- | --- |
| 中文名称 | 发条修理铺 |
| 英文名称 | Clockwork Toy Workshop，名称可用性待查 |
| 中文副标题 | 合并零件，修复你的玩具收藏 |
| 英文副标题 | Merge parts. Restore toys. |
| 分类 | 游戏，益智；最终按 App Store Connect 可选分类填写 |
| 价格 | 免费 |
| 年龄分级 | 据实际内容填写问卷，不预先承诺某个等级 |
| 登录 | 无需账号 |
| 关键词方向 | 合并、解谜、玩具、修复、齿轮、逻辑、益智；提交前检查长度和相关性 |
| 首版更新说明 | 首次发布：36 个主线关卡、12 件玩具与每日挑战题库 |

中文描述草案：

在发条修理铺，让沉睡的玩具重新动起来。滑动一行或一列，合并相同零件，把指定等级的齿轮与电池送到交付格，完成维修委托。

挑战 36 个主线关卡，逐步修复 12 件玩具。利用可预测的补给和固定障碍规划路线，保留恰好需要的零件。每日挑战从 30 个题目中按日期循环，为你提供另一道小谜题。

全部玩法免费，无广告、无内购、无需登录。支持离线游玩、免费提示、撤销和自动续玩。进度保存在当前设备，支持页面和隐私网页需要网络。

英文描述草案：

Bring forgotten toys back to life in Clockwork Toy Workshop. Slide one row or column, merge matching parts, and deliver gears and batteries at the exact levels your repair orders need.

Solve 36 story puzzles and restore 12 toys. Plan around fixed obstacles and a visible supply queue. A daily challenge rotates through a collection of 30 puzzles.

All gameplay is free, with no ads, in-app purchases, or account required. Play offline with hints, undo, and automatic local saves. Progress stays on your device. Support and privacy web pages require an internet connection.

## 截图与审核演示

准备 5 张来自正式构建的截图：实际合并棋盘、精确交付、玩具维修阶段、收藏页面、每日挑战。叠加说明可以帮助理解，但图片主体需准确展示应用使用；三屏 AI 视觉原型不能直接充当实际游戏截图。[Apple 截图说明](https://developer.apple.com/help/app-review/guideline-reference/2-3-3-screenshots)

按提交时 App Store Connect 要求导出对应 iPhone 尺寸，避免硬编码已经变化的设备规格。[截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

审核备注草案：

Clockwork Toy Workshop is a free, offline puzzle game. No account, advertisements, or in-app purchases are required. The player moves one row or column at a time, merges matching parts, and manually delivers parts of the exact type and level requested by repair orders.

Please start from a fresh installation to access the first tutorial. Level 1 introduces local row and column movement; Level 2 introduces exact-level delivery; Level 3 combines delivery with fixed obstacles and completes the first toy. Completing Level 3 also opens Daily Challenge. The Collection tab displays restored toys. Settings contains the rules, privacy policy, and support links.

The release contains 36 story levels and a rotating pool of 30 daily puzzles. Progress is saved locally. All features described here are available in the submitted build.

提审前必须逐句核对上述功能和路径。初始三关要短且容易体验差异，不能把核心机制藏在长时间解锁后。无需创建只对审核人员显示的特殊内容。

## 隐私和支持资料

所有应用都需要真实可用的支持链接与隐私政策；应用内设置页也应提供容易找到的隐私入口。[Apple 审核准备说明](https://developer.apple.com/app-store/review/)

按本方案，核心玩法不向开发者服务器发送用户数据，不接入第三方统计。最终 App Privacy 回答仍应依据实际构建、所用 SDK 和网页行为核查，不能仅因为“离线游戏”直接跳过声明。[App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

隐私政策需明确发布者、联系方式、生效日期、本地保存的进度和设置、删除方式、系统备份可能性、用户主动访问外部支持页的情况。支持页需有产品名、联系渠道、常见问题和恢复说明。待提供真实主体及联系信息后才能形成可发布的最终文本。

PrivacyInfo.xcprivacy、App Privacy 标签和隐私政策是不同交付物，三者内容应一致。使用 UserDefaults 等受要求约束的 API 时需填报实际用途。[Required Reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

## 发行地区与外部依赖

| 待落实事项 | 上线影响 | 当前处理 |
| --- | --- | --- |
| 发行国家和地区 | 决定本地化、地区许可与商店资料 | 暂不替用户选择，开发按中英双语进行 |
| 中国大陆发行资料 | Apple 对游戏列有批准文号及支持文件要求，并列出适用的 ICP 信息 | 若发行大陆，在提审前核实适用资料并办理；免费不是自动豁免 |
| 其他地区要求 | 可能涉及地区游戏许可或商店主体信息 | 按实际所选地区逐项核验 |
| 开发者展示主体和联系信息 | 支持页、隐私政策与审核联系方式使用 | 由实际账号主体提供 |
| App 名称与内容权利 | 影响名称可用性和素材使用 | 提交前核验并保留依据 |
| 公开支持与隐私网址 | 商店提交与应用内入口依赖 | 需要真实域名或可持续托管的公开页面 |

地区要求依据 [Apple App 信息说明](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)。此表用于列明发布依赖，不替代对具体发行资质的核实，也不擅自改变发行地区。

## 资料与范围变更

本次已完成本地应用开发和可用验证，未操作 App Store Connect、未提交构建、未修改签名团队或发行配置。剩余验收及正式上架按照本清单与发布缺项推进。若增加广告、内购、账号或网络服务，必须重新审查产品范围、隐私资料和对应测试。

审核通过无法由技术方案保证。若审核反馈同质化，应基于真实机制、内容与演示路径解释或改进，不通过换 Bundle ID 或重复换皮提交来处理。[Apple 审核指南](https://developer.apple.com/app-store/review/guidelines/#design)

