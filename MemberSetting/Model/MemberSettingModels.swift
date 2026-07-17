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
    case refreshProfile
    case clearProfileCache
    case appVersion
    case tmdbAttribution
    case logout
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
    let id: String
    let title: String
    let rows: [MemberSettingRowItem]
}
