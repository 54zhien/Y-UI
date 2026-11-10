//
//  YUIHomeUITests.swift
//  YUIUITests
//
//  对「管理模式 / 上移下移 / 隐藏恢复 / 战争模式切换 / 滚到底管理按钮可见」做真实
//  模拟器交互验证。仅依赖 App 已有的无障碍 label，不注入任何测试专用代码。
//

import XCTest

final class YUIHomeUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // 上一个用例若没退干净，launch() 自身的 terminate 会偶发失败（CI 上出现过一次），
        // 这里先显式结束再启动。
        app.terminate()
        app.launch()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    // MARK: - 工具

    /// 把当前屏幕截图挂到测试报告里（xcresult 附件）。
    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func scrollUntilHittable(_ element: XCUIElement, up: Bool, maxSwipes: Int = 15) {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            if up {
                app.swipeUp()
            } else {
                app.swipeDown()
            }
            swipes += 1
        }
    }

    private func panelTile(_ title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "\(title)，")).firstMatch
    }

    // MARK: - 战争模式胶囊

    func testWarModeCapsuleTogglesState() {
        let capsule = app.buttons["战争模式"]
        XCTAssertTrue(capsule.waitForExistence(timeout: 20), "底部战争模式胶囊应存在")
        XCTAssertEqual(capsule.value as? String, "关", "初始应为关")
        attach("dock-war-off")

        capsule.tap()
        expectation(for: NSPredicate(format: "value == %@", "开"), evaluatedWith: capsule)
        waitForExpectations(timeout: 5)
        attach("dock-war-on")

        capsule.tap()
        expectation(for: NSPredicate(format: "value == %@", "关"), evaluatedWith: capsule)
        waitForExpectations(timeout: 5)
    }

    // MARK: - 非管理模式：面板可点

    func testNonEditingTileOpensDemoSheet() {
        let tile = panelTile("主题")
        XCTAssertTrue(tile.waitForExistence(timeout: 20), "主题面板应存在")
        tile.tap()

        XCTAssertTrue(app.navigationBars["主题"].waitForExistence(timeout: 8), "应打开主题占位说明页")
        attach("sheet-panel")

        app.buttons["完成"].tap()
        XCTAssertTrue(capsuleExists(), "关闭说明页后应回到首页")
    }

    private func capsuleExists() -> Bool {
        app.buttons["战争模式"].waitForExistence(timeout: 8)
    }

    // MARK: - 管理模式：独立控件 + 排序

    func testManageModeExposesIndependentEditControlsAndReorders() {
        enterManageMode()

        // 回到顶部，检查首个面板的编辑控件
        let moveUpFirst = app.buttons["上移主题"]
        scrollUntilHittable(moveUpFirst, up: false, maxSwipes: 20)
        XCTAssertTrue(app.buttons["隐藏主题"].exists, "管理模式下应有隐藏控件")
        XCTAssertTrue(app.buttons["下移主题"].exists, "管理模式下应有下移控件")
        XCTAssertFalse(moveUpFirst.isEnabled, "首项不应可上移")
        attach("edit-controls")

        // 编辑模式下点击卡片本体不应再打开说明页（原来外层 Button 的问题）
        app.staticTexts["主题"].firstMatch.tap()
        XCTAssertFalse(
            app.navigationBars["主题"].waitForExistence(timeout: 2),
            "编辑模式下点击卡片本体不应打开占位说明页"
        )

        // 下移「主题」，顺序变化：外观成为第一项
        let moveDown = app.buttons["下移主题"]
        XCTAssertTrue(moveDown.isHittable, "下移按钮应可点")
        moveDown.tap()

        let moveUpAppearance = app.buttons["上移外观"]
        expectation(for: NSPredicate(format: "enabled == false"), evaluatedWith: moveUpAppearance)
        waitForExpectations(timeout: 6)
        attach("edit-reordered")

        // 退出编辑
        exitManageMode()
    }

    // MARK: - 隐藏 / 恢复

    func testHideAndRestorePanel() {
        enterManageMode()

        let hideTheme = app.buttons["隐藏主题"]
        scrollUntilHittable(hideTheme, up: false, maxSwipes: 20)
        hideTheme.tap()

        let restore = app.buttons["重新添加主题"]
        XCTAssertTrue(restore.waitForExistence(timeout: 8), "隐藏后应出现「重新添加主题」")
        scrollUntilHittable(restore, up: true, maxSwipes: 12)
        attach("edit-hidden")
        XCTAssertTrue(restore.isHittable, "重新添加按钮应可点")
        restore.tap()

        XCTAssertTrue(app.buttons["隐藏主题"].waitForExistence(timeout: 8), "恢复后应重新出现在网格里")
        attach("edit-restored")

        exitManageMode()
    }

    // MARK: - 滚到底：管理按钮可见

    func testManageButtonReachableAfterScrollingToBottom() {
        let manage = app.buttons["管理面板"]
        XCTAssertTrue(manage.waitForExistence(timeout: 20), "管理按钮应在视图层级中存在")

        var swipes = 0
        while !manage.isHittable && swipes < 25 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(manage.isHittable, "滚动到底后管理按钮应可点，不能被底部悬浮控件遮挡")
        attach("scroll-bottom-manage")
        XCTAssertFalse(app.buttons["隐藏主题"].exists, "非编辑模式不应出现隐藏控件")
    }

    // MARK: - 模式切换封装

    private func enterManageMode() {
        let manage = app.buttons["管理面板"]
        XCTAssertTrue(manage.waitForExistence(timeout: 20), "管理按钮应存在")
        scrollUntilHittable(manage, up: true, maxSwipes: 25)
        XCTAssertTrue(manage.isHittable, "管理按钮应可点")
        manage.tap()

        XCTAssertTrue(
            app.buttons["完成编辑"].waitForExistence(timeout: 8),
            "进入管理模式后按钮应变为「完成编辑」"
        )
    }

    private func exitManageMode() {
        let done = app.buttons["完成编辑"]
        scrollUntilHittable(done, up: true, maxSwipes: 25)
        if done.isHittable {
            done.tap()
        }
    }
}
