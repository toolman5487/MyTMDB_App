//
//  MemberSettingViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - MemberSettingAction

nonisolated enum MemberSettingAction: Sendable, Equatable {
    case logout
}

// MARK: - MemberSettingRowRole

nonisolated enum MemberSettingRowRole: Sendable, Equatable {
    case destructive
}

// MARK: - MemberSettingRowItem

nonisolated struct MemberSettingRowItem: Sendable, Equatable, Identifiable {
    let id: MemberSettingAction
    let title: String
    let systemImageName: String
    let role: MemberSettingRowRole
}

// MARK: - MemberSettingViewModel

@MainActor
final class MemberSettingViewModel {

    // MARK: - Properties

    private let sessionStore: SessionStoring

    let rows: [MemberSettingRowItem] = [
        MemberSettingRowItem(
            id: .logout,
            title: "登出",
            systemImageName: "rectangle.portrait.and.arrow.right",
            role: .destructive
        )
    ]

    // MARK: - Initialization

    init(sessionStore: SessionStoring = SessionStore()) {
        self.sessionStore = sessionStore
    }

    // MARK: - Public Methods

    func row(at index: Int) -> MemberSettingRowItem? {
        guard rows.indices.contains(index) else { return nil }
        return rows[index]
    }

    func action(at index: Int) -> MemberSettingAction? {
        row(at: index)?.id
    }

    func logout() {
        sessionStore.clear()
    }
}
