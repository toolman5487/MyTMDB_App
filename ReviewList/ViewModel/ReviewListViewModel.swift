//
//  ReviewListViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

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
final class ReviewListViewModel {

    // MARK: - Properties

    private(set) var state: ReviewListViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }
    private(set) var selectedFilter: ReviewFilter = .all

    private var onStateChange: (@MainActor (ReviewListViewState) -> Void)?
    private let mediaKind: MediaKind
    private let loadReviewsUseCase: LoadReviewsUseCase
    private let filterReviewsUseCase: FilterReviewsUseCase
    private let localization: AppInterfaceLocalization

    private static let initialPagination = MediaGridPaginationState(
        currentPage: 0,
        totalPages: 1,
        totalResults: 0
    )

    private var reviews: [Review] = []
    private var pagination = ReviewListViewModel.initialPagination
    private var mediaID: Int?

    // MARK: - Initialization

    init(
        mediaKind: MediaKind,
        loadReviewsUseCase: LoadReviewsUseCase,
        filterReviewsUseCase: FilterReviewsUseCase,
        localization: AppInterfaceLocalization
    ) {
        self.mediaKind = mediaKind
        self.loadReviewsUseCase = loadReviewsUseCase
        self.filterReviewsUseCase = filterReviewsUseCase
        self.localization = localization
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (ReviewListViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadInitialContent(mediaID: Int) async {
        self.mediaID = mediaID
        state = .loading
        resetPagination()

        do {
            let page = try await loadReviewsUseCase(kind: mediaKind, mediaID: mediaID)
            apply(page: page, replacingCurrentReviews: true)
            renderCurrentPresentation()
        } catch let error as DomainError {
            state = .failed(errorMessage(for: error))
        } catch {
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    func beginLoadingNextPage() -> Bool {
        guard !pagination.isLoadingNextPage else { return false }
        guard pagination.currentPage > 0, pagination.canLoadNextPage else { return false }

        pagination = pagination.updatingLoadingNextPage(true)
        renderCurrentPresentation()
        return true
    }

    func loadNextPage() async {
        guard let mediaID else { return }
        guard pagination.isLoadingNextPage || beginLoadingNextPage() else { return }

        let requestedPage = pagination.currentPage
        let nextPage = pagination.nextPage

        do {
            let page = try await loadReviewsUseCase(
                kind: mediaKind,
                mediaID: mediaID,
                page: nextPage
            )

            guard !Task.isCancelled,
                  isCurrentRequest(mediaID: mediaID, page: requestedPage) else {
                return
            }

            apply(page: page, replacingCurrentReviews: false)
        } catch {
            guard !Task.isCancelled,
                  isCurrentRequest(mediaID: mediaID, page: requestedPage) else {
                return
            }

            AppLogger.network.warning(
                "Failed to load next \(self.mediaKind.rawValue) review page. mediaID: \(mediaID), page: \(nextPage), error: \(error.localizedDescription)"
            )
        }

        pagination = pagination.updatingLoadingNextPage(false)
        renderCurrentPresentation()
    }

    func selectFilter(_ filter: ReviewFilter) {
        guard selectedFilter != filter else { return }

        selectedFilter = filter
        renderCurrentPresentation()
    }

    // MARK: - Private Methods

    private func errorMessage(for error: DomainError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier(let kind):
            return ErrorMessage(
                title: localization.string(
                    "review_list.error.not_found.title",
                    defaultValue: "Reviews Not Found"
                ),
                message: kind.invalidIdentifierMessage(localization: localization),
                actionTitle: nil
            )
        }
    }

    private func renderCurrentPresentation() {
        guard pagination.currentPage > 0 else {
            state = .empty
            return
        }

        let reviewItems = filterReviewsUseCase(reviews, filter: selectedFilter)
            .map { ReviewItem(review: $0, localization: localization) }

        guard !reviewItems.isEmpty else {
            state = .empty
            return
        }

        state = .loaded(
            ReviewListPresentation(
                filters: ReviewFilter.allCases.map {
                    ReviewFilterItem(
                        filter: $0,
                        selectedFilter: selectedFilter,
                        localization: localization
                    )
                },
                reviews: reviewItems,
                pagination: pagination
            )
        )
    }

    private func isCurrentRequest(mediaID: Int, page: Int) -> Bool {
        self.mediaID == mediaID && pagination.isLoadingNextPage && pagination.currentPage == page
    }

    private func resetPagination() {
        reviews = []
        pagination = Self.initialPagination
    }

    private func apply(page: Page<Review>, replacingCurrentReviews: Bool) {
        pagination = MediaGridPaginationState(page: page)

        reviews = replacingCurrentReviews
            ? page.items
            : reviews.appending(uniqueReviewsFrom: page.items)
    }
}
