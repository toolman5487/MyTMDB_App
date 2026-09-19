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
    private let localization: AppInterfaceLocalization

    // MARK: - Initialization

    init(
        sessionProvider: AuthSessionProviding,
        loadAccountMediaStateUseCase: LoadAccountMediaStateUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        submitRatingUseCase: SubmitRatingUseCase,
        deleteRatingUseCase: DeleteRatingUseCase,
        localization: AppInterfaceLocalization
    ) {
        self.sessionProvider = sessionProvider
        self.loadAccountMediaStateUseCase = loadAccountMediaStateUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.submitRatingUseCase = submitRatingUseCase
        self.deleteRatingUseCase = deleteRatingUseCase
        self.localization = localization
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
            return favoriteSignInRequiredMessage

        case .unavailable:
            return ErrorMessage(
                title: localization.string(
                    "detail.account_state.favorite_unavailable.title",
                    defaultValue: "Favorites Unavailable"
                ),
                message: localization.string(
                    "detail.account_state.favorite_unavailable.message",
                    defaultValue: "Favorite status cannot be loaded right now. Please try again later."
                )
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
                    return ErrorMessage(title: favoriteFailedTitle, message: result.message)
                }

                favoriteState = .ready(isFavorite: updatedFavoriteStatus)
                return nil
            } catch let error as AccountMediaError {
                favoriteState = .ready(isFavorite: currentFavoriteStatus)
                return favoriteErrorMessage(for: error, invalidMessage: invalidMessage)
            } catch {
                favoriteState = .ready(isFavorite: currentFavoriteStatus)
                return error.errorMessage(localization: localization)
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
            return invalidRatingValueMessage
        }

        switch ratingState {
        case .requiresUserLogin:
            return ratingSignInRequiredMessage

        case .unavailable:
            return ErrorMessage(
                title: localization.string(
                    "detail.account_state.rating_unavailable.title",
                    defaultValue: "Ratings Unavailable"
                ),
                message: ratingStateUnavailableMessage
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
                    return ErrorMessage(
                        title: localization.string(
                            "detail.account_state.rating_failed.title",
                            defaultValue: "Rating Failed"
                        ),
                        message: result.message
                    )
                }

                ratingState = .ready(value: normalizedValue)
                return nil
            } catch let error as AccountMediaError {
                ratingState = .ready(value: currentValue)
                return ratingErrorMessage(for: error, invalidMessage: invalidMessage)
            } catch {
                ratingState = .ready(value: currentValue)
                return error.errorMessage(localization: localization)
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
            return ratingSignInRequiredMessage

        case .unavailable:
            return ErrorMessage(
                title: localization.string(
                    "detail.account_state.delete_rating_unavailable.title",
                    defaultValue: "Rating Deletion Unavailable"
                ),
                message: ratingStateUnavailableMessage
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
                    return ErrorMessage(
                        title: localization.string(
                            "detail.account_state.delete_rating_failed.title",
                            defaultValue: "Unable to Delete Rating"
                        ),
                        message: result.message
                    )
                }

                ratingState = .ready(value: nil)
                return nil
            } catch let error as AccountMediaError {
                ratingState = .ready(value: currentValue)
                return ratingErrorMessage(for: error, invalidMessage: invalidMessage)
            } catch {
                ratingState = .ready(value: currentValue)
                return error.errorMessage(localization: localization)
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
            return favoriteSignInRequiredMessage

        case .invalidRatingValue:
            return ErrorMessage(
                title: favoriteFailedTitle,
                message: localization.string(
                    "detail.account_state.favorite_invalid_data.message",
                    defaultValue: "The favorite data is invalid. Please try again later."
                )
            )
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
            return invalidRatingValueMessage

        case .requiresUserLogin:
            ratingState = .requiresUserLogin
            return ratingSignInRequiredMessage
        }
    }

    // MARK: - Localized Messages

    private var signInRequiredTitle: String {
        localization.string(
            "detail.account_state.sign_in_required.title",
            defaultValue: "Sign-in Required"
        )
    }

    private var favoriteSignInRequiredMessage: ErrorMessage {
        ErrorMessage(
            title: signInRequiredTitle,
            message: localization.string(
                "detail.account_state.favorite_sign_in_required.message",
                defaultValue: "Sign in to your TMDB account to use favorites."
            )
        )
    }

    private var ratingSignInRequiredMessage: ErrorMessage {
        ErrorMessage(
            title: signInRequiredTitle,
            message: localization.string(
                "detail.account_state.rating_sign_in_required.message",
                defaultValue: "Sign in to your TMDB account to use ratings."
            )
        )
    }

    private var favoriteFailedTitle: String {
        localization.string(
            "detail.account_state.favorite_failed.title",
            defaultValue: "Favorite Update Failed"
        )
    }

    private var ratingStateUnavailableMessage: String {
        localization.string(
            "detail.account_state.rating_unavailable.message",
            defaultValue: "Rating status cannot be loaded right now. Please try again later."
        )
    }

    private var invalidRatingValueMessage: ErrorMessage {
        ErrorMessage(
            title: localization.string("detail.error.rating.title", defaultValue: "Unable to Rate"),
            message: localization.string(
                "detail.account_state.invalid_rating_value.message",
                defaultValue: "Ratings must be between 0.5 and 10."
            )
        )
    }

}
