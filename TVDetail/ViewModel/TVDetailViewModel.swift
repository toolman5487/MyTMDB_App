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
    private let loadTVDetailUseCase: LoadTVDetailUseCase
    private let accountMediaController: DetailAccountMediaStateController

    // MARK: - Initialization

    init(
        loadTVDetailUseCase: LoadTVDetailUseCase,
        accountMediaController: DetailAccountMediaStateController
    ) {
        self.loadTVDetailUseCase = loadTVDetailUseCase
        self.accountMediaController = accountMediaController
        self.accountMediaController.stateDidChange = { [weak self] in
            self?.notifyAccountStateChange()
        }
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

    func loadInitialContent(seriesID: Int) async {
        state = .loading
        accountMediaController.prepareForLoading()

        do {
            async let content = loadTVDetailUseCase(seriesID: seriesID)
            await accountMediaController.loadAccountMediaState(
                kind: .tv,
                mediaID: seriesID,
                sourceDescription: "TV series \(seriesID)"
            )
            let loadedContent = try await content
            guard !Task.isCancelled else { return }

            accountMediaController.updateDefaultRating(
                fromPublicRating: loadedContent.series.voteCount > 0
                    ? loadedContent.series.voteAverage
                    : nil
            )
            state = .loaded(TVDetailSectionBuilder.makeSections(content: loadedContent))
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
