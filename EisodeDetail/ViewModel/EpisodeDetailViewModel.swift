//
//  EpisodeDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import Foundation

// MARK: - EpisodeDetailInput

nonisolated struct EpisodeDetailInput: Sendable, Equatable {
    let seriesID: Int
    let seasonNumber: Int
    let episodeNumber: Int

    var isValid: Bool {
        seriesID > 0 && seasonNumber >= 0 && episodeNumber > 0
    }
}

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
    private let service: EpisodeDetailServicing
    private let accountMediaController: DetailAccountMediaStateController

    // MARK: - Initialization

    init(
        input: EpisodeDetailInput,
        service: EpisodeDetailServicing,
        sessionStore: SessionStoring,
        accountService: AccountServiceProtocol,
        accountMediaService: MemberCenterServicing
    ) {
        self.input = input
        self.service = service
        self.accountMediaController = DetailAccountMediaStateController(
            sessionStore: sessionStore,
            accountService: accountService,
            accountMediaService: accountMediaService
        )
        self.accountMediaController.stateDidChange = { [weak self] in
            self?.notifyRatingStateChange()
        }
    }

    convenience init(input: EpisodeDetailInput) {
        let sessionStore = SessionStore()
        self.init(
            input: input,
            service: EpisodeDetailService(session: sessionStore.load()),
            sessionStore: sessionStore,
            accountService: AccountService(),
            accountMediaService: MemberCenterService()
        )
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

    func loadEpisodeDetail() async {
        guard input.isValid else {
            state = .failed(
                ErrorMessage(
                    title: "資料錯誤",
                    message: "缺少有效的影集、季數或集數資訊。"
                )
            )
            return
        }

        state = .loading
        accountMediaController.prepareForLoading()

        do {
            let content = try await service.fetchEpisodeDetailContent(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            )
            guard !Task.isCancelled else { return }

            accountMediaController.updateDefaultRating(
                fromPublicRating: content.detail.voteCount > 0
                    ? content.detail.voteAverage
                    : nil
            )
            if content.supportsAccountRating {
                accountMediaController.applyLoadedRating(value: content.accountStates.rated.value)
            } else {
                accountMediaController.markRatingUnavailable()
            }
            state = .loaded(EpisodeDetailPresentationBuilder.makeContent(content: content))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
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
                title: "無法評分",
                message: "缺少有效的影集、季數或集數資訊。"
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
                title: "無法刪除評分",
                message: "缺少有效的影集、季數或集數資訊。"
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
}
