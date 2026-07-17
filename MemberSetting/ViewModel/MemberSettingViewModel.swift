//
//  MemberSettingViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - MemberSettingAction

nonisolated enum MemberSettingAction: Sendable, Equatable {
    case refreshProfile
    case clearProfileCache
    case tmdbAttribution
    case logout
}

// MARK: - MemberSettingRowRole

nonisolated enum MemberSettingRowRole: Sendable, Equatable {
    case normal
    case destructive
}

// MARK: - MemberSettingRowAccessory

nonisolated enum MemberSettingRowAccessory: Sendable, Equatable {
    case none
    case disclosure
    case value(String)
    case toggle(isOn: Bool)
}

// MARK: - MemberSettingRowItem

nonisolated struct MemberSettingRowItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let systemImageName: String
    let role: MemberSettingRowRole
    let accessory: MemberSettingRowAccessory
    let action: MemberSettingAction?
}

// MARK: - MemberSettingSectionItem

nonisolated struct MemberSettingSectionItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let rows: [MemberSettingRowItem]
}

// MARK: - MemberSettingViewModel

@MainActor
final class MemberSettingViewModel {

    // MARK: - Properties

    private let sessionStore: SessionStoring
    private let userProfileStore: UserProfileStoring
    private let accountService: AccountServiceProtocol
    private let bundle: Bundle

    var sections: [MemberSettingSectionItem] {
        [
            MemberSettingSectionItem(
                id: "account",
                title: "帳號",
                rows: [
                    MemberSettingRowItem(
                        id: "refreshProfile",
                        title: "重新整理會員資料",
                        subtitle: nil,
                        systemImageName: "arrow.clockwise",
                        role: .normal,
                        accessory: .disclosure,
                        action: .refreshProfile
                    ),
                    MemberSettingRowItem(
                        id: "clearProfileCache",
                        title: "清除會員資料快取",
                        subtitle: nil,
                        systemImageName: "person.crop.circle.badge.xmark",
                        role: .normal,
                        accessory: .disclosure,
                        action: .clearProfileCache
                    )
                ]
            ),
            MemberSettingSectionItem(
                id: "about",
                title: "關於",
                rows: [
                    MemberSettingRowItem(
                        id: "appVersion",
                        title: "App 版本",
                        subtitle: nil,
                        systemImageName: "info.circle",
                        role: .normal,
                        accessory: .value(appVersionText),
                        action: nil
                    ),
                    MemberSettingRowItem(
                        id: "tmdbAttribution",
                        title: "TMDB 資料來源",
                        subtitle: nil,
                        systemImageName: "film.stack",
                        role: .normal,
                        accessory: .disclosure,
                        action: .tmdbAttribution
                    )
                ]
            ),
            MemberSettingSectionItem(
                id: "danger",
                title: "",
                rows: [
                    MemberSettingRowItem(
                        id: "logout",
                        title: "登出",
                        subtitle: nil,
                        systemImageName: "rectangle.portrait.and.arrow.right",
                        role: .destructive,
                        accessory: .none,
                        action: .logout
                    )
                ]
            )
        ]
    }

    var tmdbAttributionURL: URL? {
        URL(string: APIConfig.tmdbWebsiteBaseURL)
    }

    // MARK: - Initialization

    init(
        sessionStore: SessionStoring = SessionStore(),
        userProfileStore: UserProfileStoring = UserProfileStore(),
        accountService: AccountServiceProtocol = AccountService(),
        bundle: Bundle = .main
    ) {
        self.sessionStore = sessionStore
        self.userProfileStore = userProfileStore
        self.accountService = accountService
        self.bundle = bundle
    }

    // MARK: - Public Methods

    func section(at index: Int) -> MemberSettingSectionItem? {
        guard sections.indices.contains(index) else { return nil }
        return sections[index]
    }

    func row(at indexPath: IndexPath) -> MemberSettingRowItem? {
        guard let section = section(at: indexPath.section),
              section.rows.indices.contains(indexPath.item) else {
            return nil
        }

        return section.rows[indexPath.item]
    }

    func action(at indexPath: IndexPath) -> MemberSettingAction? {
        row(at: indexPath)?.action
    }

    func refreshProfile() async throws {
        guard case .user(let sessionId) = sessionStore.load() else { return }
        let account = try await accountService.fetchAccount(sessionId: sessionId)
        userProfileStore.save(account: account)
    }

    func clearProfileCache() {
        userProfileStore.clear()
    }

    func logout() {
        sessionStore.clear()
        userProfileStore.clear()
    }

    // MARK: - Private Methods

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
}
