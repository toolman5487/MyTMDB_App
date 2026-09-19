//
//  DetailBaseViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import UIKit

// MARK: - DetailContentPresentationState

@MainActor
enum DetailContentPresentationState {
    case idle
    case loading
    case loaded(navigationTitle: String?)
    case failed(message: ErrorMessage, retry: @MainActor () -> Void)
}

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
    private var isDetailNavigationTitleVisible = false

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

    // MARK: - Content Presentation

    func renderDetailContent(_ state: DetailContentPresentationState) {
        switch state {
        case .idle:
            setDetailNavigationTitle(nil)
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .loading:
            setDetailNavigationTitle(nil)
            setLoadingVisible(true)
            collectionView.backgroundView = nil

        case .loaded(let navigationTitle):
            setDetailNavigationTitle(navigationTitle)
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .failed(let message, let retry):
            setDetailNavigationTitle(nil)
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(
                message: message,
                localization: interfaceLocalization,
                action: retry
            )
        }
    }

    // MARK: - Section Header

    func registerDetailSectionHeader() {
        collectionView.register(
            DetailSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DetailSectionHeaderView.reuseIdentifier
        )
    }

    func dequeueDetailSectionHeader(
        at indexPath: IndexPath,
        title: String?,
        onTap: (() -> Void)? = nil
    ) -> UICollectionReusableView {
        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DetailSectionHeaderView.reuseIdentifier,
            for: indexPath
        )
        (reusableView as? DetailSectionHeaderView)?.configure(
            title: title,
            localization: interfaceLocalization,
            onTitleTap: onTap
        )
        return reusableView
    }

    // MARK: - Navigation Title

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

        if offsetY >= topBoundary + NavigationTitle.revealOffset {
            setDetailNavigationTitleVisible(true, animated: true)
        }
    }

    private func setDetailNavigationTitle(_ title: String?) {
        let normalizedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        detailNavigationTitle = normalizedTitle?.isEmpty == false ? normalizedTitle : nil
        setDetailNavigationTitleVisible(false, animated: false)
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
}
