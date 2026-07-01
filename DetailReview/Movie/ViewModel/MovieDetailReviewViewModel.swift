//
//  MovieDetailReviewViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import Observation

// MARK: - MovieDetailReviewViewState

nonisolated enum MovieDetailReviewViewState: Equatable {
    case idle
    case loading
    case loaded(MovieDetailReviewPresentation)
    case empty
    case failed(ErrorMessage)
}

// MARK: - MovieDetailReviewViewModel

@MainActor
@Observable
final class MovieDetailReviewViewModel {

    // MARK: - Properties

    private(set) var state: MovieDetailReviewViewState = .idle
    private(set) var selectedFilter: MovieDetailReviewFilter = .all

    private let service: MovieDetailReviewServicing
    private var reviews: [MovieDetailReview] = []
    private var currentPage: Int = 0
    private var totalPages: Int = 1
    private var totalResults: Int = 0
    private var isLoadingNextPage = false

    // MARK: - Initialization

    init(service: MovieDetailReviewServicing = MovieDetailReviewService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadReviews(movieID: Int) async {
        guard movieID > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到評論",
                    message: "電影 ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading
        resetPagination()

        do {
            let page = try await service.fetchMovieReviews(movieID: movieID)
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

    func loadNextPage(movieID: Int) async {
        guard movieID > 0 else {
            isLoadingNextPage = false
            renderCurrentPresentation()
            return
        }

        guard isLoadingNextPage || beginLoadingNextPage() else { return }

        do {
            let page = try await service.fetchMovieReviews(
                movieID: movieID,
                page: currentPage + 1
            )
            apply(page: page, replacingCurrentReviews: false)
        } catch {
            // Keep the existing reviews visible and stop the pagination indicator.
        }

        isLoadingNextPage = false
        renderCurrentPresentation()
    }

    func selectFilter(_ filter: MovieDetailReviewFilter) {
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
            .map(MovieDetailReviewItem.init(review:))
            .filter { !$0.content.isEmpty }

        guard !reviewItems.isEmpty else {
            state = .empty
            return
        }

        state = .loaded(
            MovieDetailReviewPresentation(
                filters: MovieDetailReviewFilter.allCases.map {
                    MovieDetailReviewFilterItem(
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
        page: MovieDetailReviewsPage,
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
        _ reviews: [MovieDetailReview],
        applying filter: MovieDetailReviewFilter
    ) -> [MovieDetailReview] {
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
        _ lhs: MovieDetailReview,
        orderedBefore rhs: MovieDetailReview,
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

    private func reviewDate(for review: MovieDetailReview) -> Date? {
        date(from: review.updatedAt) ?? date(from: review.createdAt)
    }

    private func date(from rawValue: String) -> Date? {
        guard !rawValue.isEmpty else { return nil }

        let fractionalSecondsFormatter = ISO8601DateFormatter()
        fractionalSecondsFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return fractionalSecondsFormatter.date(from: rawValue)
            ?? ISO8601DateFormatter().date(from: rawValue)
    }
}
