//
//  TVDetailReviewViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import Foundation
import Observation

// MARK: - TVDetailReviewViewState

nonisolated enum TVDetailReviewViewState: Equatable {
    case idle
    case loading
    case loaded(TVDetailReviewPresentation)
    case empty
    case failed(ErrorMessage)
}

// MARK: - TVDetailReviewViewModel

@MainActor
@Observable
final class TVDetailReviewViewModel {

    // MARK: - Properties

    private(set) var state: TVDetailReviewViewState = .idle
    private(set) var selectedFilter: TVDetailReviewFilter = .all

    private let service: TVDetailReviewServicing
    private var reviews: [TVDetailReview] = []
    private var currentPage: Int = 0
    private var totalPages: Int = 1
    private var totalResults: Int = 0
    private var isLoadingNextPage = false

    // MARK: - Initialization

    init(service: TVDetailReviewServicing = TVDetailReviewService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadReviews(seriesID: Int) async {
        guard seriesID > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到評論",
                    message: "影集 ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading
        resetPagination()

        do {
            let page = try await service.fetchTVReviews(seriesID: seriesID)
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

    func loadNextPage(seriesID: Int) async {
        guard seriesID > 0 else {
            isLoadingNextPage = false
            renderCurrentPresentation()
            return
        }

        guard isLoadingNextPage || beginLoadingNextPage() else { return }

        let nextPage = currentPage + 1

        do {
            let page = try await service.fetchTVReviews(
                seriesID: seriesID,
                page: nextPage
            )
            apply(page: page, replacingCurrentReviews: false)
        } catch {
            AppLogger.network.warning(
                "Failed to load next TV review page. seriesID: \(seriesID), page: \(nextPage), error: \(error.localizedDescription)"
            )
        }

        isLoadingNextPage = false
        renderCurrentPresentation()
    }

    func selectFilter(_ filter: TVDetailReviewFilter) {
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
            .map(TVReviewDetailItem.init(review:))
            .filter { !$0.content.isEmpty }

        guard !reviewItems.isEmpty else {
            state = .empty
            return
        }

        state = .loaded(
            TVDetailReviewPresentation(
                filters: TVDetailReviewFilter.allCases.map {
                    TVDetailReviewFilterItem(
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
        page: TVDetailReviewsPage,
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
        _ reviews: [TVDetailReview],
        applying filter: TVDetailReviewFilter
    ) -> [TVDetailReview] {
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
        _ lhs: TVDetailReview,
        orderedBefore rhs: TVDetailReview,
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

    private func reviewDate(for review: TVDetailReview) -> Date? {
        BaseDisplayTextFormatter.iso8601Date(from: review.updatedAt)
            ?? BaseDisplayTextFormatter.iso8601Date(from: review.createdAt)
    }
}
