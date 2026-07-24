//
//  ScrollTrackingBaseViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SnapKit
import UIKit

// MARK: - TabBarScrollVisibilityTracker

@MainActor
struct TabBarScrollVisibilityTracker {

    // MARK: - Constants

    private enum Layout {
        static let scrollThreshold: CGFloat = 12
        static let topBoundaryTolerance: CGFloat = 4
    }

    // MARK: - Properties

    private var previousVerticalContentOffsetY: CGFloat = 0
    private var accumulatedVerticalScrollDelta: CGFloat = 0

    // MARK: - Methods

    mutating func reset(for scrollView: UIScrollView) {
        previousVerticalContentOffsetY = scrollView.contentOffset.y
        accumulatedVerticalScrollDelta = 0
    }

    mutating func visibilityState(for scrollView: UIScrollView) -> MainTabBarVisibilityState? {
        guard scrollView.isDragging || scrollView.isDecelerating else { return nil }

        let offsetY = scrollView.contentOffset.y
        let topBoundary = -scrollView.adjustedContentInset.top

        guard offsetY > topBoundary + Layout.topBoundaryTolerance else {
            reset(for: scrollView)
            return .visible
        }

        let deltaY = offsetY - previousVerticalContentOffsetY
        previousVerticalContentOffsetY = offsetY

        guard deltaY != 0 else { return nil }

        if accumulatedVerticalScrollDelta.sign != deltaY.sign {
            accumulatedVerticalScrollDelta = deltaY
        } else {
            accumulatedVerticalScrollDelta += deltaY
        }

        guard abs(accumulatedVerticalScrollDelta) >= Layout.scrollThreshold else { return nil }

        let visibilityState: MainTabBarVisibilityState = accumulatedVerticalScrollDelta > 0
            ? .hiddenByScroll
            : .visible
        accumulatedVerticalScrollDelta = 0
        return visibilityState
    }
}

@MainActor
class ScrollTrackingBaseViewController: BaseViewController {

    // MARK: - Override Points

    var collectionViewItemHeight: CGFloat {
        80
    }

    var updatesFlowLayoutItemSizeAutomatically: Bool {
        true
    }

    // MARK: - Properties

    private var tabBarVisibilityTracker = TabBarScrollVisibilityTracker()

    // MARK: - UI Components

    let collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()

    // MARK: - Collection Layout

    func makeCollectionViewLayout() -> UICollectionViewLayout {
        collectionViewFlowLayout
    }

    // MARK: - BaseViewController

    override func setupHierarchy() {
        view.addSubview(collectionView)
    }

    override func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Layout

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetTabBarVisibilityTracking()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewItemSize()
    }

    // MARK: - Tab Bar Visibility

    func resetTabBarVisibilityTracking() {
        tabBarVisibilityTracker.reset(for: collectionView)
    }

    func showTabBarForScrollTracking(animated: Bool = true) {
        setTabBarVisibility(.visible, animated: animated)
    }

    func beginTabBarVisibilityTracking(for scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        tabBarVisibilityTracker.reset(for: scrollView)
    }

    func updateTabBarVisibilityTracking(for scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        guard let visibilityState = tabBarVisibilityTracker.visibilityState(for: scrollView) else { return }
        setTabBarVisibility(visibilityState, animated: true)
    }

    private func updateCollectionViewItemSize() {
        guard updatesFlowLayoutItemSizeAutomatically else { return }

        let availableWidth = collectionView.bounds.width
        guard availableWidth > 0 else { return }

        let itemSize = CGSize(width: availableWidth, height: collectionViewItemHeight)
        guard collectionViewFlowLayout.itemSize != itemSize else { return }

        collectionViewFlowLayout.itemSize = itemSize
        collectionViewFlowLayout.invalidateLayout()
    }

    private func setTabBarVisibility(
        _ visibilityState: MainTabBarVisibilityState,
        animated: Bool
    ) {
        guard let tabBarController = tabBarController as? MainTabBarController else { return }
        tabBarController.setTabBarVisibility(visibilityState, animated: animated)
    }
}
