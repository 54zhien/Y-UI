# YUI — 键盘 App 首页静态演示（SwiftUI）

原生 iOS SwiftUI 演示工程，只做**前端界面演示**：不接入真实键盘扩展、不联网、不含业务逻辑。
布局与材料按照四张参考图还原，配色按需求改为浅色冷蓝淡紫 / 深色深蓝紫到酒红。

---

## 1. 参考图对照

| 参考图 | 内容 | 工程中的实现 |
| --- | --- | --- |
| 图 1（浅色设置页） | 冷蓝淡紫弥散渐变、Material 玻璃卡片、底部悬浮圆按钮 | `DiffuseBackground`（浅色 3×3 网格色）、`GlassCard`（`.regularMaterial`）、`BottomDock` |
| 图 2（深色设置页） | 深蓝紫 → 酒红渐变 | `DiffuseBackground`（深色网格色，右下角酒红 `#6B2A3C`） |
| 图 3（首页） | 当前键盘预览卡、两列面板入口、底部左右圆形控件 | `KeyboardPreviewCard`、`PanelGrid`、`BottomDock` |
| 图 4（列表底部） | 面板列表底部的「管理」按钮、滚动后底部悬浮控件 | `HomeView.manageButton` + `BottomDock` |

按审核意见，战争模式已从页面顶部移除，只保留底部胶囊上的开关与状态显示。

## 2. 界面结构

```
HomeView
├─ DiffuseBackground                       全屏弥散渐变（MeshGradient，公开 API）
└─ ScrollView
   ├─ SectionHeader("当前键盘")             页面第一块内容
   ├─ KeyboardPreviewCard                  静态九宫格 + 候选栏 + PureGlass / 跟随系统
   ├─ SectionHeader("你的设置")
   ├─ PanelGrid                            两列液态玻璃外观面板（无回弹），10 个入口
   │  └─ PanelTile                         仅管理模式：抖动 + 隐藏 + 上移/下移 + 拖动排序
   ├─ HiddenPanelsBar                      仅编辑模式出现，点 + 重新添加
   ├─ DemoNoteCard                         示例说明（占位声明）
   └─ manageButton                         「管理 / 完成」
底部悬浮（固定，不随滚动）
└─ BottomDock
   ├─ 设置（圆形，左）
   ├─ 战争模式胶囊（中，显示开/关，可点切换）
   └─ 搜索（圆形，右）
```

保留的面板入口：主题、外观、声音与触感、输入与手势、工具栏、扩展、词库、社区、隐私与省电、输入统计；
另有独立的「示例说明」区块。

## 3. 设计与材料

- **卡片材质分两种**：首页 10 个面板用 **Liquid Glass 外观**（`.glassEffect(.regular, in:)`，
  **不调用** `.interactive()`，所以按下去没有液态回弹/放大）；键盘预览卡与示例说明卡仍用
  系统普通半透明 Material（`.regularMaterial` + 细描边），保留材质层级差。
- **底部控件**：圆形按钮用 `.buttonStyle(.glass)` + `.buttonBorderShape(.circle)`；战争模式胶囊用
  `.glassEffect(... .interactive(), in: .capsule)`（这里是按钮，保留系统交互反馈），
  两者用 `GlassEffectContainer` 让相邻玻璃形状融合。
- **图标**：全部 SF Symbols，无自绘位图图标。
- **渐变**：`MeshGradient`（3×3 控制点），无接缝、无私有 API；开启「降低透明度」时退化为同色系纯色底。
- **底部圆心对齐**：公开 API 不提供屏幕圆角半径，`Theme.screenCornerRadius(for:)` 按屏宽给出经验值，
  圆形控件用「圆角近似值 − 控件半径」作为内边距，并把结果夹紧到 8…30pt，
  因此**圆心对齐只是近似**：窄屏、无 Home Indicator 的机型、iPad 上会以不溢出和不压安全区优先。
- **底栏尺寸与间距（按 HIG）**：左右圆钮 44–46pt（HIG 最小触控目标 44×44pt，不再放大到 56pt），
  三控件统一 8pt 间距，中间战争模式胶囊**撑满**两侧剩余宽度，整条栏读起来是一条导航栏；
  辅助功能字号下胶囊只保留图标 + 开/关状态（VoiceOver 仍读出「战争模式」）。
