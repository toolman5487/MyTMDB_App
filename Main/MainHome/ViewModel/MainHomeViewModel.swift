//
//  MainHomeViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation
import Observation

// MARK: - State

nonisolated enum MainHomeViewState: Equatable {
    case idle
    case loading
    case loaded([MainHomeSectionItem])
    case empty
    case failed(ErrorMessage)
}

// MARK: - MainHomeViewModel

@MainActor
@Observable
final class MainHomeViewModel {

    // MARK: - Properties

    private(set) var state: MainHomeViewState = .idle

    private let service: MainHomeServicing
    private var loadGeneration = 0

    // MARK: - Initialization

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadHome() async {
        loadGeneration += 1
        let currentGeneration = loadGeneration
        state = .loading

        do {
            let sections = try await service.fetchHomeSections()
            guard isCurrentLoad(generation: currentGeneration) else { return }

            let visibleSections = MainHomePresentationBuilder.makeSections(from: sections)
            state = visibleSections.isEmpty ? .empty : .loaded(visibleSections)
        } catch is CancellationError {
            return
        } catch {
            guard isCurrentLoad(generation: currentGeneration) else { return }
            state = .failed(error.errorMessage)
        }
    }

    // MARK: - Private Methods

    private func isCurrentLoad(generation: Int) -> Bool {
        !Task.isCancelled && generation == loadGeneration
    }
}
