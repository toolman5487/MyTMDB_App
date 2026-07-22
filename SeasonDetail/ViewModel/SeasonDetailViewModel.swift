//
//  SeasonDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation
import Observation

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
@Observable
final class SeasonDetailViewModel {

    // MARK: - Properties

    private(set) var state: SeasonDetailViewState = .idle

    private let service: SeasonDetailServicing

    // MARK: - Initialization

    init(service: SeasonDetailServicing? = nil) {
        self.service = service ?? SeasonDetailService(session: SessionStore().load())
    }

    // MARK: - Public Methods

    func loadSeasonDetail(
        seriesID: Int,
        seasonNumber: Int
    ) async {
        guard seriesID > 0, seasonNumber >= 0 else {
            state = .failed(
                ErrorMessage(
                    title: "資料錯誤",
                    message: "缺少有效的劇集或季數資訊。"
                )
            )
            return
        }

        state = .loading

        do {
            let content = try await service.fetchSeasonDetailContent(
                seriesID: seriesID,
                seasonNumber: seasonNumber
            )
            guard !Task.isCancelled else { return }

            state = .loaded(SeasonDetailSectionBuilder.makeContent(content: content))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }
}
