//
//  PersonDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import Foundation
import Observation

// MARK: - State

nonisolated enum PersonDetailViewState: Equatable {
    case idle
    case loading
    case loaded([PersonDetailSectionItem])
    case failed(ErrorMessage)
}

// MARK: - PersonDetailViewModel

@MainActor
@Observable
final class PersonDetailViewModel {

    // MARK: - Properties

    private(set) var state: PersonDetailViewState = .idle

    private let service: PersonDetailServicing

    // MARK: - Initialization

    init(service: PersonDetailServicing = PersonDetailService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadPersonDetail(id: Int) async {
        guard id > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到人物",
                    message: "人物 ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading

        do {
            let content = try await service.fetchPersonDetailContent(id: id)
            state = .loaded(PersonDetailSectionBuilder.makeSections(content: content))
        } catch {
            state = .failed(error.errorMessage)
        }
    }
}
