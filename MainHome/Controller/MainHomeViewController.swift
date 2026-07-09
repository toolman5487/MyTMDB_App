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
        static let itemHeight: CGFloat = 232
        static let headerContentSpacing: CGFloat = 8
        static let sectionBottomSpacing: CGFloat = 16
    }

    // MARK: - Properties

    private let viewModel: MainHomeViewModel
    private var sections: [MainHomeSectionItem] = []
    private var carouselItems: [MainHomeContentItem] = []
    private var loadTask: Task<Void, Never>?
    private lazy var router: MainHomeRouting = MainHomeRouter(sourceViewController: self)

    override var collectionViewItemHeight: CGFloat {
        Layout.itemHeight
    }

    // MARK: - Initialization

    init() {
        self.viewModel = MainHomeViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    init(viewModel: MainHomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MainHomeViewModel()
        super.init(coder: coder)
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        title = nil
        navigationItem.largeTitleDisplayMode = .never
        configureCollectionView()
    }

    override func bindViewModel() {
        loadHome()
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

    private func loadHome() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadHome()

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
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
                self?.loadHome()
            }
        }

        collectionView.reloadData()
    }

    // MARK: - Navigation

    private func showDetail(for item: MainHomeContentItem) {
        router.showDetail(for: item)
    }

    private func showSectionList(for category: MainHomeContentCategory) {
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
                    carouselItems: carouselItems
                )
                headerView.onCarouselSelected = { [weak self] item in
                    self?.showDetail(for: item)
                }
                headerView.onTitleTapped = { [weak self] in
                    self?.showSectionList(for: section.category)
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
            headerView.configure(title: section.title)
            headerView.onTitleTapped = { [weak self] in
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
            height: collectionViewItemHeight
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        let height = section == 0 && !carouselItems.isEmpty
            ? MainHomeFeaturedHeaderView.featuredHeight
            : Layout.headerHeight

        return CGSize(
            width: collectionView.bounds.width,
            height: height
        )
    }
}
