//
//  ReviewListViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import Observation

// MARK: - ReviewListViewState

nonisolated enum ReviewListViewState: Equatable {
    case idle
    case loading
    case loaded(ReviewListPresentation)
    case empty
    case failed(ErrorMessage)
}

// MARK: - ReviewListViewModel

@MainActor
@Observable
final class ReviewListViewModel {

    // MARK: - Properties

    private(set) var state: ReviewListViewState = .idle
    private(set) var selectedFilter: ReviewFilter = .all

    private let mediaKind: MediaKind
    private let loadReviewsUseCase: LoadReviewsUseCase
    private let filterReviewsUseCase: FilterReviewsUseCase

    private var reviews: [Review] = []
    private var currentPage: Int = 0
    private var totalPages: Int = 1
    private var totalResults: Int = 0
    private var isLoadingNextPage = false

    // MARK: - Initialization

    init(
        mediaKind: MediaKind,
        loadReviewsUseCase: LoadReviewsUseCase,
        filterReviewsUseCase: FilterReviewsUseCase
    ) {
        self.mediaKind = mediaKind
        self.loadReviewsUseCase = loadReviewsUseCase
        self.filterReviewsUseCase = filterReviewsUseCase
    }

    // MARK: - Public Methods

    func loadReviews(mediaID: Int) async {
        state = .loading
        resetPagination()

        do {
            let page = try await loadReviewsUseCase(kind: mediaKind, mediaID: mediaID)
            apply(page: page, replacingCurrentReviews: true)
            renderCurrentPresentation()
        } catch let error as DomainError {
            state = .failed(Self.errorMessage(for: error))
        } catch {
            state = .failed(error.errorMessage)
        }
    }

    func beginLoadingNextPage() -> Bool {
        guard !isLoadingNextPage else { return false }
        guard currentPage > 0, currentPage < totalPages else { return false }

        isLoadingNextPage = true
        renderCurrentPresentation()
        return true
    }

    func loadNextPage(mediaID: Int) async {
        guard isLoadingNextPage || beginLoadingNextPage() else { return }

        let nextPage = currentPage + 1

        do {
            let page = try await loadReviewsUseCase(
                kind: mediaKind,
                mediaID: mediaID,
                page: nextPage
            )
            apply(page: page, replacingCurrentReviews: false)
        } catch {
            AppLogger.network.warning(
                "Failed to load next \(self.mediaKind.rawValue) review page. mediaID: \(mediaID), page: \(nextPage), error: \(error.localizedDescription)"
            )
        }

        isLoadingNextPage = false
        renderCurrentPresentation()
    }

    func selectFilter(_ filter: ReviewFilter) {
        guard selectedFilter != filter else { return }

        selectedFilter = filter
        renderCurrentPresentation()
    }

    // MARK: - Private Methods

    private static func errorMessage(for error: DomainError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier(let kind):
            return ErrorMessage(
                title: "找不到評論",
                message: "\(kind.displayName) ID 不正確，請返回上一頁後再試。",
                actionTitle: nil
            )
        }
    }

    private func renderCurrentPresentation() {
        guard currentPage > 0 else {
            state = .empty
            return
        }

        let reviewItems = filterReviewsUseCase(reviews, filter: selectedFilter)
            .map(ReviewItem.init(review:))

        guard !reviewItems.isEmpty else {
            state = .empty
            return
        }

        state = .loaded(
            ReviewListPresentation(
                filters: ReviewFilter.allCases.map {
                    ReviewFilterItem(filter: $0, selectedFilter: selectedFilter)
                },
                reviews: reviewItems,
                page: currentPage,
                totalPages: totalPages,
                totalResults: totalResults,
                isLoadingNextPage: isLoadingNextPage
            )
        )
    }

    private func resetPagination() {
        reviews = []
        currentPage = 0
        totalPages = 1
        totalResults = 0
        isLoadingNextPage = false
    }

    private func apply(page: Page<Review>, replacingCurrentReviews: Bool) {
        currentPage = page.number
        totalPages = page.totalPages
        totalResults = page.totalResults

        reviews = replacingCurrentReviews
            ? page.items
            : reviews.appending(uniqueReviewsFrom: page.items)
    }
}
