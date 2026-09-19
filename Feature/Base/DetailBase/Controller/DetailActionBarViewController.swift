//
//  DetailActionBarViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/8/1.
//

import SnapKit
import UIKit

// MARK: - DetailActionBarViewController

@MainActor
class DetailActionBarViewController: DetailBaseViewController {

    // MARK: - Properties

    private var favoriteUpdateTask: Task<Void, Never>?
    private var ratingUpdateTask: Task<Void, Never>?

    // MARK: - UI Components

    private lazy var actionBarView = DetailBottomActionBarView(localization: interfaceLocalization)

    // MARK: - Lifecycle

    deinit {
        favoriteUpdateTask?.cancel()
        ratingUpdateTask?.cancel()
    }

    // MARK: - BaseViewController

    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(actionBarView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        actionBarView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewBottomInset()
    }

    // MARK: - Configuration

    func configureDetailActions(
        showsFavorite: Bool,
        showsRating: Bool,
        showsReview: Bool,
        favoriteAction: (@MainActor () -> Void)? = nil,
        ratingAction: (@MainActor () -> Void)? = nil,
        reviewAction: (@MainActor () -> Void)? = nil
    ) {
        actionBarView.setVisibleActions(
            favorite: showsFavorite,
            rating: showsRating,
            review: showsReview
        )
        actionBarView.setActionHandlers(
            favorite: favoriteAction,
            rating: ratingAction,
            review: reviewAction
        )
        actionBarView.configureFavorite(with: .unavailable)
        actionBarView.configureRating(with: .unavailable)
    }

    // MARK: - State Rendering

    func updateFavoriteAction(with state: AccountMediaFavoriteState) {
        actionBarView.configureFavorite(with: state)
    }

    func updateRatingAction(with state: AccountMediaRatingState) {
        actionBarView.configureRating(with: state)
    }

    // MARK: - Async Updates

    func performFavoriteUpdate(
        from state: AccountMediaFavoriteState,
        operation: @escaping @MainActor () async -> ErrorMessage?
    ) {
        actionBarView.configurePendingFavorite(from: state)
        favoriteUpdateTask?.cancel()
        favoriteUpdateTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let message = await operation()
            guard !Task.isCancelled else { return }

            presentDetailActionError(message)
        }
    }

    func performRatingUpdate(
        pendingValue: Double?,
        operation: @escaping @MainActor () async -> ErrorMessage?
    ) {
        actionBarView.configurePendingRating(value: pendingValue)
        ratingUpdateTask?.cancel()
        ratingUpdateTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let message = await operation()
            guard !Task.isCancelled else { return }

            presentDetailActionError(message)
        }
    }

    // MARK: - Private Helpers

    private func updateCollectionViewBottomInset() {
        let bottomInset = actionBarView.bounds.height
        guard collectionView.contentInset.bottom != bottomInset else { return }

        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func presentDetailActionError(_ message: ErrorMessage?) {
        guard let message else { return }

        presentAlert(
            title: message.title,
            message: message.message,
            actionTitle: message.actionTitle
        )
    }
}
