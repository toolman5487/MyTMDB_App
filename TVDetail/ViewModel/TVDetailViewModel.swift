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
    private let localization: AppInterfaceLocalization

    // MARK: - Initialization

    init(
        loadTVDetailUseCase: LoadTVDetailUseCase,
        accountMediaController: DetailAccountMediaStateController,
        localization: AppInterfaceLocalization
    ) {
        self.loadTVDetailUseCase = loadTVDetailUseCase
        self.accountMediaController = accountMediaController
        self.localization = localization
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
            state = .loaded(TVDetailSectionBuilder.makeSections(
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

    func toggleFavorite(seriesID: Int) async -> ErrorMessage? {
        await accountMediaController.toggleFavorite(
            mediaID: seriesID,
            mediaType: .tv,
            invalidMessage: ErrorMessage(
                title: localization.string("detail.error.favorite.title", defaultValue: "Unable to Favorite"),
                message: MediaKind.tv.invalidIdentifierMessage(localization: localization)
            )
        )
    }

    // MARK: - Rating

    func submitRating(seriesID: Int, value: Double) async -> ErrorMessage? {
        await accountMediaController.submitRating(
            target: .tv(seriesID: seriesID),
            value: value,
            invalidMessage: ErrorMessage(
                title: localization.string("detail.error.rating.title", defaultValue: "Unable to Rate"),
                message: MediaKind.tv.invalidIdentifierMessage(localization: localization)
            )
        )
    }

    func deleteRating(seriesID: Int) async -> ErrorMessage? {
        await accountMediaController.deleteRating(
            target: .tv(seriesID: seriesID),
            invalidMessage: ErrorMessage(
                title: localization.string("detail.error.delete_rating.title", defaultValue: "Unable to Delete Rating"),
                message: MediaKind.tv.invalidIdentifierMessage(localization: localization)
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
