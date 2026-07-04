//
//  MovieDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import UIKit

@MainActor
final class MovieDetailViewController: DetailBaseViewController {

    // MARK: - Properties

    private let movieID: Int
    private let viewModel: MovieDetailViewModel
    private var sections: [MovieDetailSectionItem] = []
    private var loadTask: Task<Void, Never>?
    private lazy var router: DetailRouting = DetailRouter(sourceViewController: self)

    // MARK: - Initialization

    convenience init(movieID: Int) {
        self.init(
            movieID: movieID,
            viewModel: MovieDetailViewModel()
        )
    }

    init(
        movieID: Int,
        viewModel: MovieDetailViewModel
    ) {
        self.movieID = movieID
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.movieID = 0
        self.viewModel = MovieDetailViewModel()
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.largeTitleDisplayMode = .never
        configureNavigationBar()
        configureCollectionView()
    }

    override func bindViewModel() {
        loadMovieDetail()
    }

    // MARK: - Setup

    private enum Layout {
        static let headerHeight: CGFloat = 28
        static let headerContentSpacing: CGFloat = 8
        static let defaultHorizontalInset: CGFloat = 16
        static let defaultSectionBottomInset: CGFloat = 24
        static let factsSectionHeight: CGFloat = 96
        static let castSectionHeight: CGFloat = 220
        static let videosSectionHeight: CGFloat = 160
        static let recommendationsSectionHeight: CGFloat = 220
    }

    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "text.bubble"),
            style: .plain,
            target: self,
            action: #selector(handleReviewButtonTapped)
        )
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ThemeColor.background
        collectionViewFlowLayout.minimumLineSpacing = 8
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        collectionView.register(
            MovieDetailOverviewCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailOverviewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailFactsCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailFactsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailAttributesCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailAttributesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailCastCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailCastCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailVideosCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailVideosCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailRecommendationsCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailRecommendationsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MovieDetailSectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            MovieDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MovieDetailHeroHeaderView.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadMovieDetail() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadMovieDetail(id: movieID)

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func render(state: MovieDetailViewState) {
        switch state {
        case .idle:
            sections = []
            setDetailNavigationTitle(nil)
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .loading:
            sections = []
            setDetailNavigationTitle(nil)
            setLoadingVisible(true)
            collectionView.backgroundView = nil

        case .loaded(let loadedSections):
            sections = loadedSections
            setDetailNavigationTitle(detailNavigationTitle(from: loadedSections))
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .failed(let message):
            sections = []
            setDetailNavigationTitle(nil)
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadMovieDetail()
            }
        }

        collectionView.reloadData()
    }

    // MARK: - Actions

    @objc private func handleReviewButtonTapped() {
        let viewController = MovieReviewListViewController(movieID: movieID)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func detailNavigationTitle(from sections: [MovieDetailSectionItem]) -> String? {
        guard case .overview(let item) = sections.first else { return nil }
        return item.hero.title.isEmpty ? item.hero.originalTitle : item.hero.title
    }
}

// MARK: - UICollectionViewDataSource

extension MovieDetailViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if case .overview(let item) = sections[section] {
            return item.overview == nil ? 0 : 1
        }

        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch sections[indexPath.section] {
        case .overview(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailOverviewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailOverviewCollectionViewCell)?.configure(overview: item.overview ?? "")
            return cell

        case .facts(let facts):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailFactsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailFactsCollectionViewCell)?.configure(facts: facts)
            return cell

        case .attributes(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailAttributesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailAttributesCollectionViewCell)?.configure(with: item)
            return cell

        case .cast(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailCastCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailCastCollectionViewCell)?.configure(items: items) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .videos(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailVideosCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailVideosCollectionViewCell)?.configure(items: items) { [weak self] item in
                guard let self else { return }

                if let youtubeVideoKey = item.youtubeVideoKey {
                    router.showYouTubeVideo(videoKey: youtubeVideoKey, title: item.title)
                } else if let videoURL = item.videoURL {
                    router.showWebVideo(url: videoURL, title: item.title)
                }
            }
            return cell

        case .recommendations(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailRecommendationsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailRecommendationsCollectionViewCell)?.configure(items: items) { [weak self] movieID in
                self?.router.showMovieDetail(movieID: movieID)
            }
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        if case .overview(let item) = sections[indexPath.section] {
            let reusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MovieDetailHeroHeaderView.reuseIdentifier,
                for: indexPath
            )

            if let headerView = reusableView as? MovieDetailHeroHeaderView {
                headerView.configure(with: item.hero)
            }

            return reusableView
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MovieDetailSectionHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MovieDetailSectionHeaderView {
            headerView.configure(title: sections[indexPath.section].title)
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MovieDetailViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDetailNavigationTitleVisibility(for: scrollView)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        if case .overview(let item) = sections[section] {
            return CGSize(
                width: collectionView.bounds.width,
                height: MovieDetailHeroHeaderView.headerHeight(
                    for: item.hero,
                    width: collectionView.bounds.width
                )
            )
        }

        guard sections[section].title != nil else {
            return .zero
        }

        return CGSize(
            width: collectionView.bounds.width,
            height: Layout.headerHeight
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        sectionInset(for: section)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let sectionInset = sectionInset(for: indexPath.section)
        let width = collectionView.bounds.width
            - sectionInset.left
            - sectionInset.right

        return CGSize(
            width: max(width, 0),
            height: height(for: sections[indexPath.section], width: max(width, 0))
        )
    }

    private func sectionInset(for section: Int) -> UIEdgeInsets {
        if case .overview(let item) = sections[section] {
            return UIEdgeInsets(
                top: item.overview == nil ? 0 : Layout.headerContentSpacing,
                left: Layout.defaultHorizontalInset,
                bottom: Layout.defaultSectionBottomInset,
                right: Layout.defaultHorizontalInset
            )
        }

        let topInset = sections[section].title == nil ? 0 : Layout.headerContentSpacing

        return UIEdgeInsets(
            top: topInset,
            left: Layout.defaultHorizontalInset,
            bottom: Layout.defaultSectionBottomInset,
            right: Layout.defaultHorizontalInset
        )
    }

    private func height(for section: MovieDetailSectionItem, width: CGFloat) -> CGFloat {
        switch section {
        case .overview(let item):
            guard let overview = item.overview else { return 0 }

            return MovieDetailOverviewCollectionViewCell.fittingHeight(
                for: overview,
                width: width
            )

        case .facts:
            return Layout.factsSectionHeight

        case .attributes(let item):
            return MovieDetailAttributesCollectionViewCell.fittingHeight(for: item)

        case .cast:
            return Layout.castSectionHeight

        case .videos:
            return Layout.videosSectionHeight

        case .recommendations:
            return Layout.recommendationsSectionHeight
        }
    }

}
