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

    // MARK: - Initialization

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadHome() async {
        state = .loading

        do {
            let sections = try await service.fetchHomeSections()
            let visibleSections = MainHomePresentationBuilder.makeSections(from: sections)
            state = visibleSections.isEmpty ? .empty : .loaded(visibleSections)
        } catch {
            state = .failed(error.errorMessage)
        }
    }
}
