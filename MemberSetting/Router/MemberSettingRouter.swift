//
//  MemberSettingRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/16.
//

import UIKit

// MARK: - MemberSettingRouting

@MainActor
protocol MemberSettingRouting: AnyObject {
    func showProfileRefreshCompleted()
    func showProfileRefreshFailed()
    func showClearProfileCacheConfirmation(onConfirm: @escaping () -> Void)
    func showProfileCacheCleared()
    func openTMDBAttribution(_ url: URL)
    func showLogoutConfirmation(onConfirm: @escaping () -> Void)
    func showLoggedOut()
}

// MARK: - MemberSettingRouter

@MainActor
final class MemberSettingRouter: BaseRouter, MemberSettingRouting {

    func showProfileRefreshCompleted() {
        showAlert(title: "已更新", message: "會員資料已重新整理。")
    }

    func showProfileRefreshFailed() {
        showAlert(title: "更新失敗", message: "目前無法重新整理會員資料，請稍後再試。")
    }

    func showClearProfileCacheConfirmation(onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: "清除會員資料快取",
            message: "會清除本機儲存的會員名稱與頭像快取，但不會登出。",
            actionTitle: "清除",
            onConfirm: onConfirm
        )
    }

    func showProfileCacheCleared() {
        showAlert(title: "已清除", message: "會員資料快取已清除。")
    }

    func openTMDBAttribution(_ url: URL) {
        openSafari(url)
    }

    func showLogoutConfirmation(onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: "登出",
            message: "確定要登出並返回登入頁嗎？",
            actionTitle: "登出",
            onConfirm: onConfirm
        )
    }

    func showLoggedOut() {
        guard let window = sourceViewController?.view.window else {
            AppLogger.navigation.warning(
                "MemberSetting logout navigation failed because source window was unavailable."
            )
            return
        }

        AppRootFactory.replaceRoot(in: window, for: .loggedOut)
    }
}
