//
//  DetailBaseViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import UIKit

@MainActor
class DetailBaseViewController: ScrollTrackingBaseViewController {

    // MARK: - Constants

    private enum NavigationTitle {
        static let revealOffset: CGFloat = 192
        static let topBoundaryTolerance: CGFloat = 4
        static let animationDuration: TimeInterval = 0.18
    }

    // MARK: - Properties

    private var detailNavigationTitle: String?
    private var detailNavigationTitleRevealOffset = NavigationTitle.revealOffset
    private var isDetailNavigationTitleVisible = false
    private var detailRightBarButtonItems: [UIBarButtonItem] = []
    private lazy var favoriteBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "heart"),
        style: .plain,
        target: self,
        action: #selector(handleFavoriteButtonTapped)
    )
    private var isFavoriteButtonVisible = false

    // MARK: - Initialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil
    }

    // MARK: - Navigation Items

    func setDetailRightBarButtonItems(_ items: [UIBarButtonItem]) {
        detailRightBarButtonItems = items
        updateRightBarButtonItems()
    }

    func setFavoriteButton(isFavorite: Bool, isEnabled: Bool) {
        isFavoriteButtonVisible = true
        favoriteBarButtonItem.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        favoriteBarButtonItem.isEnabled = isEnabled
        favoriteBarButtonItem.accessibilityLabel = isFavorite ? "取消收藏" : "加入收藏"
        updateRightBarButtonItems()
    }

    func hideFavoriteButton() {
        isFavoriteButtonVisible = false
        updateRightBarButtonItems()
    }

    func handleDetailFavoriteButtonTapped() {}

    // MARK: - Navigation Title

    func setDetailNavigationTitle(_ title: String?) {
        setDetailNavigationTitle(title, revealOffset: NavigationTitle.revealOffset)
    }

    func setDetailNavigationTitle(_ title: String?, revealOffset: CGFloat) {
        let normalizedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        detailNavigationTitle = normalizedTitle?.isEmpty == false ? normalizedTitle : nil
        detailNavigationTitleRevealOffset = revealOffset
        setDetailNavigationTitleVisible(false, animated: false)
    }

    func updateDetailNavigationTitleVisibility(for scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }

        guard detailNavigationTitle != nil else {
            setDetailNavigationTitleVisible(false, animated: false)
            return
        }

        let topBoundary = -scrollView.adjustedContentInset.top
        let offsetY = scrollView.contentOffset.y

        if offsetY <= topBoundary + NavigationTitle.topBoundaryTolerance {
            setDetailNavigationTitleVisible(false, animated: true)
            return
        }

        if offsetY >= topBoundary + detailNavigationTitleRevealOffset {
            setDetailNavigationTitleVisible(true, animated: true)
        }
    }

    private func setDetailNavigationTitleVisible(_ isVisible: Bool, animated: Bool) {
        let title = isVisible ? detailNavigationTitle : nil

        guard isDetailNavigationTitleVisible != isVisible || navigationItem.title != title else {
            return
        }

        isDetailNavigationTitleVisible = isVisible

        let updates = {
            self.navigationItem.title = title
        }

        guard animated, let navigationBar = navigationController?.navigationBar else {
            updates()
            return
        }

        UIView.transition(
            with: navigationBar,
            duration: NavigationTitle.animationDuration,
            options: [.transitionCrossDissolve, .allowUserInteraction],
            animations: updates
        )
    }

    private func updateRightBarButtonItems() {
        var items: [UIBarButtonItem] = []

        if isFavoriteButtonVisible {
            items.append(favoriteBarButtonItem)
        }

        items.append(contentsOf: detailRightBarButtonItems)
        navigationItem.rightBarButtonItems = items
    }

    @objc private func handleFavoriteButtonTapped() {
        handleDetailFavoriteButtonTapped()
    }
}
