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
        static let sectionHeaderHeight: CGFloat = 32
        static let contentItemHeight: CGFloat = 232
        static let guestLoginItemHeight: CGFloat = 220
        static let sectionSpacing: CGFloat = 12
        static let bottomInset: CGFloat = 32
    }

    // MARK: - Properties

    private let viewModel: MainMemberCenterViewModel
    private lazy var router: MainMemberCenterRouting = MainMemberCenterRouter(sourceViewController: self)
    private var loadTask: Task<Void, Never>?

    private let profileHeaderView = MainMemberCenterProfileHeaderView(
        frame: CGRect(
            origin: .zero,
            size: CGSize(width: 0, height: MainMemberCenterProfileLayout.headerHeight)
        )
    )

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
        configureNavigationBarAppearance()
        navigationItem.title = "會員中心"
        profileHeaderView.isHidden = true
        configureCollectionView()
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(profileHeaderView)
        profileHeaderView.onTap = { [weak self] in
            self?.showProfileAction()
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        profileHeaderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(MainMemberCenterProfileLayout.headerHeight)
        }
    }

    override func bindViewModel() {
        render(state: viewModel.state)
        observeViewModelState()
        loadContent()
    }

    func refreshContentFromTabSelection() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.refreshContentFromTabSelection()
        }
    }

    // MARK: - Setup

    private func configureNavigationBarAppearance() {
        AppFactory.NavigationBar.applyStandardAppearance(to: navigationItem)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(profileHeaderView)
        updateProfileHeaderInsets()
    }

    private func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.minimumLineSpacing = Layout.sectionSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = 0
        registerSectionCells()
        collectionView.register(
            MainHomeSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier
        )
    }

    private func registerSectionCells() {
        collectionView.register(
            MainMemberCenterGuestLoginCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberCenterGuestLoginCollectionViewCell.reuseIdentifier
        )

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
            updateProfileHeaderVisibility(isVisible: false)
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .loading:
            renderHeaderContentIfAvailable()
            setLoadingVisible(true)
            collectionView.backgroundView = nil

        case .guest, .loaded:
            renderHeaderContentIfAvailable()
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .empty:
            renderHeaderContentIfAvailable()
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: .emptyMemberCenterContent)

        case .failed(let message):
            updateProfileHeaderVisibility(isVisible: false)
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadContent()
            }
        }

        collectionView.reloadData()
    }

    private func renderHeaderContentIfAvailable() {
        guard let headerContent = viewModel.headerContent else {
            updateProfileHeaderVisibility(isVisible: false)
            return
        }

        profileHeaderView.configure(with: headerContent)
        updateProfileHeaderVisibility(isVisible: true)
    }

    private func updateProfileHeaderVisibility(isVisible: Bool) {
        profileHeaderView.isHidden = !isVisible
        updateProfileHeaderInsets()

        guard isVisible else { return }
        view.bringSubviewToFront(profileHeaderView)
    }

    private func updateProfileHeaderInsets() {
        let topInset = profileHeaderView.isHidden ? 0 : MainMemberCenterProfileLayout.headerHeight
        collectionView.contentInset.top = topInset
        collectionView.verticalScrollIndicatorInsets.top = topInset
    }

    private func showProfileAction() {
        router.showProfileAction(viewModel.profileAction)
    }

    private func showList(for destination: MainMemberCenterDestination) {
        guard let route = viewModel.listRoute(for: destination) else { return }
        router.showList(route)
    }
}

// MARK: - UICollectionViewDataSource

extension MainMemberCenterViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.displaySections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard viewModel.displaySections.indices.contains(indexPath.section) else {
            return UICollectionViewCell()
        }

        switch viewModel.displaySections[indexPath.section] {
        case .guestLogin(let prompt):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainMemberCenterGuestLoginCollectionViewCell.reuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainMemberCenterGuestLoginCollectionViewCell {
                cell.configure(with: prompt)
            }

            return cell

        case .content(let contentSection):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: contentSection.id.sectionCellReuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainMemberCenterListStripCollectionViewCell {
                cell.configure(items: contentSection.items) { [weak self] item in
                    self?.router.showDetail(for: item)
                }
            } else if let cell = cell as? MainMemberCenterContentStripCollectionViewCell {
                cell.configure(items: contentSection.items) { [weak self] item in
                    self?.router.showDetail(for: item)
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
              viewModel.displaySections.indices.contains(indexPath.section) else {
            return UICollectionReusableView()
        }

        guard case .content(let contentSection) = viewModel.displaySections[indexPath.section] else {
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

        guard viewModel.displaySections.indices.contains(indexPath.section) else { return }

        switch viewModel.displaySections[indexPath.section] {
        case .guestLogin:
            router.showProfileAction(viewModel.profileAction)

        case .content:
            return
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let height: CGFloat

        if viewModel.displaySections.indices.contains(indexPath.section),
           case .guestLogin = viewModel.displaySections[indexPath.section] {
            height = Layout.guestLoginItemHeight
        } else {
            height = Layout.contentItemHeight
        }

        return CGSize(
            width: collectionView.bounds.width,
            height: height
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        let isLastSection = section == viewModel.displaySections.count - 1
        return UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: isLastSection ? Layout.bottomInset : Layout.sectionSpacing,
            right: 0
        )
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
        guard viewModel.displaySections.indices.contains(section),
              case .content = viewModel.displaySections[section] else {
            return .zero
        }

        return CGSize(
            width: collectionView.bounds.width,
            height: Layout.sectionHeaderHeight
        )
    }
}
