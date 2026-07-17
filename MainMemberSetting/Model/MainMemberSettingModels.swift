//
//  MainMemberSettingModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/17.
//

import Foundation

// MARK: - MainMemberSettingAction

nonisolated enum MainMemberSettingAction: Sendable, Equatable {
    case showMemberCenter
    case refreshProfile
    case clearProfileCache
    case clearImageCache
    case clearAllLocalData
    case tmdbAttribution
    case logout
}

// MARK: - MainMemberSettingRowRole

nonisolated enum MainMemberSettingRowRole: Sendable, Equatable {
    case normal
    case destructive
}

// MARK: - MainMemberSettingRowAccessory

nonisolated enum MainMemberSettingRowAccessory: Sendable, Equatable {
    case none
    case disclosure
    case value(String)
    case toggle(isOn: Bool)
}

// MARK: - MainMemberSettingRowKind

nonisolated enum MainMemberSettingRowKind: Sendable, Equatable, Hashable {
    case profileSummary
    case accountId
    case refreshProfile
    case clearProfileCache
    case clearImageCache
    case clearSearchHistory
    case clearAllLocalData
    case appVersion
    case apiDataLanguage
    case loginStatus
    case tmdbAttribution
    case defaultSort
    case defaultContentType
    case logout
}

// MARK: - MainMemberSettingSectionKind

nonisolated enum MainMemberSettingSectionKind: Sendable, Equatable, Hashable {
    case profile
    case account
    case data
    case preferences
    case about
    case danger
}

// MARK: - MainMemberSettingRowItem

nonisolated struct MainMemberSettingRowItem: Sendable, Equatable, Identifiable {
    let kind: MainMemberSettingRowKind
    let title: String
    let subtitle: String?
    let systemImageName: String
    let role: MainMemberSettingRowRole
    let accessory: MainMemberSettingRowAccessory
    let action: MainMemberSettingAction?

    init(
        kind: MainMemberSettingRowKind,
        title: String,
        subtitle: String? = nil,
        systemImageName: String,
        role: MainMemberSettingRowRole = .normal,
        accessory: MainMemberSettingRowAccessory = .none,
        action: MainMemberSettingAction? = nil
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.systemImageName = systemImageName
        self.role = role
        self.accessory = accessory
        self.action = action
    }

    var id: MainMemberSettingRowKind {
        kind
    }
}

// MARK: - MainMemberSettingProfileSummaryItem

nonisolated struct MainMemberSettingProfileSummaryItem: Sendable, Equatable {
    let displayName: String
    let usernameText: String
    let avatarURL: URL?
    let avatarImageData: Data?
}

// MARK: - MainMemberSettingSectionItem

nonisolated struct MainMemberSettingSectionItem: Sendable, Equatable, Identifiable {
    let kind: MainMemberSettingSectionKind
    let title: String
    let rows: [MainMemberSettingRowItem]

    init(
        kind: MainMemberSettingSectionKind,
        title: String = "",
        rows: [MainMemberSettingRowItem]
    ) {
        self.kind = kind
        self.title = title
        self.rows = rows
    }

    var id: MainMemberSettingSectionKind {
        kind
    }
}
