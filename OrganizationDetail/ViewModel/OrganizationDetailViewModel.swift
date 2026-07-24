//
//  OrganizationDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import Observation

nonisolated enum OrganizationDetailViewState: Equatable {
    case idle
    case loading
    case loaded([OrganizationDetailSectionItem])
    case failed(ErrorMessage)
}

@MainActor
@Observable
final class OrganizationDetailViewModel {

    private(set) var state: OrganizationDetailViewState = .idle

    private let service: OrganizationDetailServicing

    init(service: OrganizationDetailServicing = OrganizationDetailService()) {
        self.service = service
    }

    func load(kind: OrganizationKind, id: Int) async {
        guard id > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到資料",
                    message: "\(kind.displayName) ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading

        do {
            let content = try await service.fetchContent(kind: kind, id: id)
            state = .loaded(OrganizationDetailSectionBuilder.makeSections(content: content))
        } catch {
            state = .failed(error.errorMessage)
        }
    }
}
