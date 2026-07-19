//
//  EpisodeDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import Foundation
import Observation

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
@Observable
final class EpisodeDetailViewModel {

    // MARK: - Properties

    private(set) var state: EpisodeDetailViewState = .idle
    private(set) var ratingState: AccountMediaRatingState = .unavailable
    private(set) var ratingDefaultValue: Double = AccountMediaRatingValue.fallback

    private let service: EpisodeDetailServicing
    private let accountMediaController: DetailAccountMediaStateController

    // MARK: - Initialization

    init(
        service: EpisodeDetailServicing? = nil,
        sessionStore: SessionStoring = SessionStore(),
        accountService: AccountServiceProtocol = AccountService(),
        accountMediaService: MemberCenterServicing = MemberCenterService()
    ) {
        self.service = service ?? EpisodeDetailService(session: sessionStore.load())
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

    func loadEpisodeDetail(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async {
        guard seriesID > 0, seasonNumber >= 0, episodeNumber > 0 else {
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
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
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

    func submitRating(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int,
        value: Double
    ) async -> ErrorMessage? {
        let errorMessage = await accountMediaController.submitRating(
            target: .episode(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
            value: value,
            invalidMessage: ErrorMessage(title: "無法評分", message: "缺少有效的影集、季數或集數資訊。")
        )
        updateAccountStateSectionAfterRatingMutation(errorMessage: errorMessage)
        return errorMessage
    }

    func deleteRating(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async -> ErrorMessage? {
        let errorMessage = await accountMediaController.deleteRating(
            target: .episode(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
            invalidMessage: ErrorMessage(title: "無法刪除評分", message: "缺少有效的影集、季數或集數資訊。")
        )
        updateAccountStateSectionAfterRatingMutation(errorMessage: errorMessage)
        return errorMessage
    }

    private func syncAccountMediaState() {
        ratingState = accountMediaController.ratingState
        ratingDefaultValue = accountMediaController.ratingDefaultValue
    }

    private func updateAccountStateSectionAfterRatingMutation(errorMessage: ErrorMessage?) {
        guard errorMessage == nil,
              case .loaded(let content) = state,
              case .ready(let value) = ratingState else {
            return
        }

        state = .loaded(EpisodeDetailPresentationBuilder.updatingAccountState(value: value, in: content))
    }
}
