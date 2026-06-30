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
    var errorMessage: ErrorMessage { get }
}

// MARK: - Error Presentation

nonisolated extension Error {

    var errorMessage: ErrorMessage {
        if let error = self as? ErrorMessageConvertible {
            return error.errorMessage
        }

        return ErrorMessage(
            title: "發生錯誤",
            message: localizedDescription,
            actionTitle: "重試"
        )
    }
}

// MARK: - Empty State

nonisolated extension ErrorMessage {

    static let emptyContent = ErrorMessage(
        title: "目前沒有可顯示的內容",
        message: "請稍後再重新整理。",
        systemImageName: "tray",
        actionTitle: nil
    )
}
