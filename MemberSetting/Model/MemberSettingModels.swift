//
//  MemberSettingModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/17.
//

import Foundation

// MARK: - MemberSettingAction

nonisolated enum MemberSettingAction: Sendable, Equatable {
    case refreshProfile
    case clearProfileCache
    case clearImageCache
    case clearAllLocalData
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

// MARK: - MemberSettingRowKind

nonisolated enum MemberSettingRowKind: Sendable, Equatable, Hashable {
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

// MARK: - MemberSettingSectionKind

nonisolated enum MemberSettingSectionKind: Sendable, Equatable, Hashable {
    case profile
    case account
    case data
    case preferences
    case about
    case danger
}

// MARK: - MemberSettingRowItem

nonisolated struct MemberSettingRowItem: Sendable, Equatable, Identifiable {
    let kind: MemberSettingRowKind
    let title: String
    let subtitle: String?
    let systemImageName: String
    let role: MemberSettingRowRole
    let accessory: MemberSettingRowAccessory
    let action: MemberSettingAction?

    init(
        kind: MemberSettingRowKind,
        title: String,
        subtitle: String? = nil,
        systemImageName: String,
        role: MemberSettingRowRole = .normal,
        accessory: MemberSettingRowAccessory = .none,
        action: MemberSettingAction? = nil
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.systemImageName = systemImageName
        self.role = role
        self.accessory = accessory
        self.action = action
    }

    var id: MemberSettingRowKind {
        kind
    }
}

// MARK: - MemberSettingProfileSummaryItem

nonisolated struct MemberSettingProfileSummaryItem: Sendable, Equatable {
    let displayName: String
    let usernameText: String
    let avatarURL: URL?
    let avatarImageData: Data?
}

// MARK: - MemberSettingSectionItem

nonisolated struct MemberSettingSectionItem: Sendable, Equatable, Identifiable {
    let kind: MemberSettingSectionKind
    let title: String
    let rows: [MemberSettingRowItem]

    init(
        kind: MemberSettingSectionKind,
        title: String = "",
        rows: [MemberSettingRowItem]
    ) {
        self.kind = kind
        self.title = title
        self.rows = rows
    }

    var id: MemberSettingSectionKind {
        kind
    }
}