- **辅助功能字号**：动态字体 ≥ accessibility1 时面板网格改**单列**、卡片标题/数值/说明允许换行，键盘卡底部签名行改为上下排列，避免大字号截断。
- **安全区域与遮挡**：滚动内容底部预留 132pt，底部悬浮控件不遮挡最后一张卡片与「管理」按钮。
- **深浅色 / 动态字体 / 无障碍**：颜色取自语义色与自定义渐变；字体走 `Font.TextStyle` 体系；
  可点元素均有 label/value/hint；开启「减少动态效果」时编辑模式**不抖动**。

## 4. 交互（全部为演示占位）

| 操作 | 行为 | 边界 |
| --- | --- | --- |
| 点面板卡片（非管理模式） | 弹出该面板的占位说明页 | 该模式下卡片本身就是一个 Button；编辑模式下卡片不再是 Button，点它不会打开说明页 |
| 点「管理」 | 进入编辑模式：卡片轻微抖动，出现隐藏与上移/下移按钮 | 仅内存状态，不持久化 |
| 管理模式下拖动卡片 | 本地重排面板顺序 | 非管理模式不挂拖动/放置，避免误触 |
| 上移 / 下移按钮 | 本地重排（可用 VoiceOver 操作） | 首/末项自动禁用 |
| 点隐藏（眼睛斜杠） | 隐藏该面板，进入「已隐藏」区 | 仅内存状态 |
| 点「已隐藏」里的「＋」 | 重新添加到列表末尾 | 仅内存状态 |
| 点「完成」 | 退出编辑模式，移除拖动能力并停止抖动 | — |
| 点底部战争模式胶囊 | 切换开/关，顶部不再有状态卡，状态只在胶囊上呈现 | 仅模拟，不影响网络或特效 |
| 点底部设置 / 搜索 | 弹出占位说明页（搜索只有样式，不可输入） | 明确标注「演示占位」 |

编辑控件触控尺寸：视觉 30pt 的玻璃圆钮，命中区域扩到 44pt；隐藏按钮固定在卡片右上角并在管理模式下
为文字预留 40pt 尾部空间，上移/下移按钮走卡片底部布局行，**不覆盖**标题、数值与说明文字。

## 5. 运行

要求：**Xcode 26 或更新版本**，iOS 26.0+ 模拟器或设备（Liquid Glass API 的最低系统版本）。

```bash
open YUI.xcodeproj      # 选择任意 iPhone 模拟器，⌘R
```

命令行构建（与 CI 相同的命令）：

```bash
xcodebuild -project YUI.xcodeproj -scheme YUI -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
```

## 6. 构建工作流（GitHub Actions）

`.github/workflows/ios-build.yml`：在 `macos-26` runner 上打印工具链版本、构建 iOS Simulator 包，
并通过 `Scripts/ci-capture-screenshots.sh` 启动模拟器截图，构建日志与截图都作为 artifact 上传：

| 截图 | 覆盖的场景 |
| --- | --- |
| `home-light` / `home-dark` | 常规字号，浅色 / 深色外观 |
| `home-a11y-xxxl` | 辅助功能最大字号（核查底栏三控件与两列网格是否被压坏） |
| `home-narrow-light` | 窄屏机型（runner 上有 SE / mini 时才有） |

**CI 与实际视觉验证的区别（重要）**：

- CI 只能证明「工程可被 Xcode 26 编译、可安装到模拟器启动、可生成截图」；
- CI **不能**证明与参考图的视觉一致、卡片材料观感、圆形控件圆心是否真的贴合圆角、
  编辑模式抖动与排序手感；
- 截图是供人工核对的素材，截图能上传不代表通过验收；
- 交互路径由第 7 节的 XCUITest 覆盖，但「手感/抖动幅度」这类主观项仍只能人工判断。

## 7. 交互验证（XCUITest）

`YUIUITests/YUIHomeUITests.swift` 在真实模拟器上驱动 App，不注入任何测试专用代码，只依赖界面已有的无障碍 label：

