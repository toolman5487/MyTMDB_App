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
    private let imageCache: ImageCacheClearing
    private let refreshAccountProfile: RefreshAccountProfileUseCase
    private let logoutUseCase: LogoutUseCase
    private let clearLocalData: ClearLocalDataUseCase
    private let localization: AppLocalization
    let interfaceLocalization: AppInterfaceLocalization
    private let bundle: Bundle

    private(set) var currentSession: AuthSession = .loggedOut
    private lazy var content: MainMemberSettingContent = makeContent(
        session: currentSession,
        profile: nil
    )

    var navigationTitle: String {
        content.navigationTitle
    }

    var sections: [MainMemberSettingSectionItem] {
        content.sections
    }

    var profileSummary: MainMemberSettingProfileSummaryItem {
        content.profileSummary
    }

    var guestPrompt: MainMemberSettingGuestPromptItem {
        content.guestPrompt
    }

    var isMember: Bool {
        if case .user = currentSession {
            return true
        }
        return false
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
        content = makeContent(session: session, profile: profile)
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

    private func makeContent(
        session: AuthSession,
        profile: AccountProfile?
    ) -> MainMemberSettingContent {
        MainMemberSettingPresentationBuilder.makeContent(
            session: session,
            profile: profile,
            appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            buildNumber: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            apiLanguageParameter: localization.languageParameter,
            localization: interfaceLocalization
        )
    }

}
