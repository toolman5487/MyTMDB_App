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
    private let service: ReviewListServicing
    private var reviews: [Review] = []
    private var currentPage: Int = 0
    private var totalPages: Int = 1
    private var totalResults: Int = 0
    private var isLoadingNextPage = false

    // MARK: - Initialization

    init(
        mediaKind: MediaKind,
        service: ReviewListServicing = ReviewListService()
    ) {
        self.mediaKind = mediaKind
        self.service = service
    }

    // MARK: - Public Methods

    func loadReviews(mediaID: Int) async {
        guard mediaID > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到評論",
                    message: "\(mediaKind.displayName) ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading
        resetPagination()

        do {
            let page = try await service.fetchReviews(kind: mediaKind, mediaID: mediaID)
            apply(page: page, replacingCurrentReviews: true)
            renderCurrentPresentation()
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
        guard mediaID > 0 else {
            isLoadingNextPage = false
            renderCurrentPresentation()
            return
        }

        guard isLoadingNextPage || beginLoadingNextPage() else { return }

        let nextPage = currentPage + 1

        do {
            let page = try await service.fetchReviews(
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

    private func renderCurrentPresentation() {
        guard currentPage > 0 else {
            state = .empty
            return
        }

        let reviewItems = reviews(
            reviews,
            applying: selectedFilter
        )
            .map(ReviewItem.init(review:))
            .filter { !$0.content.isEmpty }

        guard !reviewItems.isEmpty else {
            state = .empty
            return
        }

        state = .loaded(
            ReviewListPresentation(
                filters: ReviewFilter.allCases.map {
                    ReviewFilterItem(
                        filter: $0,
                        selectedFilter: selectedFilter
                    )
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

    private func apply(
        page: ReviewsPage,
        replacingCurrentReviews: Bool
    ) {
        currentPage = page.page
        totalPages = page.totalPages
        totalResults = page.totalResults

        if replacingCurrentReviews {
            reviews = page.results
            return
        }

        var existingIDs = Set(reviews.map(\.id))
        let newReviews = page.results.filter { review in
            guard !existingIDs.contains(review.id) else { return false }
            existingIDs.insert(review.id)
            return true
        }

        reviews.append(contentsOf: newReviews)
    }

    private func reviews(
        _ reviews: [Review],
        applying filter: ReviewFilter
    ) -> [Review] {
        switch filter {
        case .all:
            return reviews

        case .rated:
            return reviews.filter { ($0.authorDetails.rating ?? 0) > 0 }

        case .unrated:
            return reviews.filter {
                $0.authorDetails.rating == nil || $0.authorDetails.rating == 0
            }

        case .latest:
            return reviews.sorted {
                isReview($0, orderedBefore: $1, ascending: false)
            }

        case .oldest:
            return reviews.sorted {
                isReview($0, orderedBefore: $1, ascending: true)
            }
        }
    }

    private func isReview(
        _ lhs: Review,
        orderedBefore rhs: Review,
        ascending: Bool
    ) -> Bool {
        let lhsDate = reviewDate(for: lhs)
        let rhsDate = reviewDate(for: rhs)

        switch (lhsDate, rhsDate) {
        case (.some(let lhsDate), .some(let rhsDate)):
            return ascending ? lhsDate < rhsDate : lhsDate > rhsDate

        case (.some, .none):
            return true

        case (.none, .some):
            return false

        case (.none, .none):
            return lhs.id < rhs.id
        }
    }

    private func reviewDate(for review: Review) -> Date? {
        BaseDisplayTextFormatter.iso8601Date(from: review.updatedAt)
            ?? BaseDisplayTextFormatter.iso8601Date(from: review.createdAt)
    }
}
