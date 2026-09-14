//
//  MainMemberSettingViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - MainMemberSettingViewModel

@MainActor
final class MainMemberSettingViewModel {

    // MARK: - Properties

    private let sessionProvider: AuthSessionProviding
    private let profileProvider: AccountProfileProviding
    private let searchHistory: SearchHistoryProviding
    private let refreshAccountProfile: RefreshAccountProfileUseCase
    private let logoutUseCase: LogoutUseCase
    private let clearLocalData: ClearLocalDataUseCase
    private let localization: AppLocalization
    private let bundle: Bundle

    var sections: [MainMemberSettingSectionItem] {
        guard isMember else {
            return [
                guestSection,
                dataSection,
                preferencesSection,
                aboutSection
            ]
        }

        return [
            profileSection,
            accountSection,
            dataSection,
            preferencesSection,
            aboutSection,
            dangerSection
        ]
    }

    var isMember: Bool {
        if case .user = sessionProvider.currentSession() {
            return true
        }
        return false
    }

    var guestPrompt: MainMemberSettingGuestPromptItem {
        MainMemberSettingGuestPromptItem(
            title: "目前以訪客身分瀏覽",
            message: "登入 TMDB 帳號後即可同步收藏、片單與評分。",
            systemImageName: "person.crop.circle.badge.plus",
            loginTitle: "登入",
            registerTitle: "註冊"
        )
    }

    var tmdbAttributionURL: URL? {
        URL(string: TMDBResourceURL.websiteBaseURL)
    }

    var currentSession: AuthSession {
        sessionProvider.currentSession()
    }

    var profileSummary: MainMemberSettingProfileSummaryItem {
        guard let profile = profileProvider.cachedProfile() else {
            return MainMemberSettingProfileSummaryItem(
                displayName: "TMDB 會員",
                usernameText: "尚未同步 username",
                avatarURL: nil,
                avatarImageData: nil
            )
        }

        return MainMemberSettingProfileSummaryItem(
            displayName: profile.displayName,
            usernameText: "@\(profile.username)",
            avatarURL: profile.avatarURL,
            avatarImageData: profile.avatarImageData
        )
    }

    // MARK: - Initialization

    init(
        sessionProvider: AuthSessionProviding,
        profileProvider: AccountProfileProviding,
        searchHistory: SearchHistoryProviding,
        refreshAccountProfile: RefreshAccountProfileUseCase,
        logout: LogoutUseCase,
        clearLocalData: ClearLocalDataUseCase,
        localization: AppLocalization = .current,
        bundle: Bundle = .main
    ) {
        self.sessionProvider = sessionProvider
        self.profileProvider = profileProvider
        self.searchHistory = searchHistory
        self.refreshAccountProfile = refreshAccountProfile
        self.logoutUseCase = logout
        self.clearLocalData = clearLocalData
        self.localization = localization
        self.bundle = bundle
    }

    // MARK: - Public Methods

    func section(at index: Int) -> MainMemberSettingSectionItem? {
        guard sections.indices.contains(index) else { return nil }
        return sections[index]
    }

    func row(at indexPath: IndexPath) -> MainMemberSettingRowItem? {
        guard let section = section(at: indexPath.section),
              section.rows.indices.contains(indexPath.item) else {
            return nil
        }

        return section.rows[indexPath.item]
    }

    func action(at indexPath: IndexPath) -> MainMemberSettingAction? {
        row(at: indexPath)?.action
    }

    func refreshProfile() async throws {
        try await refreshAccountProfile()
    }

    func clearProfileCache() {
        profileProvider.clearCachedProfile()
    }

    func clearSearchHistory() {
        searchHistory.clear(scope: nil)
    }

    func clearAllLocalData() {
        clearLocalData()
    }

    func logout() {
        logoutUseCase()
    }

    // MARK: - Private Methods

