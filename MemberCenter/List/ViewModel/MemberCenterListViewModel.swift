//
//  MemberCenterListViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MemberCenterListViewModel

@MainActor
final class MemberCenterListViewModel {

    // MARK: - Properties

    let destination: MemberCenterDestination
    private(set) var state: MemberCenterListViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (MemberCenterListViewState) -> Void)?
    private let accountId: Int
    private let sessionId: String
    private let loadCollectionPage: LoadAccountCollectionPageUseCase

    // MARK: - Initialization

    init(
        destination: MemberCenterDestination,
        accountId: Int,
        sessionId: String,
        loadCollectionPage: LoadAccountCollectionPageUseCase
    ) {
        self.destination = destination
        self.accountId = accountId
        self.sessionId = sessionId
        self.loadCollectionPage = loadCollectionPage
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (MemberCenterListViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadInitialContent() async {
        state = .loading

        do {
            let content = try await fetchContent(page: 1)
            guard !Task.isCancelled else { return }

            state = content.items.isEmpty ? .empty(destination) : .loaded(content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func loadNextPageIfNeeded(currentItemID: String) async {
        guard case .loaded(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentItemID: currentItemID, items: content.items) else {
            return
        }

        state = .loaded(content.updatingLoadingNextPage(true))

        do {
            let nextContent = try await fetchContent(page: content.currentPage + 1)
            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.destination == content.destination,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .loaded(currentContent.appending(nextContent))
        } catch {
            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.destination == content.destination,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .loaded(currentContent.updatingLoadingNextPage(false))
        }
    }

    // MARK: - Private Methods

    private func fetchContent(page: Int) async throws -> MemberCenterListContent {
        let collection = try await loadCollectionPage(
            destination: destination,
            accountID: accountId,
            sessionID: sessionId,
            page: page
        )

        return MemberCenterPresentationBuilder.makeListContent(from: collection)
    }

    private func shouldLoadNextPage(
        currentItemID: String,
        items: [MemberCenterListItem]
    ) -> Bool {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        return currentIndex >= max(items.count - 4, 0)
    }
}
