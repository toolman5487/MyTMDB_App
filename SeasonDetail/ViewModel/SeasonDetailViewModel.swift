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
    private let localization: AppInterfaceLocalization

    // MARK: - Initialization

    init(
        loadSeasonDetailUseCase: LoadSeasonDetailUseCase,
        localization: AppInterfaceLocalization
    ) {
        self.loadSeasonDetailUseCase = loadSeasonDetailUseCase
        self.localization = localization
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

            state = .loaded(SeasonDetailSectionBuilder.makeContent(
                content: content,
                interfaceLocalization: localization
            ))
        } catch let error as DomainError {
            guard !Task.isCancelled else { return }
            state = .failed(errorMessage(for: error))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    // MARK: - Private Helpers

    private func errorMessage(for error: DomainError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return ErrorMessage(
                title: localization.string("detail.error.invalid_data.title", defaultValue: "Invalid Data"),
                message: localization.string(
                    "season_detail.error.invalid_input.message",
                    defaultValue: "Valid TV show and season information is required."
                )
            )
        }
    }
}
