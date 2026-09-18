//
//  MainHomeViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import UIKit

@MainActor
final class MainHomeViewController: MainBaseViewController {

    // MARK: - Constants

    private enum Layout {
        static let headerHeight: CGFloat = 32
        static let headerContentSpacing: CGFloat = 8
        static let sectionBottomSpacing: CGFloat = 16
        private static let posterHeight: CGFloat = 186
        private static let titleTopSpacing: CGFloat = 4
        private static let minimumItemHeight: CGFloat = 232

        static var itemHeight: CGFloat {
            let titleHeight = ceil(UIFont.preferredFont(forTextStyle: .caption1).lineHeight)
            let scoreHeight = ceil(UIFont.preferredFont(forTextStyle: .caption2).lineHeight)
            return max(
                minimumItemHeight,
                posterHeight + titleTopSpacing + titleHeight + scoreHeight
            )
        }
    }

    // MARK: - Properties

    private let viewModel: MainHomeViewModel
    private let sceneBuilder: HomeSceneBuilding
    private lazy var router: MainHomeRouting = MainHomeRouter(
        sourceViewController: self,
        sceneBuilder: sceneBuilder
    )

    private var sections: [MainHomeSectionItem] = []
    private var carouselItems: [HomeContentItem] = []

    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        viewModel: MainHomeViewModel,
        sceneBuilder: HomeSceneBuilding
    ) {
        self.viewModel = viewModel
        self.sceneBuilder = sceneBuilder
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        viewModel.bind { [weak self] state in
            self?.render(state: state)
        }
        loadInitialContent()
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
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionViewFlowLayout.minimumLineSpacing = 0
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(
            top: Layout.headerContentSpacing,
            left: 0,
            bottom: Layout.sectionBottomSpacing,
            right: 0
        )
        registerSectionCells()
        collectionView.register(
            MainHomeSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            MainHomeFeaturedHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainHomeFeaturedHeaderView.reuseIdentifier
        )
    }

    private func registerSectionCells() {
        let cellTypes: [UICollectionViewCell.Type] = [
            MainHomeTrendingMoviesSectionCollectionViewCell.self,
            MainHomeTrendingTVSectionCollectionViewCell.self,
            MainHomePopularMoviesSectionCollectionViewCell.self,
            MainHomePopularTVSectionCollectionViewCell.self,
            MainHomeOnTheAirTVSectionCollectionViewCell.self,
            MainHomeUpcomingMoviesSectionCollectionViewCell.self,
            MainHomeAiringTodayTVSectionCollectionViewCell.self,
            MainHomeTopRatedMoviesSectionCollectionViewCell.self,
            MainHomeTopRatedTVSectionCollectionViewCell.self
        ]

        for cellType in cellTypes {
            collectionView.register(
                cellType,
                forCellWithReuseIdentifier: String(describing: cellType)
            )
        }
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let viewModel = self?.viewModel else { return }
            await viewModel.loadInitialContent()
        }
    }

    private func render(state: MainHomeViewState) {
        switch state {
        case .idle:
            sections = []
            carouselItems = []
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .loading:
            sections = []
            carouselItems = []
            setLoadingVisible(true)
            collectionView.backgroundView = nil

        case .loaded(let loadedSections):
            carouselItems = loadedSections
                .first { $0.category == .nowPlayingMovies }?
                .contents ?? []
            sections = loadedSections.filter { $0.category != .nowPlayingMovies }
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .empty:
            sections = []
            carouselItems = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: .emptyContent)

        case .failed(let message):
            sections = []
            carouselItems = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadInitialContent()
            }
        }

        collectionView.reloadData()
    }

    // MARK: - Navigation

    private func showDetail(for item: HomeContentItem) {
        router.showDetail(for: item)
    }

    private func showSectionList(for category: HomeCategory) {
        router.showSectionList(for: category)
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeViewController: UICollectionViewDataSource {

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
        let section = sections[indexPath.section]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: section.category.sectionCellReuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainHomeContentStripCollectionViewCell {
            cell.configure(contents: section.contents) { [weak self] item in
                self?.showDetail(for: item)
            }
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        let shouldShowCarousel = indexPath.section == 0 && !carouselItems.isEmpty

        let section = sections[indexPath.section]

        if shouldShowCarousel {
            let reusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MainHomeFeaturedHeaderView.reuseIdentifier,
                for: indexPath
            )

            if let headerView = reusableView as? MainHomeFeaturedHeaderView {
                headerView.configure(
                    title: section.title,
                    carouselItems: carouselItems,
                    onTitleTap: { [weak self] in
                        self?.showSectionList(for: section.category)
                    }
                )
                headerView.onCarouselSelected = { [weak self] item in
                    self?.showDetail(for: item)
                }
            }

            return reusableView
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MainHomeSectionHeaderView {
            headerView.configure(title: section.title) { [weak self] in
                self?.showSectionList(for: section.category)
            }
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegate

extension MainHomeViewController: UICollectionViewDelegateFlowLayout {

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
        return CGSize(
            width: collectionView.bounds.width,
            height: Layout.itemHeight
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        let height = section == 0 && !carouselItems.isEmpty
            ? MainHomeFeaturedHeaderView.featuredHeight(
                for: collectionView.bounds.width,
                userInterfaceIdiom: traitCollection.userInterfaceIdiom
            )
            : Layout.headerHeight

        return CGSize(
            width: collectionView.bounds.width,
            height: height
        )
    }
}
