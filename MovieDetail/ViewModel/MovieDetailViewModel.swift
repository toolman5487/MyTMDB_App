//
//  MovieDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - State

nonisolated enum MovieDetailViewState: Equatable {
    case idle
    case loading
    case loaded([MovieDetailSectionItem])
    case failed(ErrorMessage)
}

// MARK: - MovieDetailViewModel

@MainActor
final class MovieDetailViewModel {

    // MARK: - Properties

    private(set) var state: MovieDetailViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }
    var favoriteState: AccountMediaFavoriteState { accountMediaController.favoriteState }
    var ratingState: AccountMediaRatingState { accountMediaController.ratingState }
    var ratingDefaultValue: Double { accountMediaController.ratingDefaultValue }

    private var onStateChange: (@MainActor (MovieDetailViewState) -> Void)?
    private var onAccountStateChange: (@MainActor (AccountMediaFavoriteState, AccountMediaRatingState) -> Void)?
    private let loadMovieDetailUseCase: LoadMovieDetailUseCase
    private let accountMediaController: DetailAccountMediaStateController
    private let localization: AppInterfaceLocalization

    // MARK: - Initialization

    init(
        loadMovieDetailUseCase: LoadMovieDetailUseCase,
        accountMediaController: DetailAccountMediaStateController,
        localization: AppInterfaceLocalization
    ) {
        self.loadMovieDetailUseCase = loadMovieDetailUseCase
        self.accountMediaController = accountMediaController
        self.localization = localization
        self.accountMediaController.stateDidChange = { [weak self] in
            self?.notifyAccountStateChange()
        }
    }

    // MARK: - Output Binding

    func bind(
        onStateChange: @escaping @MainActor (MovieDetailViewState) -> Void,
        onAccountStateChange: @escaping @MainActor (AccountMediaFavoriteState, AccountMediaRatingState) -> Void
    ) {
        self.onStateChange = onStateChange
        self.onAccountStateChange = onAccountStateChange
        onStateChange(state)
        notifyAccountStateChange()
    }

    // MARK: - Data Loading

    func loadInitialContent(movieID: Int) async {
        state = .loading
        accountMediaController.prepareForLoading()

        do {
            async let content = loadMovieDetailUseCase(movieID: movieID)
            await accountMediaController.loadAccountMediaState(
                kind: .movie,
                mediaID: movieID,
                sourceDescription: "movie \(movieID)"
            )
            let loadedContent = try await content
            guard !Task.isCancelled else { return }

            accountMediaController.updateDefaultRating(
                fromPublicRating: loadedContent.movie.voteCount > 0
                    ? loadedContent.movie.voteAverage
                    : nil
            )
            state = .loaded(MovieDetailSectionBuilder.makeSections(
                content: loadedContent,
                interfaceLocalization: localization
            ))
        } catch let error as DomainError {
            guard !Task.isCancelled else { return }
            state = .failed(errorMessage(for: error))
            accountMediaController.markUnavailable()
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
            accountMediaController.markUnavailable()
        }
    }

    // MARK: - Favorite

    func toggleFavorite(movieID: Int) async -> ErrorMessage? {
        await accountMediaController.toggleFavorite(
            mediaID: movieID,
            mediaType: .movie,
            invalidMessage: ErrorMessage(
                title: localization.string("detail.error.favorite.title", defaultValue: "Unable to Favorite"),
                message: MediaKind.movie.invalidIdentifierMessage(localization: localization)
            )
        )
    }

    // MARK: - Rating

    func submitRating(movieID: Int, value: Double) async -> ErrorMessage? {
        await accountMediaController.submitRating(
            target: .movie(id: movieID),
            value: value,
            invalidMessage: ErrorMessage(
                title: localization.string("detail.error.rating.title", defaultValue: "Unable to Rate"),
                message: MediaKind.movie.invalidIdentifierMessage(localization: localization)
            )
        )
    }

    func deleteRating(movieID: Int) async -> ErrorMessage? {
        await accountMediaController.deleteRating(
            target: .movie(id: movieID),
            invalidMessage: ErrorMessage(
                title: localization.string("detail.error.delete_rating.title", defaultValue: "Unable to Delete Rating"),
                message: MediaKind.movie.invalidIdentifierMessage(localization: localization)
            )
        )
    }

    // MARK: - Private Helpers

    private func errorMessage(for error: DomainError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier(let kind):
            let mediaName = kind.displayName(localization: localization)
            return ErrorMessage(
                title: localization.formatted(
                    "detail.error.not_found.title_format",
                    defaultValue: "%@ Not Found",
                    mediaName
                ),
                message: kind.invalidIdentifierMessage(localization: localization),
                actionTitle: nil
            )
        }
    }

    private func notifyAccountStateChange() {
        onAccountStateChange?(favoriteState, ratingState)
    }

}
