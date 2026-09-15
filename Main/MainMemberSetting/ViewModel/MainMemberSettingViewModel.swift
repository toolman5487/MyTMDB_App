//
//  MainMemberSettingViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - MainMemberSettingViewModel

/// Synchronous query/action model; it intentionally has no asynchronous state binding.
@MainActor
final class MainMemberSettingViewModel {

    // MARK: - Properties

    private let sessionProvider: AuthSessionProviding
    private let profileProvider: AccountProfileProviding
    private let searchHistory: SearchHistoryProviding
    private let imageCache: ImageCacheClearing
    private let refreshAccountProfile: RefreshAccountProfileUseCase
    private let logoutUseCase: LogoutUseCase
    private let clearLocalData: ClearLocalDataUseCase
    private let localization: AppLocalization
    private let bundle: Bundle

    private(set) var sections: [MainMemberSettingSectionItem] = []
    private(set) var currentSession: AuthSession = .loggedOut
    private(set) var profileSummary = MainMemberSettingViewModel.placeholderProfileSummary

    var isMember: Bool {
        if case .user = currentSession {
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

    private static let placeholderProfileSummary = MainMemberSettingProfileSummaryItem(
        displayName: "TMDB 會員",
        usernameText: "尚未同步 username",
        avatarURL: nil,
        avatarImageData: nil
    )

    // MARK: - Initialization

    init(
        sessionProvider: AuthSessionProviding,
        profileProvider: AccountProfileProviding,
        searchHistory: SearchHistoryProviding,
        imageCache: ImageCacheClearing,
        refreshAccountProfile: RefreshAccountProfileUseCase,
        logout: LogoutUseCase,
        clearLocalData: ClearLocalDataUseCase,
        localization: AppLocalization = .current,
        bundle: Bundle = .main
    ) {
        self.sessionProvider = sessionProvider
        self.profileProvider = profileProvider
        self.searchHistory = searchHistory
        self.imageCache = imageCache
        self.refreshAccountProfile = refreshAccountProfile
        self.logoutUseCase = logout
        self.clearLocalData = clearLocalData
        self.localization = localization
        self.bundle = bundle
        reloadContent()
    }

    // MARK: - Public Methods

    func reloadContent() {
        let session = sessionProvider.currentSession()
        let profile: AccountProfile? = if case .user = session {
            profileProvider.cachedProfile()
        } else {
            nil
        }

        currentSession = session
        profileSummary = makeProfileSummary(profile: profile)
        sections = makeSections(session: session, profile: profile)
    }

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
        reloadContent()
    }

    func clearProfileCache() {
        profileProvider.clearCachedProfile()
        reloadContent()
    }

    func clearImageCache() async {
        await imageCache.clearImageCache()
    }

    func clearSearchHistory() {
        searchHistory.clear(scope: nil)
        reloadContent()
    }

    func clearAllLocalData() async {
        await clearLocalData()
    }

    func logout() {
        logoutUseCase()
    }

    // MARK: - Private Methods

    private func makeSections(
        session: AuthSession,
        profile: AccountProfile?
    ) -> [MainMemberSettingSectionItem] {
        guard case .user = session else {
            return [
                guestSection,
                dataSection,
                preferencesSection,
                aboutSection(session: session)
            ]
        }

        return [
            profileSection,
            accountSection(profile: profile),
            dataSection,
            preferencesSection,
            aboutSection(session: session),
            dangerSection
        ]
    }

    private func makeProfileSummary(profile: AccountProfile?) -> MainMemberSettingProfileSummaryItem {
        guard let profile else {
            return Self.placeholderProfileSummary
        }

        return MainMemberSettingProfileSummaryItem(
            displayName: profile.displayName,
            usernameText: "@\(profile.username)",
            avatarURL: profile.avatarURL,
            avatarImageData: profile.avatarImageData
        )
    }

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

    private func accountSection(profile: AccountProfile?) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .account,
            title: "帳號",
            rows: [
                MainMemberSettingRowItem(
                    kind: .accountID,
                    title: "Account ID",
                    systemImageName: "number",
                    accessory: .value(accountIDText(profile: profile))
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

    private func aboutSection(session: AuthSession) -> MainMemberSettingSectionItem {
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
                    accessory: .value(loginStatusText(session: session))
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

    private func accountIDText(profile: AccountProfile?) -> String {
        guard let accountID = profile?.id else {
            return "尚未同步"
        }

        return String(accountID)
    }

    private func loginStatusText(session: AuthSession) -> String {
        switch session {
        case .loggedOut:
            return "未登入"

        case .guest:
            return "訪客"

        case .user:
            return "會員"
        }
    }

}
