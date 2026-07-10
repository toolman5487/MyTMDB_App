//
//  MainMemberCenterViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/9.
//

import Observation
import UIKit

@MainActor
final class MainMemberCenterViewController: MainBaseViewController {

    // MARK: - Layout

    private enum Layout {
        static let profileHeight: CGFloat = 128
        static let menuItemHeight: CGFloat = 60
        static let sectionSpacing: CGFloat = 16
        static let horizontalInset: CGFloat = 16
        static let topInset: CGFloat = 16
        static let bottomInset: CGFloat = 24
    }

    private enum Section: Int, CaseIterable {
        case profile
        case menu
    }

    // MARK: - Properties

    private let viewModel: MainMemberCenterViewModel
    private var content: MainMemberCenterContent?
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(session: AuthSession) {
        self.viewModel = MainMemberCenterViewModel(session: session)
        super.init(nibName: nil, bundle: nil)
    }

    init(viewModel: MainMemberCenterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MainMemberCenterViewModel(session: .loggedOut)
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.largeTitleDisplayMode = .never
        configureCollectionView()
    }

    override func bindViewModel() {
        render(state: viewModel.state)
        observeViewModelState()
        loadContent()
    }

    // MARK: - Setup

    private func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.minimumLineSpacing = Layout.sectionSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = 0
        collectionView.register(
            MainMemberCenterProfileCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberCenterProfileCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainMemberCenterMenuItemCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberCenterMenuItemCollectionViewCell.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadContent() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadContent()
        }
    }

    private func observeViewModelState() {
        withObservationTracking {
            _ = viewModel.state
        } onChange: { [weak self] in
            Task(priority: .userInitiated) { @MainActor [weak self] in
                guard let self else { return }
                render(state: viewModel.state)
                observeViewModelState()
            }
        }
    }

    private func render(state: MainMemberCenterViewState) {
        switch state {
        case .idle:
            content = nil
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .loading:
            content = nil
            setLoadingVisible(true)
            collectionView.backgroundView = nil

        case .loaded(let content):
            self.content = content
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .failed(let message):
            content = nil
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadContent()
            }
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension MainMemberCenterViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        content == nil ? 0 : Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section), let content else { return 0 }

        switch section {
        case .profile:
            return 1

        case .menu:
            return content.menuItems.count
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let section = Section(rawValue: indexPath.section), let content else {
            return UICollectionViewCell()
        }

        switch section {
        case .profile:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainMemberCenterProfileCollectionViewCell.reuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainMemberCenterProfileCollectionViewCell {
                cell.configure(with: content.profile)
            }

            return cell

        case .menu:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainMemberCenterMenuItemCollectionViewCell.reuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainMemberCenterMenuItemCollectionViewCell,
               content.menuItems.indices.contains(indexPath.item) {
                cell.configure(with: content.menuItems[indexPath.item])
            }

            return cell
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainMemberCenterViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginTabBarVisibilityTracking(for: scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTabBarVisibilityTracking(for: scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let section = Section(rawValue: indexPath.section) else {
            return .zero
        }

        let width = collectionView.bounds.width - (Layout.horizontalInset * 2)
        let height: CGFloat

        switch section {
        case .profile:
            height = Layout.profileHeight

        case .menu:
            height = Layout.menuItemHeight
        }

        return CGSize(width: width, height: height)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard let section = Section(rawValue: section) else { return .zero }

        let topInset: CGFloat = section == .profile ? Layout.topInset : 0
        let bottomInset: CGFloat = section == .menu ? Layout.bottomInset : 0

        return UIEdgeInsets(
            top: topInset,
            left: Layout.horizontalInset,
            bottom: bottomInset,
            right: Layout.horizontalInset
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        8
    }
}