    private var profileSection: MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .profile,
            rows: [
                MainMemberSettingRowItem(
                    kind: .profileSummary,
                    title: "會員資料",
                    systemImageName: "person.crop.circle",
                    action: .showMemberCenter
                )
            ]
        )
    }

    private var guestSection: MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .profile,
            rows: [
                MainMemberSettingRowItem(
                    kind: .guestPrompt,
                    title: "訪客",
                    systemImageName: "person.crop.circle.badge.plus"
                )
            ]
        )
    }

    private var accountSection: MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .account,
            title: "帳號",
            rows: [
                MainMemberSettingRowItem(
                    kind: .accountId,
                    title: "Account ID",
                    systemImageName: "number",
                    accessory: .value(accountIdText)
                ),
                MainMemberSettingRowItem(
                    kind: .refreshProfile,
                    title: "重新整理會員資料",
                    systemImageName: "arrow.clockwise",
                    accessory: .disclosure,
                    action: .refreshProfile
                ),
                MainMemberSettingRowItem(
                    kind: .clearProfileCache,
                    title: "清除會員資料快取",
                    systemImageName: "person.crop.circle.badge.xmark",
                    accessory: .disclosure,
                    action: .clearProfileCache
                )
            ]
        )
    }

    private var dataSection: MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .data,
            title: "快取與資料",
            rows: [
                MainMemberSettingRowItem(
                    kind: .clearImageCache,
                    title: "清除圖片快取",
                    systemImageName: "photo.badge.arrow.down",
                    accessory: .disclosure,
                    action: .clearImageCache
                ),
                MainMemberSettingRowItem(
                    kind: .clearSearchHistory,
                    title: "清除搜尋紀錄",
                    systemImageName: "magnifyingglass.circle",
                    accessory: .disclosure,
                    action: .clearSearchHistory
                ),
                MainMemberSettingRowItem(
                    kind: .clearAllLocalData,
                    title: "清除所有本機資料",
                    systemImageName: "trash",
                    role: .destructive,
                    accessory: .disclosure,
                    action: .clearAllLocalData
                )
            ]
        )
    }

    private var preferencesSection: MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .preferences,
            title: "偏好設定",
            rows: [
                MainMemberSettingRowItem(
                    kind: .defaultSort,
                    title: "預設列表排序",
                    systemImageName: "arrow.up.arrow.down",
                    accessory: .value("熱門度")
                ),
                MainMemberSettingRowItem(
                    kind: .defaultContentType,
                    title: "預設內容類型",
                    systemImageName: "rectangle.stack",
                    accessory: .value("電影與影集")
                )
            ]
        )
    }

    private var aboutSection: MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .about,
            title: "關於",
            rows: [
                MainMemberSettingRowItem(
                    kind: .appVersion,
                    title: "App 版本",
                    systemImageName: "info.circle",
                    accessory: .value(appVersionText)
                ),
                MainMemberSettingRowItem(
                    kind: .apiDataLanguage,
                    title: "API 資料語言",
                    systemImageName: "textformat",
                    accessory: .value(localization.languageParameter)
                ),
                MainMemberSettingRowItem(
                    kind: .loginStatus,
                    title: "目前登入狀態",
                    systemImageName: "person.crop.circle.badge.checkmark",
                    accessory: .value(loginStatusText)
                ),
                MainMemberSettingRowItem(
                    kind: .tmdbAttribution,
                    title: "TMDB 資料來源",
                    systemImageName: "film.stack",
                    accessory: .disclosure,
                    action: .tmdbAttribution
                )
            ]
        )
    }

    private var dangerSection: MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .danger,
            rows: [
                MainMemberSettingRowItem(
                    kind: .logout,
                    title: "登出",
                    systemImageName: "rectangle.portrait.and.arrow.right",
                    role: .destructive,
                    action: .logout
                )
            ]
        )
    }

    private var appVersionText: String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (version, build) {
        case (.some(let version), .some(let build)):
            return "\(version) (\(build))"

        case (.some(let version), .none):
            return version

        case (.none, .some(let build)):
            return build

        case (.none, .none):
            return "未知"
        }
    }

    private var accountIdText: String {
        guard let accountID = profileProvider.cachedProfile()?.id else {
            return "尚未同步"
        }

        return String(accountID)
    }

    private var loginStatusText: String {
        switch sessionProvider.currentSession() {
        case .loggedOut:
            return "未登入"

        case .guest:
            return "訪客"

        case .user:
            return "會員"
        }
    }

}
