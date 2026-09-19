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
    let interfaceLocalization: AppInterfaceLocalization
    private let bundle: Bundle

    private(set) var sections: [MainMemberSettingSectionItem] = []
    private(set) var currentSession: AuthSession = .loggedOut
    private(set) var profileSummary: MainMemberSettingProfileSummaryItem

    var navigationTitle: String {
        interfaceLocalization.string(
            "main_member_setting.navigation.title",
            defaultValue: "Settings"
        )
    }

    var isMember: Bool {
        if case .user = currentSession {
            return true
        }
        return false
    }

    var guestPrompt: MainMemberSettingGuestPromptItem {
        MainMemberSettingGuestPromptItem(
            title: interfaceLocalization.string(
                "main_member_setting.guest.title",
                defaultValue: "Browsing as a Guest"
            ),
            message: interfaceLocalization.string(
                "main_member_setting.guest.message",
                defaultValue: "Sign in to your TMDB account to sync favorites, lists, and ratings."
            ),
            systemImageName: "person.crop.circle.badge.plus",
            loginTitle: interfaceLocalization.string(
                "common.action.sign_in",
                defaultValue: "Sign In"
            ),
            registerTitle: interfaceLocalization.string(
                "common.action.register",
                defaultValue: "Register"
            )
        )
    }

    var tmdbAttributionURL: URL? {
        URL(string: TMDBResourceURL.websiteBaseURL)
    }

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
        interfaceLocalization: AppInterfaceLocalization,
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
        self.interfaceLocalization = interfaceLocalization
        self.bundle = bundle
        self.profileSummary = MainMemberSettingProfileSummaryItem(
            displayName: interfaceLocalization.string(
                "main_member_setting.profile.placeholder_name",
                defaultValue: "TMDB Member"
            ),
            usernameText: interfaceLocalization.string(
                "main_member_setting.profile.username_not_synced",
                defaultValue: "Username not synced"
            ),
            avatarURL: nil,
            avatarImageData: nil
        )
        reloadContent()
    }

    // MARK: - Public Methods

    func reloadContent() {
        let session: AuthSession
        do {
            session = try sessionProvider.currentSession()
        } catch {
            AppLogger.security.error("Unable to read the secure authentication session")
            session = .loggedOut
        }
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

    func interfaceLanguage(for optionID: String) -> AppInterfaceLanguage? {
        guard let language = AppInterfaceLanguage(rawValue: optionID) else {
            return nil
        }
        guard language != interfaceLocalization.language else { return nil }
        return language
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

    func clearAllLocalData(logoutScope: LogoutScope = .remoteAndLocal) async throws {
        try await clearLocalData(logoutScope: logoutScope)
    }

    func logout(scope: LogoutScope = .remoteAndLocal) async throws {
        try await logoutUseCase(scope: scope)
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
            return MainMemberSettingProfileSummaryItem(
                displayName: interfaceLocalization.string(
                    "main_member_setting.profile.placeholder_name",
                    defaultValue: "TMDB Member"
                ),
                usernameText: interfaceLocalization.string(
                    "main_member_setting.profile.username_not_synced",
                    defaultValue: "Username not synced"
                ),
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

    private var profileSection: MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .profile,
            rows: [
                MainMemberSettingRowItem(
                    kind: .profileSummary,
                    title: interfaceLocalization.string(
                        "main_member_setting.profile.row.title",
                        defaultValue: "Profile"
                    ),
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
                    title: interfaceLocalization.string(
                        "common.account.guest",
                        defaultValue: "Guest"
                    ),
                    systemImageName: "person.crop.circle.badge.plus"
                )
            ]
        )
    }

    private func accountSection(profile: AccountProfile?) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .account,
            title: interfaceLocalization.string(
                "main_member_setting.account.section_title",
                defaultValue: "Account"
            ),
            rows: [
                MainMemberSettingRowItem(
                    kind: .accountID,
                    title: "Account ID",
                    systemImageName: "number",
                    accessory: .value(accountIDText(profile: profile))
                ),
                MainMemberSettingRowItem(
                    kind: .refreshProfile,
                    title: interfaceLocalization.string(
                        "main_member_setting.account.refresh_profile",
                        defaultValue: "Refresh Profile"
                    ),
                    systemImageName: "arrow.clockwise",
                    accessory: .disclosure,
                    action: .refreshProfile
                ),
                MainMemberSettingRowItem(
                    kind: .clearProfileCache,
                    title: interfaceLocalization.string(
                        "main_member_setting.account.clear_profile_cache",
                        defaultValue: "Clear Profile Cache"
                    ),
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
            title: interfaceLocalization.string(
                "main_member_setting.data.section_title",
                defaultValue: "Cache and Data"
            ),
            rows: [
                MainMemberSettingRowItem(
                    kind: .clearImageCache,
                    title: interfaceLocalization.string(
                        "main_member_setting.data.clear_image_cache",
                        defaultValue: "Clear Image Cache"
                    ),
                    systemImageName: "photo.badge.arrow.down",
                    accessory: .disclosure,
                    action: .clearImageCache
                ),
                MainMemberSettingRowItem(
                    kind: .clearSearchHistory,
                    title: interfaceLocalization.string(
                        "main_member_setting.data.clear_search_history",
                        defaultValue: "Clear Search History"
                    ),
                    systemImageName: "magnifyingglass.circle",
                    accessory: .disclosure,
                    action: .clearSearchHistory
                ),
                MainMemberSettingRowItem(
                    kind: .clearAllLocalData,
                    title: interfaceLocalization.string(
                        "main_member_setting.data.clear_all_local_data",
                        defaultValue: "Clear All Local Data"
                    ),
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
            title: interfaceLocalization.string(
                "main_member_setting.preferences.section_title",
                defaultValue: "Preferences"
            ),
            rows: [
                MainMemberSettingRowItem(
                    kind: .appInterfaceLanguage,
                    title: interfaceLocalization.string(
                        "main_member_setting.language.title",
                        defaultValue: "Language Preference"
                    ),
                    systemImageName: "globe",
                    accessory: .menu(
                        selectedOptionID: interfaceLocalization.language.rawValue,
                        options: interfaceLanguageMenuOptions
                    )
                ),
                MainMemberSettingRowItem(
                    kind: .defaultSort,
                    title: interfaceLocalization.string(
                        "main_member_setting.preferences.default_sort",
                        defaultValue: "Default List Sort"
                    ),
                    systemImageName: "arrow.up.arrow.down",
                    accessory: .value(interfaceLocalization.string(
                        "common.sort.popularity",
                        defaultValue: "Popularity"
                    ))
                ),
                MainMemberSettingRowItem(
                    kind: .defaultContentType,
                    title: interfaceLocalization.string(
                        "main_member_setting.preferences.default_content_type",
                        defaultValue: "Default Content Type"
                    ),
                    systemImageName: "rectangle.stack",
                    accessory: .value(interfaceLocalization.string(
                        "common.media.movies_and_tv",
                        defaultValue: "Movies and TV Shows"
                    ))
                )
            ]
        )
    }

    private var interfaceLanguageMenuOptions: [MainMemberSettingMenuOption] {
        AppInterfaceLanguage.allCases.map { language in
            MainMemberSettingMenuOption(
                id: language.rawValue,
                title: interfaceLanguageTitle(for: language)
            )
        }
    }

    private func interfaceLanguageTitle(for language: AppInterfaceLanguage) -> String {
        switch language {
        case .traditionalChinese:
            return interfaceLocalization.string(
                "main_member_setting.language.option.traditional_chinese",
                defaultValue: "Traditional Chinese"
            )

        case .english:
            return interfaceLocalization.string(
                "main_member_setting.language.option.english",
                defaultValue: "English"
            )
        }
    }

    private func aboutSection(session: AuthSession) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .about,
            title: interfaceLocalization.string(
                "main_member_setting.about.section_title",
                defaultValue: "About"
            ),
            rows: [
                MainMemberSettingRowItem(
                    kind: .appVersion,
                    title: interfaceLocalization.string(
                        "main_member_setting.about.app_version",
                        defaultValue: "App Version"
                    ),
                    systemImageName: "info.circle",
                    accessory: .value(appVersionText)
                ),
                MainMemberSettingRowItem(
                    kind: .apiDataLanguage,
                    title: interfaceLocalization.string(
                        "main_member_setting.about.api_data_language",
                        defaultValue: "API Data Language"
                    ),
                    systemImageName: "textformat",
                    accessory: .value(localization.languageParameter)
                ),
                MainMemberSettingRowItem(
                    kind: .loginStatus,
                    title: interfaceLocalization.string(
                        "main_member_setting.about.login_status",
                        defaultValue: "Current Sign-in Status"
                    ),
                    systemImageName: "person.crop.circle.badge.checkmark",
                    accessory: .value(loginStatusText(session: session))
                ),
                MainMemberSettingRowItem(
                    kind: .tmdbAttribution,
                    title: interfaceLocalization.string(
                        "main_member_setting.about.tmdb_attribution",
                        defaultValue: "TMDB Data Source"
                    ),
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
                    title: interfaceLocalization.string(
                        "common.action.sign_out",
                        defaultValue: "Sign Out"
                    ),
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
            return interfaceLocalization.string(
                "common.value.unknown",
                defaultValue: "Unknown"
            )
        }
    }

    private func accountIDText(profile: AccountProfile?) -> String {
        guard let accountID = profile?.id else {
            return interfaceLocalization.string(
                "common.value.not_synced",
                defaultValue: "Not Synced"
            )
        }

        return String(accountID)
    }

    private func loginStatusText(session: AuthSession) -> String {
        switch session {
        case .loggedOut:
            return interfaceLocalization.string(
                "common.account.signed_out",
                defaultValue: "Signed Out"
            )

        case .guest:
            return interfaceLocalization.string(
                "common.account.guest",
                defaultValue: "Guest"
            )

        case .user:
            return interfaceLocalization.string(
                "common.account.member",
                defaultValue: "Member"
            )
        }
    }

}
