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

    // MARK: - Properties

    var collectionViewItemHeight: CGFloat {
        80
    }

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
