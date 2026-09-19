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
        appFlowRouter: AppFlowRouting,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.sceneBuilder = sceneBuilder
        self.appFlowRouter = appFlowRouter
        super.init(
            sourceViewController: sourceViewController,
            interfaceLocalization: interfaceLocalization
        )
    }

    func showMemberCenter(session: AuthSession) {
        show(sceneBuilder.makeMemberCenterViewController(session: session), using: .push)
    }

    func showProfileRefreshCompleted() {
        showAlert(
            title: interfaceLocalization.string(
                "main_member_setting.alert.updated.title",
                defaultValue: "Updated"
            ),
            message: interfaceLocalization.string(
                "main_member_setting.alert.profile_refreshed.message",
                defaultValue: "Your profile has been refreshed."
            )
        )
    }

    func showProfileRefreshFailed() {
        showAlert(
            title: interfaceLocalization.string(
                "main_member_setting.alert.update_failed.title",
                defaultValue: "Update Failed"
            ),
            message: interfaceLocalization.string(
                "main_member_setting.alert.profile_refresh_failed.message",
                defaultValue: "Your profile cannot be refreshed right now. Please try again later."
            )
        )
    }

    func showClearProfileCacheConfirmation(onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: interfaceLocalization.string(
                "main_member_setting.alert.clear_profile_cache.title",
                defaultValue: "Clear Profile Cache"
            ),
            message: interfaceLocalization.string(
                "main_member_setting.alert.clear_profile_cache.message",
                defaultValue: "This removes the locally stored profile name and avatar without signing you out."
            ),
            actionTitle: interfaceLocalization.string("common.action.clear", defaultValue: "Clear"),
            onConfirm: onConfirm
        )
    }

    func showProfileCacheCleared() {
        showAlert(
            title: interfaceLocalization.string("common.state.cleared", defaultValue: "Cleared"),
            message: interfaceLocalization.string(
                "main_member_setting.alert.profile_cache_cleared.message",
                defaultValue: "The profile cache has been cleared."
            )
        )
    }

    func showClearImageCacheConfirmation(onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: interfaceLocalization.string(
                "main_member_setting.alert.clear_image_cache.title",
                defaultValue: "Clear Image Cache"
            ),
            message: interfaceLocalization.string(
                "main_member_setting.alert.clear_image_cache.message",
                defaultValue: "This removes locally stored images. They will be downloaded again the next time you browse."
            ),
            actionTitle: interfaceLocalization.string("common.action.clear", defaultValue: "Clear"),
            onConfirm: onConfirm
        )
    }

    func showImageCacheCleared() {
        showAlert(
            title: interfaceLocalization.string("common.state.cleared", defaultValue: "Cleared"),
            message: interfaceLocalization.string(
                "main_member_setting.alert.image_cache_cleared.message",
                defaultValue: "The image cache has been cleared."
            )
        )
    }

    func showClearSearchHistoryConfirmation(onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: interfaceLocalization.string(
                "main_member_setting.alert.clear_search_history.title",
                defaultValue: "Clear Search History?"
            ),
            message: interfaceLocalization.string(
                "main_member_setting.alert.clear_search_history.message",
                defaultValue: "This permanently deletes all locally stored search terms."
            ),
            actionTitle: interfaceLocalization.string("common.action.clear", defaultValue: "Clear"),
            onConfirm: onConfirm
        )
    }

    func showSearchHistoryCleared() {
        showAlert(
            title: interfaceLocalization.string("common.state.cleared", defaultValue: "Cleared"),
            message: interfaceLocalization.string(
                "main_member_setting.alert.search_history_cleared.message",
                defaultValue: "Search history has been cleared."
            )
        )
    }

    func showClearAllLocalDataConfirmation(isMember: Bool, onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: interfaceLocalization.string(
                "main_member_setting.alert.clear_all_local_data.title",
                defaultValue: "Clear All Local Data"
            ),
            message: isMember
                ? interfaceLocalization.string(
                    "main_member_setting.alert.clear_all_local_data.member_message",
                    defaultValue: "This clears your profile, session, search history, and image cache, then returns to the sign-in screen."
                )
                : interfaceLocalization.string(
                    "main_member_setting.alert.clear_all_local_data.guest_message",
                    defaultValue: "This ends guest mode, clears search history and the image cache, then returns to the sign-in screen."
                ),
            actionTitle: interfaceLocalization.string("common.action.clear", defaultValue: "Clear"),
            onConfirm: onConfirm
        )
    }

    func showClearAllLocalDataFailed(
        onRetry: @escaping () -> Void,
        onClearLocalOnly: @escaping () -> Void
    ) {
        showRemoteSessionFailureAlert(
            title: interfaceLocalization.string(
                "main_member_setting.alert.revoke_session_failed.title",
                defaultValue: "Unable to Revoke TMDB Session"
            ),
            localOnlyTitle: interfaceLocalization.string(
                "main_member_setting.alert.clear_local_data_anyway",
                defaultValue: "Clear Local Data Anyway"
            ),
            onRetry: onRetry,
            onLocalOnly: onClearLocalOnly
        )
    }

    func showSecureSessionOperationFailed(onRetry: @escaping () -> Void) {
        let alert = UIAlertController(
            title: interfaceLocalization.string(
                "main_member_setting.alert.clear_sign_in_data_failed.title",
                defaultValue: "Unable to Clear Sign-in Data"
            ),
            message: interfaceLocalization.string(
                "main_member_setting.alert.clear_sign_in_data_failed.message",
                defaultValue: "The TMDB session may have expired, but sign-in data cannot be safely cleared from this device. Unlock the device and try again."
            ),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: interfaceLocalization.string("common.action.cancel", defaultValue: "Cancel"),
            style: .cancel
        ))
        alert.addAction(UIAlertAction(
            title: interfaceLocalization.string("common.action.retry", defaultValue: "Retry"),
            style: .default
        ) { _ in onRetry() })
        show(alert, using: .present)
    }

    func openTMDBAttribution(_ url: URL) {
        openSafari(url)
    }

    func showLogoutConfirmation(onConfirm: @escaping () -> Void) {
        showConfirmationAlert(
            title: interfaceLocalization.string("common.action.sign_out", defaultValue: "Sign Out"),
            message: interfaceLocalization.string(
                "main_member_setting.alert.sign_out.message",
                defaultValue: "Are you sure you want to sign out and return to the sign-in screen?"
            ),
            actionTitle: interfaceLocalization.string("common.action.sign_out", defaultValue: "Sign Out"),
            onConfirm: onConfirm
        )
    }

    func showLogoutFailed(
        onRetry: @escaping () -> Void,
        onClearLocalOnly: @escaping () -> Void
    ) {
        showRemoteSessionFailureAlert(
            title: interfaceLocalization.string(
                "main_member_setting.alert.sign_out_failed.title",
                defaultValue: "Sign Out Failed"
            ),
            localOnlyTitle: interfaceLocalization.string(
                "main_member_setting.alert.clear_local_sign_in_only",
                defaultValue: "Clear Local Sign-in Only"
            ),
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
            message: interfaceLocalization.string(
                "main_member_setting.alert.remote_session_failure.message",
                defaultValue: "CineBase cannot connect to TMDB to revoke the session. If you clear only local data, the remote session may remain active."
            ),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: interfaceLocalization.string("common.action.cancel", defaultValue: "Cancel"),
            style: .cancel
        ))
        alert.addAction(UIAlertAction(
            title: interfaceLocalization.string("common.action.retry", defaultValue: "Retry"),
            style: .default
        ) { _ in onRetry() })
        alert.addAction(UIAlertAction(title: localOnlyTitle, style: .destructive) { _ in
            onLocalOnly()
        })
        show(alert, using: .present)
    }
}
