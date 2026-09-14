//
//  AppIntentFavoriteActionHandler.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import Foundation

// MARK: - AppIntentFavoriteActionOutcome

nonisolated enum AppIntentFavoriteActionOutcome: Sendable, Equatable {
    case succeeded(message: String)
    case failed(message: String)

    var message: String {
        switch self {
        case .succeeded(let message), .failed(let message):
            return message
        }
    }

    var isSucceeded: Bool {
        switch self {
        case .succeeded:
            return true

        case .failed:
            return false
        }
    }
}

// MARK: - AppIntentFavoriteActionHandler

nonisolated struct AppIntentFavoriteActionHandler: Sendable {
    private let toggleFavorite: ToggleFavoriteUseCase

    init(toggleFavorite: ToggleFavoriteUseCase) {
        self.toggleFavorite = toggleFavorite
    }

    func updateFavorite(
        mediaType: MediaKind,
        mediaID: Int,
        favorite: Bool,
        displayTitle: String
    ) async -> AppIntentFavoriteActionOutcome {
        guard mediaID > 0 else {
            return .failed(message: "找不到要更新的項目。")
        }

        do {
            let result = try await toggleFavorite(
                kind: mediaType,
                mediaID: mediaID,
                isFavorite: favorite
            )

            guard result.isSuccess else {
                return .failed(message: result.message)
            }

            return .succeeded(
                message: successMessage(
                    mediaType: mediaType,
                    displayTitle: displayTitle,
                    favorite: favorite
                )
            )
        } catch AccountMediaError.requiresUserLogin {
            return .failed(message: "需要登入 TMDB 帳號後才能更新收藏。")
        } catch {
            return .failed(message: "更新收藏失敗：\(error.localizedDescription)")
        }
    }

    private func successMessage(
        mediaType: MediaKind,
        displayTitle: String,
        favorite: Bool
    ) -> String {
        let actionText = favorite ? "加入收藏" : "移出收藏"
        switch mediaType {
        case .movie:
            return "已將電影「\(displayTitle)」\(actionText)。"

        case .tv:
            return "已將影集「\(displayTitle)」\(actionText)。"
        }
    }
}
