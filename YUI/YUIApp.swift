//
//  YUIApp.swift
//  YUI
//
//  静态 UI 演示工程入口。仅做前端演示，不接入真实键盘、网络或业务逻辑。
//

import SwiftUI

@main
struct YUIApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
