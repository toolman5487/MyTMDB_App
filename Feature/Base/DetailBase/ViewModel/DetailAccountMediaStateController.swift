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

    private let sessionProvider: AuthSessionProviding
    private let loadAccountMediaStateUseCase: LoadAccountMediaStateUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let submitRatingUseCase: SubmitRatingUseCase
    private let deleteRatingUseCase: DeleteRatingUseCase

    // MARK: - Initialization

    init(
        sessionProvider: AuthSessionProviding,
        loadAccountMediaStateUseCase: LoadAccountMediaStateUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        submitRatingUseCase: SubmitRatingUseCase,
        deleteRatingUseCase: DeleteRatingUseCase
    ) {
        self.sessionProvider = sessionProvider
        self.loadAccountMediaStateUseCase = loadAccountMediaStateUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.submitRatingUseCase = submitRatingUseCase
        self.deleteRatingUseCase = deleteRatingUseCase
    }

    // MARK: - State Lifecycle

    func prepareForLoading() {
        favoriteState = .unavailable
        ratingState = .unavailable
        ratingDefaultValue = AccountMediaRatingValue.fallback
    }

    func updateDefaultRating(fromPublicRating publicRating: Double?) {
        ratingDefaultValue = AccountMediaRatingValue.defaultValue(fromPublicRating: publicRating)
    }

    func applyLoadedRating(value: Double?) {
        guard isUserAuthenticated else {
            ratingState = .requiresUserLogin
            return
        }

        ratingState = .ready(value: value)
    }

    func loadAccountMediaState(
        kind: MediaKind,
        mediaID: Int,
        sourceDescription: String
    ) async {
        guard isUserAuthenticated else {
            favoriteState = .requiresUserLogin
            ratingState = .requiresUserLogin
            return
        }

        do {
            let loadedAccountStates = try await loadAccountMediaStateUseCase(
                kind: kind,
                mediaID: mediaID
            )
            favoriteState = .ready(isFavorite: loadedAccountStates.isFavorite)
            ratingState = .ready(value: loadedAccountStates.rating)
        } catch AccountMediaError.requiresUserLogin {
            favoriteState = .requiresUserLogin
            ratingState = .requiresUserLogin
        } catch {
            guard !Task.isCancelled else { return }
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
    }

    func markRatingUnavailable() {
        ratingState = .unavailable
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
            let updatedFavoriteStatus = !currentFavoriteStatus
            favoriteState = .updating(isFavorite: updatedFavoriteStatus)

            do {
                let result = try await toggleFavoriteUseCase(
                    kind: mediaType,
                    mediaID: mediaID,
                    isFavorite: updatedFavoriteStatus
                )

                guard result.isSuccess else {
                    favoriteState = .ready(isFavorite: currentFavoriteStatus)
                    return ErrorMessage(title: "收藏失敗", message: result.message)
                }

                favoriteState = .ready(isFavorite: updatedFavoriteStatus)
                return nil
            } catch let error as AccountMediaError {
                favoriteState = .ready(isFavorite: currentFavoriteStatus)
                return favoriteErrorMessage(for: error, invalidMessage: invalidMessage)
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
            ratingState = .updating(value: normalizedValue)

            do {
                let result = try await submitRatingUseCase(
                    target: target,
                    value: normalizedValue
                )

                guard result.isSuccess else {
                    ratingState = .ready(value: currentValue)
                    return ErrorMessage(title: "評分失敗", message: result.message)
                }

                ratingState = .ready(value: normalizedValue)
                return nil
            } catch let error as AccountMediaError {
                ratingState = .ready(value: currentValue)
                return ratingErrorMessage(for: error, invalidMessage: invalidMessage)
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

            ratingState = .updating(value: nil)

            do {
                let result = try await deleteRatingUseCase(target: target)

                guard result.isSuccess else {
                    ratingState = .ready(value: currentValue)
                    return ErrorMessage(title: "刪除評分失敗", message: result.message)
                }

                ratingState = .ready(value: nil)
                return nil
            } catch let error as AccountMediaError {
                ratingState = .ready(value: currentValue)
                return ratingErrorMessage(for: error, invalidMessage: invalidMessage)
            } catch {
                ratingState = .ready(value: currentValue)
                return error.errorMessage
            }
        }
    }

    // MARK: - Session

    private var isUserAuthenticated: Bool {
        guard let session = try? sessionProvider.currentSession() else { return false }

        if case .user = session {
            return true
        }
        return false
    }

    // MARK: - Error Mapping

    private func favoriteErrorMessage(
        for error: AccountMediaError,
        invalidMessage: ErrorMessage
    ) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return invalidMessage

        case .requiresUserLogin:
            favoriteState = .requiresUserLogin
            return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用收藏功能。")

        case .invalidRatingValue:
            return ErrorMessage(title: "收藏失敗", message: "收藏資料不正確，請稍後再試。")
        }
    }

    private func ratingErrorMessage(
        for error: AccountMediaError,
        invalidMessage: ErrorMessage
    ) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return invalidMessage

        case .invalidRatingValue:
            return ErrorMessage(title: "無法評分", message: "評分需介於 0.5 到 10 分之間。")

        case .requiresUserLogin:
            ratingState = .requiresUserLogin
            return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用評分功能。")
        }
    }

}
