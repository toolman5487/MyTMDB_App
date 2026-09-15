//
//  SeasonDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - SeasonDetailViewState

nonisolated enum SeasonDetailViewState: Equatable {
    case idle
    case loading
    case loaded(SeasonDetailViewContent)
    case failed(ErrorMessage)
}

// MARK: - SeasonDetailViewContent

nonisolated struct SeasonDetailViewContent: Sendable, Equatable {
    let sections: [SeasonDetailSectionItem]
    let navigationTitle: String
}

// MARK: - SeasonDetailViewModel

@MainActor
final class SeasonDetailViewModel {

    // MARK: - Properties

    private(set) var state: SeasonDetailViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (SeasonDetailViewState) -> Void)?
    private let loadSeasonDetailUseCase: LoadSeasonDetailUseCase

    // MARK: - Initialization

    init(loadSeasonDetailUseCase: LoadSeasonDetailUseCase) {
        self.loadSeasonDetailUseCase = loadSeasonDetailUseCase
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (SeasonDetailViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadInitialContent(
        seriesID: Int,
        seasonNumber: Int
    ) async {
        state = .loading

        do {
            let content = try await loadSeasonDetailUseCase(
                seriesID: seriesID,
                seasonNumber: seasonNumber
            )
            guard !Task.isCancelled else { return }

            state = .loaded(SeasonDetailSectionBuilder.makeContent(content: content))
        } catch let error as DomainError {
            guard !Task.isCancelled else { return }
            state = .failed(Self.errorMessage(for: error))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    // MARK: - Private Helpers

    private static func errorMessage(for error: DomainError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return ErrorMessage(
                title: "資料錯誤",
                message: "缺少有效的劇集或季數資訊。"
            )
        }
    }
}
