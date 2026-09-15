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

    // MARK: - Initialization

    init(
        loadMovieDetailUseCase: LoadMovieDetailUseCase,
        accountMediaController: DetailAccountMediaStateController
    ) {
        self.loadMovieDetailUseCase = loadMovieDetailUseCase
        self.accountMediaController = accountMediaController
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
            state = .loaded(MovieDetailSectionBuilder.makeSections(content: loadedContent))
        } catch let error as DomainError {
            guard !Task.isCancelled else { return }
            state = .failed(Self.errorMessage(for: error))
            accountMediaController.markUnavailable()
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
            accountMediaController.markUnavailable()
        }
    }

    // MARK: - Favorite

    func toggleFavorite(movieID: Int) async -> ErrorMessage? {
        await accountMediaController.toggleFavorite(
            mediaID: movieID,
            mediaType: .movie,
            invalidMessage: ErrorMessage(
                title: "無法收藏",
                message: "電影 ID 不正確，請返回上一頁後再試。"
            )
        )
    }

    // MARK: - Rating

    func submitRating(movieID: Int, value: Double) async -> ErrorMessage? {
        await accountMediaController.submitRating(
            target: .movie(id: movieID),
            value: value,
            invalidMessage: ErrorMessage(
                title: "無法評分",
                message: "電影 ID 不正確，請返回上一頁後再試。"
            )
        )
    }

    func deleteRating(movieID: Int) async -> ErrorMessage? {
        await accountMediaController.deleteRating(
            target: .movie(id: movieID),
            invalidMessage: ErrorMessage(
                title: "無法刪除評分",
                message: "電影 ID 不正確，請返回上一頁後再試。"
            )
        )
    }

    // MARK: - Private Helpers

    private static func errorMessage(for error: DomainError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier(let kind):
            return ErrorMessage(
                title: "找不到\(kind.displayName)",
                message: "\(kind.displayName) ID 不正確，請返回上一頁後再試。",
                actionTitle: nil
            )
        }
    }

    private func notifyAccountStateChange() {
        onAccountStateChange?(favoriteState, ratingState)
    }

}
