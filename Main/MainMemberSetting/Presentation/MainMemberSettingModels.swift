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
    case clearSearchHistory
    case clearAllLocalData
    case tmdbAttribution
    case logout
    case login
    case register
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
    case guestPrompt
    case accountID
    case refreshProfile
    case clearProfileCache
    case clearImageCache
    case clearSearchHistory
    case clearAllLocalData
    case appVersion
    case apiDataLanguage
    case loginStatus
    case tmdbAttribution
    case appInterfaceLanguage
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

// MARK: - MainMemberSettingGuestPromptItem

nonisolated struct MainMemberSettingGuestPromptItem: Sendable, Equatable {
    let title: String
    let message: String
    let systemImageName: String
    let loginTitle: String
    let registerTitle: String
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

// MARK: - Accessibility

extension MainMemberSettingRowItem {

    func accessibilityText(localization: AppInterfaceLocalization) -> AccessibilityText {
        AccessibilityText(
            label: title,
            value: accessibilityValue(localization: localization),
            hint: accessibilityHint(localization: localization)
        )
    }

    private func accessibilityValue(localization: AppInterfaceLocalization) -> String? {
        switch accessory {
        case .none, .disclosure:
            return BaseDisplayTextFormatter.nonEmptyText(subtitle)

        case .value(let value):
            return BaseDisplayTextFormatter.metadata([subtitle, value])

        case .toggle(let isOn):
            return BaseDisplayTextFormatter.metadata([
                subtitle,
                isOn
                    ? localization.string("common.state.on", defaultValue: "On")
                    : localization.string("common.state.off", defaultValue: "Off")
            ])
        }
    }

    private func accessibilityHint(localization: AppInterfaceLocalization) -> String? {
        guard action != nil else { return nil }

        if role == .destructive {
            return localization.string(
                "common.accessibility.destructive_action.hint",
                defaultValue: "Double-tap to perform this action. This change may be irreversible."
            )
        }

        return localization.string(
            "common.accessibility.action.hint",
            defaultValue: "Double-tap to perform this action"
        )
    }
}

extension MainMemberSettingProfileSummaryItem {

    func accessibilityText(localization: AppInterfaceLocalization) -> AccessibilityText {
        AccessibilityText(
            label: displayName,
            value: BaseDisplayTextFormatter.nonEmptyText(usernameText),
            hint: localization.string(
                "main_member_setting.profile.accessibility.hint",
                defaultValue: "Double-tap to open Member Center"
            )
        )
    }
}
