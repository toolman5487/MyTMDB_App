//
//  EpisodeDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import Foundation

// MARK: - EpisodeDetailViewState

nonisolated enum EpisodeDetailViewState: Equatable {
    case idle
    case loading
    case loaded(EpisodeDetailViewContent)
    case failed(ErrorMessage)
}

// MARK: - EpisodeDetailViewContent

nonisolated struct EpisodeDetailViewContent: Sendable, Equatable {
    let sections: [EpisodeDetailSectionItem]
    let navigationTitle: String
}

// MARK: - EpisodeDetailViewModel

@MainActor
final class EpisodeDetailViewModel {

    // MARK: - Properties

    private(set) var state: EpisodeDetailViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }
    var ratingState: AccountMediaRatingState { accountMediaController.ratingState }
    var ratingDefaultValue: Double { accountMediaController.ratingDefaultValue }

    private var onStateChange: (@MainActor (EpisodeDetailViewState) -> Void)?
    private var onRatingStateChange: (@MainActor (AccountMediaRatingState) -> Void)?
    private let input: EpisodeDetailInput
    private let loadEpisodeDetailUseCase: LoadEpisodeDetailUseCase
    private let accountMediaController: DetailAccountMediaStateController
    private let localization: AppInterfaceLocalization

    // MARK: - Initialization

    init(
        input: EpisodeDetailInput,
        loadEpisodeDetailUseCase: LoadEpisodeDetailUseCase,
        accountMediaController: DetailAccountMediaStateController,
        localization: AppInterfaceLocalization
    ) {
        self.input = input
        self.loadEpisodeDetailUseCase = loadEpisodeDetailUseCase
        self.accountMediaController = accountMediaController
        self.localization = localization
        self.accountMediaController.stateDidChange = { [weak self] in
            self?.notifyRatingStateChange()
        }
    }

    // MARK: - Output Binding

    func bind(
        onStateChange: @escaping @MainActor (EpisodeDetailViewState) -> Void,
        onRatingStateChange: @escaping @MainActor (AccountMediaRatingState) -> Void
    ) {
        self.onStateChange = onStateChange
        self.onRatingStateChange = onRatingStateChange
        onStateChange(state)
        notifyRatingStateChange()
    }

    // MARK: - Data Loading

    func loadInitialContent() async {
        state = .loading
        accountMediaController.prepareForLoading()

        do {
            let content = try await loadEpisodeDetailUseCase(input: input)
            guard !Task.isCancelled else { return }

            accountMediaController.updateDefaultRating(
                fromPublicRating: content.detail.voteCount > 0
                    ? content.detail.voteAverage
                    : nil
            )
            if content.supportsAccountRating {
                accountMediaController.applyLoadedRating(value: content.accountState.rating.value)
            } else {
                accountMediaController.markRatingUnavailable()
            }
            state = .loaded(EpisodeDetailPresentationBuilder.makeContent(
                content: content,
                localization: localization
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

    // MARK: - Rating

    func submitRating(value: Double) async -> ErrorMessage? {
        let errorMessage = await accountMediaController.submitRating(
            target: .episode(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            ),
            value: value,
            invalidMessage: ErrorMessage(
                title: localization.string("detail.error.rating.title", defaultValue: "Unable to Rate"),
                message: invalidInputMessage
            )
        )
        updateAccountStateSectionAfterRatingMutation(errorMessage: errorMessage)
        return errorMessage
    }

    func deleteRating() async -> ErrorMessage? {
        let errorMessage = await accountMediaController.deleteRating(
            target: .episode(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            ),
            invalidMessage: ErrorMessage(
                title: localization.string(
                    "detail.error.delete_rating.title",
                    defaultValue: "Unable to Delete Rating"
                ),
                message: invalidInputMessage
            )
        )
        updateAccountStateSectionAfterRatingMutation(errorMessage: errorMessage)
        return errorMessage
    }

    private func updateAccountStateSectionAfterRatingMutation(errorMessage: ErrorMessage?) {
        guard errorMessage == nil,
              case .loaded(let content) = state,
              case .ready(let value) = ratingState else {
            return
        }

        state = .loaded(EpisodeDetailPresentationBuilder.updatingAccountState(value: value, in: content))
    }

    private func notifyRatingStateChange() {
        onRatingStateChange?(ratingState)
    }

    private var invalidInputMessage: String {
        localization.string(
            "episode_detail.error.invalid_input.message",
            defaultValue: "Valid TV show, season, and episode information is required."
        )
    }

    private func errorMessage(for error: DomainError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return ErrorMessage(
                title: localization.string("detail.error.invalid_data.title", defaultValue: "Invalid Data"),
                message: invalidInputMessage
            )
        }
    }
}
