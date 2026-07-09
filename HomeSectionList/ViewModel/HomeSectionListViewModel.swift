//
//  HomeSectionListViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation
import Observation

// MARK: - HomeSectionListViewModel

@MainActor
@Observable
final class HomeSectionListViewModel {

    // MARK: - Properties

    private(set) var state: HomeSectionListViewState = .idle

    private let category: MainHomeContentCategory
    private let service: MainHomeServicing

    // MARK: - Initialization

    init(
        category: MainHomeContentCategory,
        service: MainHomeServicing = MainHomeService()
    ) {
        self.category = category
        self.service = service
    }

    // MARK: - Public Methods

    func loadInitial() async {
        state = .loading

        do {
            let page = try await service.fetchContent(for: category, page: 1)
            guard !Task.isCancelled else { return }

            let items = page.contents.map { content in
                MainHomeContentItem(
                    content: content,
                    mediaType: category.mediaType
                )
            }

            guard !items.isEmpty else {
                state = .empty
                return
            }

            state = .loaded(
                HomeSectionListContent(
                    category: category,
                    items: items,
                    currentPage: page.page,
                    totalPages: page.totalPages
                )
            )
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func loadNextPageIfNeeded(currentItemID: Int) async {
        guard case .loaded(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentItemID: currentItemID, items: content.items) else {
            return
        }

        state = .loaded(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await service.fetchContent(
                for: category,
                page: content.currentPage + 1
            )

            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.category == content.category,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .loaded(currentContent.appending(page: nextPage))
        } catch {
            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.category == content.category,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .loaded(currentContent.updatingLoadingNextPage(false))
        }
    }

    // MARK: - Private Methods

    private func shouldLoadNextPage(
        currentItemID: Int,
        items: [MainHomeContentItem]
    ) -> Bool {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        return MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: items.count
        )
    }
}
