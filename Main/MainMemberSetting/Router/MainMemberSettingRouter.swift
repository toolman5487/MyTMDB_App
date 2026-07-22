//
//  MainMemberSettingRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/16.
//

import UIKit

// MARK: - MainMemberSettingRouting

@MainActor
protocol MainMemberSettingRouting: AnyObject {
    func showMemberCenter(session: AuthSession)
    func showProfileRefreshCompleted()
    func showProfileRefreshFailed()
    func showClearProfileCacheConfirmation(onConfirm: @escaping () -> Void)
    func showProfileCacheCleared()
    func showClearImageCacheConfirmation(onConfirm: @escaping () -> Void)
    func showImageCacheCleared()
    func showClearAllLocalDataConfirmation(onConfirm: @escaping () -> Void)
    func openTMDBAttribution(_ url: URL)
    func showLogoutConfirmation(onConfirm: @escaping () -> Void)
    func showLoggedOut()
}

// MARK: - MainMemberSettingRouter

@MainActor
final class MainMemberSettingRouter: BaseRouter, MainMemberSettingRouting {

    func showMemberCenter(session: AuthSession) {
        show(MemberCenterViewController(session: session), using: .push)
    }

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

    func showClearImageCacheConfirmation(onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: "清除圖片快取",
            message: "會清除本機儲存的圖片快取，下次瀏覽時會重新下載。",
            actionTitle: "清除",
            onConfirm: onConfirm
        )
    }

    func showImageCacheCleared() {
        showAlert(title: "已清除", message: "圖片快取已清除。")
    }

    func showClearAllLocalDataConfirmation(onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: "清除所有本機資料",
            message: "會清除會員資料、Session 與圖片快取，並返回登入頁。",
            actionTitle: "清除",
            onConfirm: onConfirm
        )
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
                "MainMemberSetting logout navigation failed because source window was unavailable."
            )
            return
        }

        AppRootFactory.replaceRoot(in: window, for: .loggedOut)
    }
}
