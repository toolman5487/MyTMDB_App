//
//  CompanyDetailContentListPageProvider.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailContentListPageProvider

actor CompanyDetailContentListPageProvider: DetailContentListPageProviding {

    // MARK: - Properties

    private let repository: CompanyDetailProviding
    private let companyID: Int
    private let mediaKind: MediaKind
    private let localization: AppInterfaceLocalization
    private var nextPage: Int
    private var totalPages: Int

    // MARK: - Initialization

    init(
        repository: CompanyDetailProviding,
        companyID: Int,
        mediaKind: MediaKind,
        startingPage: Page<MediaSummary>,
        localization: AppInterfaceLocalization
    ) {
        self.repository = repository
        self.companyID = companyID
        self.mediaKind = mediaKind
        self.localization = localization
        self.nextPage = startingPage.number + 1
        self.totalPages = startingPage.totalPages
    }

    // MARK: - DetailContentListPageProviding

    func loadNextPage() async throws -> DetailContentListPage {
        guard nextPage <= totalPages else {
            return DetailContentListPage(items: [], canLoadNextPage: false)
        }

        let page: Page<MediaSummary>
        switch mediaKind {
        case .movie:
            page = try await repository.movies(companyID: companyID, page: nextPage)

        case .tv:
            page = try await repository.tvShows(companyID: companyID, page: nextPage)
        }

        totalPages = page.totalPages
        nextPage = page.number + 1

        return DetailContentListPage(
            items: page.items.map {
                CompanyDetailContentListPresentationBuilder.makeItem(
                    summary: $0,
                    mediaKind: mediaKind,
                    localization: localization
                )
            },
            canLoadNextPage: nextPage <= totalPages
        )
    }
}
