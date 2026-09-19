//
//  ErrorMessage.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - ErrorMessage

nonisolated struct ErrorMessage: Sendable, Equatable {
    let title: String
    let message: String
    let systemImageName: String
    let actionTitle: String?

    init(
        title: String,
        message: String,
        systemImageName: String = "exclamationmark.triangle",
        actionTitle: String? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImageName = systemImageName
        self.actionTitle = actionTitle
    }
}

// MARK: - ErrorMessageConvertible

nonisolated protocol ErrorMessageConvertible {
    func errorMessage(localization: AppInterfaceLocalization) -> ErrorMessage
}

// MARK: - Error Presentation

nonisolated extension Error {

    var errorMessage: ErrorMessage {
        errorMessage(localization: .traditionalChinese)
    }

    func errorMessage(localization: AppInterfaceLocalization) -> ErrorMessage {
        if let error = self as? ErrorMessageConvertible {
            return error.errorMessage(localization: localization)
        }

        return ErrorMessage(
            title: localization.string(
                "error.generic.title",
                defaultValue: "Something Went Wrong"
            ),
            message: localizedDescription,
            actionTitle: localization.string(
                "common.action.retry",
                defaultValue: "Retry"
            )
        )
    }
}

// MARK: - Empty State

nonisolated extension ErrorMessage {

    static func emptyContent(localization: AppInterfaceLocalization) -> ErrorMessage {
        ErrorMessage(
            title: localization.string(
                "empty.content.title",
                defaultValue: "Nothing to Show"
            ),
            message: localization.string(
                "empty.content.message",
                defaultValue: "Try refreshing again later."
            ),
            systemImageName: "tray",
            actionTitle: nil
        )
    }

    static func emptyMemberCenterContent(
        localization: AppInterfaceLocalization
    ) -> ErrorMessage {
        ErrorMessage(
            title: localization.string(
                "empty.member_center.title",
                defaultValue: "No Account Content Yet"
            ),
            message: localization.string(
                "empty.member_center.message",
                defaultValue: "Favorites, watchlists, ratings, and lists will appear here."
            ),
            systemImageName: "tray",
            actionTitle: nil
        )
    }
}
