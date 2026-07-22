//
//  MovieDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation
import Observation

// MARK: - State

nonisolated enum MovieDetailViewState: Equatable {
    case idle
    case loading
    case loaded([MovieDetailSectionItem])
    case failed(ErrorMessage)
}

// MARK: - MovieDetailViewModel

@MainActor
@Observable
final class MovieDetailViewModel {

    // MARK: - Properties

    private(set) var state: MovieDetailViewState = .idle
    private(set) var favoriteState: AccountMediaFavoriteState = .unavailable
    private(set) var ratingState: AccountMediaRatingState = .unavailable
    private(set) var ratingDefaultValue: Double = AccountMediaRatingValue.fallback

    private let service: MovieDetailServicing
    private let accountMediaController: DetailAccountMediaStateController

    // MARK: - Initialization

    init(
        service: MovieDetailServicing = MovieDetailService(),
        sessionStore: SessionStoring = SessionStore(),
        accountService: AccountServiceProtocol = AccountService(),
        accountMediaService: MemberCenterServicing = MemberCenterService()
    ) {
        self.service = service
        self.accountMediaController = DetailAccountMediaStateController(
            sessionStore: sessionStore,
            accountService: accountService,
            accountMediaService: accountMediaService
        )
        accountMediaController.stateDidChange = { [weak self] in
            self?.syncAccountMediaState()
        }
        syncAccountMediaState()
    }

    // MARK: - Public Methods

    func loadMovieDetail(id: Int) async {
        guard id > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到電影",
                    message: "電影 ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading
        accountMediaController.prepareForLoading()

        do {
            async let content = service.fetchMovieDetailContent(id: id)
            await accountMediaController.loadAccountMediaState(
                sourceDescription: "movie \(id)"
            ) { [service] sessionID in
                try await service.fetchMovieAccountStates(id: id, sessionId: sessionID)
            }
            let loadedContent = try await content
            accountMediaController.updateDefaultRating(
                fromPublicRating: loadedContent.detail.voteCount > 0
                    ? loadedContent.detail.voteAverage
                    : nil
            )
            state = .loaded(MovieDetailSectionBuilder.makeSections(content: loadedContent))
        } catch {
            state = .failed(error.errorMessage)
            accountMediaController.markUnavailable()
        }
    }

    func toggleFavorite(movieID: Int) async -> ErrorMessage? {
        await accountMediaController.toggleFavorite(
            mediaID: movieID,
            mediaType: .movie,
            invalidMessage: ErrorMessage(title: "無法收藏", message: "電影 ID 不正確，請返回上一頁後再試。")
        )
    }

    func submitRating(movieID: Int, value: Double) async -> ErrorMessage? {
        await accountMediaController.submitRating(
            target: .movie(id: movieID),
            value: value,
            invalidMessage: ErrorMessage(title: "無法評分", message: "電影 ID 不正確，請返回上一頁後再試。")
        )
    }

    func deleteRating(movieID: Int) async -> ErrorMessage? {
        await accountMediaController.deleteRating(
            target: .movie(id: movieID),
            invalidMessage: ErrorMessage(title: "無法刪除評分", message: "電影 ID 不正確，請返回上一頁後再試。")
        )
    }

    // MARK: - Private Methods

    private func syncAccountMediaState() {
        favoriteState = accountMediaController.favoriteState
        ratingState = accountMediaController.ratingState
        ratingDefaultValue = accountMediaController.ratingDefaultValue
    }
}
