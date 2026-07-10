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
        static let profileHeight: CGFloat = 160
        static let sectionHeaderHeight: CGFloat = 32
        static let contentItemHeight: CGFloat = 232
        static let sectionSpacing: CGFloat = 12
        static let horizontalInset: CGFloat = 16
        static let topInset: CGFloat = 24
        static let bottomInset: CGFloat = 32
    }

    private enum Section {
        case profile(MainMemberCenterProfile)
        case content(MainMemberCenterSection)
    }

    // MARK: - Properties

    private let session: AuthSession
    private let viewModel: MainMemberCenterViewModel
    private var sections: [Section] = []
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(session: AuthSession) {
        self.session = session
        self.viewModel = MainMemberCenterViewModel(session: session)
        super.init(nibName: nil, bundle: nil)
    }

    init(viewModel: MainMemberCenterViewModel) {
        self.session = .loggedOut
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.session = .loggedOut
        self.viewModel = MainMemberCenterViewModel(session: .loggedOut)
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        title = nil
        navigationItem.largeTitleDisplayMode = .never
        configureCollectionView()
    }

    override func bindViewModel() {
        render(state: viewModel.state)
        observeViewModelState()
        loadContent()
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        registerSectionCells()
        collectionView.register(
            MainHomeSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier
        )
    }

    private func registerSectionCells() {
        let cellTypes: [UICollectionViewCell.Type] = [
            MainMemberCenterFavoriteMoviesSectionCollectionViewCell.self,
            MainMemberCenterFavoriteTVSectionCollectionViewCell.self,
            MainMemberCenterWatchlistMoviesSectionCollectionViewCell.self,
            MainMemberCenterWatchlistTVSectionCollectionViewCell.self,
            MainMemberCenterRatedMoviesSectionCollectionViewCell.self,
            MainMemberCenterRatedTVSectionCollectionViewCell.self,
            MainMemberCenterRatedEpisodesSectionCollectionViewCell.self,
            MainMemberCenterListsSectionCollectionViewCell.self
        ]

        for cellType in cellTypes {
            collectionView.register(
                cellType,
                forCellWithReuseIdentifier: String(describing: cellType)
            )
        }
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
            sections = []
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .loading:
            sections = []
            setLoadingVisible(true)
            collectionView.backgroundView = nil

        case .loaded(let content):
            sections = makeSections(for: content)
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .failed(let message):
            sections = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadContent()
            }
        }

        collectionView.reloadData()
    }

    private func makeSections(for content: MainMemberCenterContent) -> [Section] {
        [.profile(content.profile)] + content.contentSections.map(Section.content)
    }

    private func showList(for destination: MainMemberCenterDestination) {
        guard case .user(let sessionId) = session,
              let accountId = sections.compactMap({ section -> Int? in
                  if case .profile(let profile) = section {
                      return profile.id
                  }
                  return nil
              }).first else {
            return
        }

        let viewController = MainMemberCenterListViewController(
            destination: destination,
            accountId: accountId,
            sessionId: sessionId
        )
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension MainMemberCenterViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard sections.indices.contains(indexPath.section) else {
            return UICollectionViewCell()
        }

        switch sections[indexPath.section] {
        case .profile(let profile):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainMemberCenterProfileCollectionViewCell.reuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainMemberCenterProfileCollectionViewCell {
                cell.configure(with: profile)
            }

            return cell

        case .content(let contentSection):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: contentSection.id.sectionCellReuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainMemberCenterContentStripCollectionViewCell {
                cell.configure(items: contentSection.items) { [weak self] _ in
                    self?.showList(for: contentSection.id)
                }
            }

            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              sections.indices.contains(indexPath.section),
              case .content(let contentSection) = sections[indexPath.section] else {
            return UICollectionReusableView()
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MainHomeSectionHeaderView {
            headerView.configure(title: contentSection.title)
            headerView.onTitleTapped = { [weak self] in
                self?.showList(for: contentSection.id)
            }
        }

        return reusableView
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
        guard sections.indices.contains(indexPath.section) else {
            return .zero
        }

        switch sections[indexPath.section] {
        case .profile:
            return CGSize(
                width: collectionView.bounds.width - (Layout.horizontalInset * 2),
                height: Layout.profileHeight
            )

        case .content:
            return CGSize(
                width: collectionView.bounds.width,
                height: Layout.contentItemHeight
            )
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard sections.indices.contains(section) else { return .zero }

        switch sections[section] {
        case .profile:
            return UIEdgeInsets(
                top: Layout.topInset,
                left: Layout.horizontalInset,
                bottom: Layout.sectionSpacing,
                right: Layout.horizontalInset
            )

        case .content:
            let isLastSection = section == sections.count - 1
            return UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: isLastSection ? Layout.bottomInset : Layout.sectionSpacing,
                right: 0
            )
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        8
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        guard sections.indices.contains(section),
              case .content = sections[section] else {
            return .zero
        }

        return CGSize(
            width: collectionView.bounds.width,
            height: Layout.sectionHeaderHeight
        )
    }
}
