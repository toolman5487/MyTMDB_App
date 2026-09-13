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

    convenience init() {
        let sessionStore = SessionStore()
        let accountService = AccountService()
        let sessionRepository = AccountSessionRepository(
            sessionStore: sessionStore,
            accountService: accountService
        )
        let mediaRepository = AccountMediaStateRepository()

        self.init(
            loadMovieDetailUseCase: DefaultLoadMovieDetailUseCase(
                repository: MovieDetailRepository(),
                auxiliaryFailureHandler: { name, movieID, error in
                    AppLogger.network.warning(
                        "Failed to load \(name, privacy: .public) for movie \(movieID, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                }
            ),
            accountMediaController: DetailAccountMediaStateController(
                isUserAuthenticated: Self.isUserAuthenticated(sessionStore.load()),
                loadAccountMediaStateUseCase: DefaultLoadAccountMediaStateUseCase(
                    sessionRepository: sessionRepository,
                    mediaRepository: mediaRepository
                ),
                toggleFavoriteUseCase: DefaultToggleFavoriteUseCase(
                    sessionRepository: sessionRepository,
                    mediaRepository: mediaRepository
                ),
                submitRatingUseCase: DefaultSubmitRatingUseCase(
                    sessionRepository: sessionRepository,
                    mediaRepository: mediaRepository
                ),
                deleteRatingUseCase: DefaultDeleteRatingUseCase(
                    sessionRepository: sessionRepository,
                    mediaRepository: mediaRepository
                )
            )
        )
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

    func loadMovieDetail(id: Int) async {
        state = .loading
        accountMediaController.prepareForLoading()

        do {
            async let content = loadMovieDetailUseCase(movieID: id)
            await accountMediaController.loadAccountMediaState(
                kind: .movie,
                mediaID: id,
                sourceDescription: "movie \(id)"
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

    private static func isUserAuthenticated(_ session: AuthSession) -> Bool {
        if case .user = session { return true }
        return false
    }
}
