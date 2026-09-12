//
//  DetailAccountMediaStateController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/19.
//

import Foundation

// MARK: - DetailAccountMediaStateController

@MainActor
final class DetailAccountMediaStateController {

    // MARK: - Types

    typealias AccountStatesProvider = (String) async throws -> AccountMediaStatesResponse

    // MARK: - Properties

    private(set) var favoriteState: AccountMediaFavoriteState = .unavailable {
        didSet {
            guard oldValue != favoriteState else { return }
            stateDidChange?()
        }
    }

    private(set) var ratingState: AccountMediaRatingState = .unavailable {
        didSet {
            guard oldValue != ratingState else { return }
            stateDidChange?()
        }
    }

    private(set) var ratingDefaultValue: Double = AccountMediaRatingValue.fallback {
        didSet {
            guard oldValue != ratingDefaultValue else { return }
            stateDidChange?()
        }
    }

    var stateDidChange: (@MainActor () -> Void)?

    private let sessionStore: SessionStoring
    private let accountService: AccountServiceProtocol
    private let accountMediaService: MemberCenterServicing
    private var favoriteSession: DetailAccountMediaFavoriteSession?
    private var ratingSession: DetailAccountMediaRatingSession?

    // MARK: - Initialization

    init(
        sessionStore: SessionStoring,
        accountService: AccountServiceProtocol,
        accountMediaService: MemberCenterServicing
    ) {
        self.sessionStore = sessionStore
        self.accountService = accountService
        self.accountMediaService = accountMediaService
    }

    // MARK: - State Lifecycle

    func prepareForLoading() {
        favoriteState = .unavailable
        ratingState = .unavailable
        ratingDefaultValue = AccountMediaRatingValue.fallback
        favoriteSession = nil
        ratingSession = nil
    }

    func updateDefaultRating(fromPublicRating publicRating: Double?) {
        ratingDefaultValue = AccountMediaRatingValue.defaultValue(fromPublicRating: publicRating)
    }

    func applyLoadedRating(value: Double?) {
        guard case .user(let sessionID) = sessionStore.load() else {
            ratingSession = nil
            ratingState = .requiresUserLogin
            return
        }

        ratingSession = DetailAccountMediaRatingSession(sessionID: sessionID)
        ratingState = .ready(value: value)
    }

    func loadAccountMediaState(
        sourceDescription: String,
        accountStatesProvider: AccountStatesProvider
    ) async {
        guard case .user(let sessionID) = sessionStore.load() else {
            favoriteSession = nil
            ratingSession = nil
            favoriteState = .requiresUserLogin
            ratingState = .requiresUserLogin
            return
        }

        do {
            let loadedAccount = try await accountService.fetchAccount(sessionId: sessionID)
            let loadedAccountStates = try await accountStatesProvider(sessionID)
            favoriteSession = DetailAccountMediaFavoriteSession(accountID: loadedAccount.id, sessionID: sessionID)
            ratingSession = DetailAccountMediaRatingSession(sessionID: sessionID)
            favoriteState = .ready(isFavorite: loadedAccountStates.favorite)
            ratingState = .ready(value: loadedAccountStates.rated.value)
        } catch {
            guard !Task.isCancelled else { return }
            favoriteSession = nil
            ratingSession = nil
            AppLogger.network.warning(
                """
                Failed to load \(sourceDescription, privacy: .public) account media state: \
                \(error.localizedDescription, privacy: .public)
                """
            )
            favoriteState = .unavailable
            ratingState = .unavailable
        }
    }

    func markUnavailable() {
        favoriteState = .unavailable
        ratingState = .unavailable
        ratingDefaultValue = AccountMediaRatingValue.fallback
        favoriteSession = nil
        ratingSession = nil
    }

    func markRatingUnavailable() {
        ratingState = .unavailable
        ratingSession = nil
    }

    // MARK: - Favorite Mutation

