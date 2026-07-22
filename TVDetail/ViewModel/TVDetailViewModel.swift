//
//  TVDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import Observation

// MARK: - State

nonisolated enum TVDetailViewState: Equatable {
    case idle
    case loading
    case loaded([TVDetailSectionItem])
    case failed(ErrorMessage)
}

// MARK: - TVDetailViewModel

@MainActor
@Observable
final class TVDetailViewModel {

    // MARK: - Properties

    private(set) var state: TVDetailViewState = .idle
    private(set) var favoriteState: AccountMediaFavoriteState = .unavailable
    private(set) var ratingState: AccountMediaRatingState = .unavailable
    private(set) var ratingDefaultValue: Double = AccountMediaRatingValue.fallback

    private let service: TVDetailServicing
    private let accountMediaController: DetailAccountMediaStateController

    // MARK: - Initialization

    init(
        service: TVDetailServicing = TVDetailService(),
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

    func loadTVDetail(seriesID: Int) async {
        guard seriesID > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到影集",
                    message: "影集 ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading
        accountMediaController.prepareForLoading()

        do {
            async let content = service.fetchTVDetailContent(seriesID: seriesID)
            await accountMediaController.loadAccountMediaState(
                sourceDescription: "TV series \(seriesID)"
            ) { [service] sessionID in
                try await service.fetchTVAccountStates(seriesID: seriesID, sessionId: sessionID)
            }
            let loadedContent = try await content
            accountMediaController.updateDefaultRating(
                fromPublicRating: loadedContent.detail.voteCount > 0
                    ? loadedContent.detail.voteAverage
                    : nil
            )
            state = .loaded(TVDetailSectionBuilder.makeSections(content: loadedContent))
        } catch {
            state = .failed(error.errorMessage)
            accountMediaController.markUnavailable()
        }
    }

    func toggleFavorite(seriesID: Int) async -> ErrorMessage? {
        await accountMediaController.toggleFavorite(
            mediaID: seriesID,
            mediaType: .tv,
            invalidMessage: ErrorMessage(title: "無法收藏", message: "影集 ID 不正確，請返回上一頁後再試。")
        )
    }

    func submitRating(seriesID: Int, value: Double) async -> ErrorMessage? {
        await accountMediaController.submitRating(
            target: .tv(seriesID: seriesID),
            value: value,
            invalidMessage: ErrorMessage(title: "無法評分", message: "影集 ID 不正確，請返回上一頁後再試。")
        )
    }

    func deleteRating(seriesID: Int) async -> ErrorMessage? {
        await accountMediaController.deleteRating(
            target: .tv(seriesID: seriesID),
            invalidMessage: ErrorMessage(title: "無法刪除評分", message: "影集 ID 不正確，請返回上一頁後再試。")
        )
    }

    // MARK: - Private Methods

    private func syncAccountMediaState() {
        favoriteState = accountMediaController.favoriteState
        ratingState = accountMediaController.ratingState
        ratingDefaultValue = accountMediaController.ratingDefaultValue
    }
}
