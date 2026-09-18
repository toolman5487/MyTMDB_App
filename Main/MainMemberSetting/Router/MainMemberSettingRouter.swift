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
    func showClearSearchHistoryConfirmation(onConfirm: @escaping () -> Void)
    func showSearchHistoryCleared()
    func showClearAllLocalDataConfirmation(isMember: Bool, onConfirm: @escaping () -> Void)
    func showClearAllLocalDataFailed(
        onRetry: @escaping () -> Void,
        onClearLocalOnly: @escaping () -> Void
    )
    func showSecureSessionOperationFailed(onRetry: @escaping () -> Void)
    func openTMDBAttribution(_ url: URL)
    func showLogoutConfirmation(onConfirm: @escaping () -> Void)
    func showLogoutFailed(
        onRetry: @escaping () -> Void,
        onClearLocalOnly: @escaping () -> Void
    )
    func showLoggedOut()
    func showLogin()
    func showRegister()
}

// MARK: - MainMemberSettingRouter

@MainActor
final class MainMemberSettingRouter: BaseRouter, MainMemberSettingRouting {

    // MARK: - Properties

    private let sceneBuilder: MemberCenterSceneBuilding
    private weak var appFlowRouter: AppFlowRouting?

    // MARK: - Initialization

    init(
        sourceViewController: UIViewController,
        sceneBuilder: MemberCenterSceneBuilding,
        appFlowRouter: AppFlowRouting
    ) {
        self.sceneBuilder = sceneBuilder
        self.appFlowRouter = appFlowRouter
        super.init(sourceViewController: sourceViewController)
    }

    func showMemberCenter(session: AuthSession) {
        show(sceneBuilder.makeMemberCenterViewController(session: session), using: .push)
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

    func showClearSearchHistoryConfirmation(onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: "清除搜尋紀錄？",
            message: "將刪除本機所有搜尋關鍵字紀錄。此操作無法復原。",
            actionTitle: "清除",
            onConfirm: onConfirm
        )
    }

    func showSearchHistoryCleared() {
        showAlert(title: "已清除", message: "搜尋紀錄已清除。")
    }

    func showClearAllLocalDataConfirmation(isMember: Bool, onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: "清除所有本機資料",
            message: isMember
                ? "會清除會員資料、Session、搜尋紀錄與圖片快取，並返回登入頁。"
                : "會結束訪客模式，清除搜尋紀錄與圖片快取，並返回登入頁。",
            actionTitle: "清除",
            onConfirm: onConfirm
        )
    }

    func showClearAllLocalDataFailed(
        onRetry: @escaping () -> Void,
        onClearLocalOnly: @escaping () -> Void
    ) {
        showRemoteSessionFailureAlert(
            title: "無法撤銷 TMDB Session",
            localOnlyTitle: "仍清除本機資料",
            onRetry: onRetry,
            onLocalOnly: onClearLocalOnly
        )
    }

    func showSecureSessionOperationFailed(onRetry: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "無法清除登入資料",
            message: "TMDB Session 可能已失效，但目前無法安全清除此裝置的登入資料。請確認裝置已解鎖後重試。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "重試", style: .default) { _ in onRetry() })
        show(alert, using: .present)
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

    func showLogoutFailed(
        onRetry: @escaping () -> Void,
        onClearLocalOnly: @escaping () -> Void
    ) {
        showRemoteSessionFailureAlert(
            title: "登出失敗",
            localOnlyTitle: "僅清除本機登入",
            onRetry: onRetry,
            onLocalOnly: onClearLocalOnly
        )
    }

    func showLoggedOut() {
        appFlowRouter?.showLoggedOutRoot()
    }

    func showLogin() {
        show(sceneBuilder.makeLoginNavigationController(context: .inApp), using: .present)
    }

    func showRegister() {
        guard let url = TMDBResourceURL.signup else { return }
        openSafari(url)
    }

    private func showRemoteSessionFailureAlert(
        title: String,
        localOnlyTitle: String,
        onRetry: @escaping () -> Void,
        onLocalOnly: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: "目前無法連線至 TMDB 撤銷 Session。若只清除本機資料，遠端 Session 可能仍然有效。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "重試", style: .default) { _ in onRetry() })
        alert.addAction(UIAlertAction(title: localOnlyTitle, style: .destructive) { _ in
            onLocalOnly()
        })
        show(alert, using: .present)
    }
}