    func toggleFavorite(
        mediaID: Int,
        mediaType: MediaKind,
        invalidMessage: ErrorMessage
    ) async -> ErrorMessage? {
        guard mediaID > 0 else { return invalidMessage }

        switch favoriteState {
        case .requiresUserLogin:
            return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用收藏功能。")

        case .unavailable:
            return ErrorMessage(
                title: "暫時無法收藏",
                message: "目前無法取得收藏狀態，請稍後再試。"
            )

        case .updating:
            return nil

        case .ready(let currentFavoriteStatus):
            guard let favoriteSession else {
                favoriteState = .requiresUserLogin
                return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用收藏功能。")
            }

            let updatedFavoriteStatus = !currentFavoriteStatus
            favoriteState = .updating(isFavorite: updatedFavoriteStatus)

            do {
                let response = try await accountMediaService.updateFavorite(
                    accountId: favoriteSession.accountID,
                    sessionId: favoriteSession.sessionID,
                    request: MemberCenterFavoriteStatusRequest(
                        mediaType: mediaType,
                        mediaID: mediaID,
                        favorite: updatedFavoriteStatus
                    )
                )

                guard response.success else {
                    favoriteState = .ready(isFavorite: currentFavoriteStatus)
                    return ErrorMessage(title: "收藏失敗", message: response.statusMessage)
                }

                favoriteState = .ready(isFavorite: updatedFavoriteStatus)
                return nil
            } catch {
                favoriteState = .ready(isFavorite: currentFavoriteStatus)
                return error.errorMessage
            }
        }
    }

    // MARK: - Rating Mutations

    func submitRating(
        target: AccountMediaRatingTarget,
        value: Double,
        invalidMessage: ErrorMessage
    ) async -> ErrorMessage? {
        guard target.isValid else { return invalidMessage }

        let normalizedValue = AccountMediaRatingValue.normalized(value)
        guard AccountMediaRatingValue.isValid(normalizedValue) else {
            return ErrorMessage(title: "無法評分", message: "評分需介於 0.5 到 10 分之間。")
        }

        switch ratingState {
        case .requiresUserLogin:
            return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用評分功能。")

        case .unavailable:
            return ErrorMessage(
                title: "暫時無法評分",
                message: "目前無法取得評分狀態，請稍後再試。"
            )

        case .updating:
            return nil

        case .ready(let currentValue):
            guard let ratingSession else {
                ratingState = .requiresUserLogin
                return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用評分功能。")
            }

            ratingState = .updating(value: normalizedValue)

            do {
                let response = try await accountMediaService.submitRating(
                    sessionId: ratingSession.sessionID,
                    target: target,
                    value: normalizedValue
                )

                guard response.success else {
                    ratingState = .ready(value: currentValue)
                    return ErrorMessage(title: "評分失敗", message: response.statusMessage)
                }

                ratingState = .ready(value: normalizedValue)
                return nil
            } catch {
                ratingState = .ready(value: currentValue)
                return error.errorMessage
            }
        }
    }

    func deleteRating(
        target: AccountMediaRatingTarget,
        invalidMessage: ErrorMessage
    ) async -> ErrorMessage? {
        guard target.isValid else { return invalidMessage }

        switch ratingState {
        case .requiresUserLogin:
            return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用評分功能。")

        case .unavailable:
            return ErrorMessage(
                title: "暫時無法刪除評分",
                message: "目前無法取得評分狀態，請稍後再試。"
            )

        case .updating:
            return nil

        case .ready(let currentValue):
            guard currentValue != nil else { return nil }

            guard let ratingSession else {
                ratingState = .requiresUserLogin
                return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用評分功能。")
            }

            ratingState = .updating(value: nil)

            do {
                let response = try await accountMediaService.deleteRating(
                    sessionId: ratingSession.sessionID,
                    target: target
                )

                guard response.success else {
                    ratingState = .ready(value: currentValue)
                    return ErrorMessage(title: "刪除評分失敗", message: response.statusMessage)
                }

                ratingState = .ready(value: nil)
                return nil
            } catch {
                ratingState = .ready(value: currentValue)
                return error.errorMessage
            }
        }
    }

}

// MARK: - DetailAccountMediaFavoriteSession

private nonisolated struct DetailAccountMediaFavoriteSession: Sendable, Equatable {
    let accountID: Int
    let sessionID: String
}

private nonisolated struct DetailAccountMediaRatingSession: Sendable, Equatable {
    let sessionID: String
}

// MARK: - AccountMediaRatingTarget

private extension AccountMediaRatingTarget {

    var isValid: Bool {
        switch self {
        case .movie(let id):
            return id > 0

        case .tv(let seriesID):
            return seriesID > 0

        case .episode(let seriesID, let seasonNumber, let episodeNumber):
            return seriesID > 0 && seasonNumber >= 0 && episodeNumber > 0
        }
    }
}
