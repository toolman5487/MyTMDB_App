//
//  GlassScrollTrackingBaseViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import SnapKit
import UIKit

@MainActor
class GlassScrollTrackingBaseViewController: GlassBaseViewController {
    
    // MARK: - Constants
    
    private enum TabBarVisibility {
        static let scrollThreshold: CGFloat = 12
        static let topBoundaryTolerance: CGFloat = 4
    }
    
    // MARK: - Properties
    
    var collectionViewItemHeight: CGFloat {
        80
    }
    
    private var previousVerticalContentOffsetY: CGFloat = 0
    private var accumulatedVerticalScrollDelta: CGFloat = 0
    
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
            collectionViewLayout: collectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    // MARK: - BaseViewController
    
    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(collectionView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Layout
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetTabBarVisibilityTracking(for: collectionView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewItemSize()
    }
    
    // MARK: - Tab Bar Visibility
    
    func beginTabBarVisibilityTracking(for scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        resetTabBarVisibilityTracking(for: scrollView)
    }
    
    func updateTabBarVisibilityTracking(for scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        guard scrollView.isDragging || scrollView.isDecelerating else { return }
        
        let offsetY = scrollView.contentOffset.y
        let topBoundary = -scrollView.adjustedContentInset.top
        
        guard offsetY > topBoundary + TabBarVisibility.topBoundaryTolerance else {
            resetTabBarVisibilityTracking(for: scrollView)
            setTabBarHiddenByScroll(false)
            return
        }
        
        let deltaY = offsetY - previousVerticalContentOffsetY
        previousVerticalContentOffsetY = offsetY
        
        guard deltaY != 0 else { return }
        
        if accumulatedVerticalScrollDelta.sign != deltaY.sign {
            accumulatedVerticalScrollDelta = deltaY
        } else {
            accumulatedVerticalScrollDelta += deltaY
        }
        
        guard abs(accumulatedVerticalScrollDelta) >= TabBarVisibility.scrollThreshold else { return }
        
        setTabBarHiddenByScroll(accumulatedVerticalScrollDelta > 0)
        accumulatedVerticalScrollDelta = 0
    }
    
    private func updateCollectionViewItemSize() {
        let availableWidth = collectionView.bounds.width
        guard availableWidth > 0 else { return }
        
        let itemSize = CGSize(width: availableWidth, height: collectionViewItemHeight)
        guard collectionViewFlowLayout.itemSize != itemSize else { return }
        
        collectionViewFlowLayout.itemSize = itemSize
        collectionViewFlowLayout.invalidateLayout()
    }
    
    private func resetTabBarVisibilityTracking(for scrollView: UIScrollView) {
        previousVerticalContentOffsetY = scrollView.contentOffset.y
        accumulatedVerticalScrollDelta = 0
    }
    
    private func setTabBarHiddenByScroll(_ isHidden: Bool, animated: Bool = true) {
        guard let tabBarController = tabBarController as? MainTabBarController else { return }
        tabBarController.setTabBarHiddenByScroll(isHidden, animated: animated)
    }
}
