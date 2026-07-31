//
//  TVDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - State

nonisolated enum TVDetailViewState: Equatable {
    case idle
    case loading
    case loaded([TVDetailSectionItem])
    case failed(ErrorMessage)
}

// MARK: - TVDetailViewModel

@MainActor
final class TVDetailViewModel {

    // MARK: - Properties

    private(set) var state: TVDetailViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }
    var favoriteState: AccountMediaFavoriteState { accountMediaController.favoriteState }
    var ratingState: AccountMediaRatingState { accountMediaController.ratingState }
    var ratingDefaultValue: Double { accountMediaController.ratingDefaultValue }

    private var onStateChange: (@MainActor (TVDetailViewState) -> Void)?
    private var onAccountStateChange: (@MainActor (AccountMediaFavoriteState, AccountMediaRatingState) -> Void)?
    private let service: TVDetailServicing
    private let accountMediaController: DetailAccountMediaStateController

    // MARK: - Initialization

    init(
        service: TVDetailServicing,
        sessionStore: SessionStoring,
        accountService: AccountServiceProtocol,
        accountMediaService: MemberCenterServicing
    ) {
        self.service = service
        self.accountMediaController = DetailAccountMediaStateController(
            sessionStore: sessionStore,
            accountService: accountService,
            accountMediaService: accountMediaService
        )
        self.accountMediaController.stateDidChange = { [weak self] in
            self?.notifyAccountStateChange()
        }
    }

    convenience init() {
        self.init(
            service: TVDetailService(),
            sessionStore: SessionStore(),
            accountService: AccountService(),
            accountMediaService: MemberCenterService()
        )
    }

    // MARK: - Output Binding

    func bind(
        onStateChange: @escaping @MainActor (TVDetailViewState) -> Void,
        onAccountStateChange: @escaping @MainActor (AccountMediaFavoriteState, AccountMediaRatingState) -> Void
    ) {
        self.onStateChange = onStateChange
        self.onAccountStateChange = onAccountStateChange
        onStateChange(state)
        notifyAccountStateChange()
    }

    // MARK: - Data Loading

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
            guard !Task.isCancelled else { return }

            accountMediaController.updateDefaultRating(
                fromPublicRating: loadedContent.detail.voteCount > 0
                    ? loadedContent.detail.voteAverage
                    : nil
            )
            state = .loaded(TVDetailSectionBuilder.makeSections(content: loadedContent))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
            accountMediaController.markUnavailable()
        }
    }

    // MARK: - Favorite

    func toggleFavorite(seriesID: Int) async -> ErrorMessage? {
        await accountMediaController.toggleFavorite(
            mediaID: seriesID,
            mediaType: .tv,
            invalidMessage: ErrorMessage(
                title: "無法收藏",
                message: "影集 ID 不正確，請返回上一頁後再試。"
            )
        )
    }

    // MARK: - Rating

    func submitRating(seriesID: Int, value: Double) async -> ErrorMessage? {
        await accountMediaController.submitRating(
            target: .tv(seriesID: seriesID),
            value: value,
            invalidMessage: ErrorMessage(
                title: "無法評分",
                message: "影集 ID 不正確，請返回上一頁後再試。"
            )
        )
    }

    func deleteRating(seriesID: Int) async -> ErrorMessage? {
        await accountMediaController.deleteRating(
            target: .tv(seriesID: seriesID),
            invalidMessage: ErrorMessage(
                title: "無法刪除評分",
                message: "影集 ID 不正確，請返回上一頁後再試。"
            )
        )
    }

    // MARK: - Private Helpers

    private func notifyAccountStateChange() {
        onAccountStateChange?(favoriteState, ratingState)
    }
}