| 用例 | 覆盖 |
| --- | --- |
| `testWarModeCapsuleTogglesState` | 点底部胶囊：关 → 开 → 关，断言 accessibilityValue |
| `testNonEditingTileOpensDemoSheet` | 非编辑模式点面板卡片 → 打开占位说明页，关闭后回到首页 |
| `testManageModeExposesIndependentEditControlsAndReorders` | 进管理模式；断言隐藏/上移/下移是独立可点控件；首项上移禁用；**编辑模式点卡片本体不会打开说明页**（嵌套 Button 回归守卫）；下移后顺序变化 |
| `testHideAndRestorePanel` | 隐藏「主题」→ 出现「重新添加主题」→ 恢复后回到网格 |
| `testManageButtonReachableAfterScrollingToBottom` | 一路滑到底，断言「管理」按钮 `isHittable`（不被底部悬浮控件遮挡） |

运行方式：

```bash
xcodebuild test -project YUI.xcodeproj -scheme YUI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -resultBundlePath artifacts/YUIUITests.xcresult
```

CI 里由 `Scripts/ci-run-ui-tests.sh` 执行，测试日志写 `artifacts/ui-tests.log`，
结果包 `artifacts/YUIUITests.xcresult`，并尽力把截图附件导出到 `artifacts/ui-test-attachments/`。
这一步失败即判整个 workflow 失败，不会用 `continue-on-error` 吞掉。

## 8. 验证状态与限制

| 项 | 状态 |
| --- | --- |
| 代码语法检查 | 本机 Swift 6.4.1（Windows 工具链）`swiftc -parse` 逐文件解析通过（仅语法，不含 SwiftUI 类型检查） |
| Xcode / iOS SDK 构建 | 由 GitHub Actions `macos-26` 执行，结果见提交对应的 workflow run |
| 模拟器运行与截图 | 同上；截图仅作素材，未做人工视觉验收 |
| 与参考图的视觉比对 | **未做**：本机是 Windows，无模拟器/真机 |
| 交互验证（排序 / 隐藏 / 恢复 / 战争模式 / 管理按钮可见性） | 由 XCUITest 在 CI 模拟器上执行，结果见对应 run 的 UI 测试步骤与 `artifacts/ui-tests.log` |
| 抖动幅度、动效手感 | **未自动化**：只能人眼看 |
| 辅助功能（VoiceOver、动态字体、减少动态效果） | 辅助字号布局已适配并有 CI 截图；VoiceOver 与「减少动态效果」仍**未实机验证** |

其它限制：

- 面板数据、统计数字（如「今天 118 字」）均为硬编码占位。
- AppIcon 为占位空资产，构建会有图标缺失告警，不影响编译。
- 屏幕圆角对齐与底栏尺寸都用经验值，极端机型可能需要微调。
- UI 测试只覆盖 iPhone 主流程，未覆盖 iPad、横屏、深浅色切换下的重复跑。

## 9. 目录结构

```
YUI.xcodeproj/                 Xcode 工程（含共享 scheme、UI 测试目标）
YUI/
├─ YUIApp.swift                入口
├─ Design/
│  ├─ Theme.swift              圆角/圆角近似/字体/颜色助手
│  ├─ DiffuseBackground.swift  弥散渐变背景
│  └─ GlassCard.swift          Material 玻璃卡片 + 小节标题
├─ Model/
│  ├─ PanelItem.swift          面板静态数据
│  └─ HomeModel.swift          内存演示状态（排序/隐藏/编辑/战争模式/占位页）
├─ Views/
│  ├─ HomeView.swift           首页组合
│  ├─ KeyboardPreviewCard.swift 静态九宫格 + 候选栏
│  ├─ PanelGrid.swift          两列网格 + 管理模式 + 抖动 + 已隐藏区
│  ├─ BottomDock.swift         底部悬浮玻璃控件
│  └─ DemoSheet.swift          占位说明页
└─ Resources/
   └─ Assets.xcassets          AccentColor / AppIcon 占位
YUIUITests/
└─ YUIHomeUITests.swift        XCUITest：管理模式/排序/隐藏恢复/战争模式/管理按钮可见
Scripts/ci-capture-screenshots.sh   CI 截图脚本
Scripts/ci-run-ui-tests.sh          CI 交互测试脚本
.github/workflows/ios-build.yml     macOS 构建 + 截图 + UI 测试工作流
```

