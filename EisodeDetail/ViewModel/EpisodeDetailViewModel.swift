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

    // MARK: - Initialization

    init(
        input: EpisodeDetailInput,
        loadEpisodeDetailUseCase: LoadEpisodeDetailUseCase,
        sessionStore: SessionStoring,
        accountService: AccountServiceProtocol,
        accountMediaService: MemberCenterServicing
    ) {
        self.input = input
        self.loadEpisodeDetailUseCase = loadEpisodeDetailUseCase
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
        let accountCredential = Self.makeAccountCredential(from: sessionStore.load())

        self.init(
            input: input,
            loadEpisodeDetailUseCase: DefaultLoadEpisodeDetailUseCase(
                repository: EpisodeDetailRepository(),
                accountCredential: accountCredential,
                auxiliaryFailureHandler: { name, input, error in
                    AppLogger.network.warning(
                        "Failed to load \(name, privacy: .public) for TV series \(input.seriesID, privacy: .public) season \(input.seasonNumber, privacy: .public) episode \(input.episodeNumber, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                }
            ),
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
            state = .loaded(EpisodeDetailPresentationBuilder.makeContent(content: content))
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

    private static func makeAccountCredential(
        from session: AuthSession?
    ) -> EpisodeAccountCredential? {
        switch session {
        case .guest(let sessionID):
            return .guest(sessionID: sessionID)

        case .user(let sessionID):
            return .user(sessionID: sessionID)

        case .loggedOut, nil:
            return nil
        }
    }

    private static func errorMessage(for error: DomainError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return ErrorMessage(
                title: "資料錯誤",
                message: "缺少有效的影集、季數或集數資訊。"
            )
        }
    }
}
