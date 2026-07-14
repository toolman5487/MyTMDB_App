//
//  MovieDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import SnapKit
import UIKit

@MainActor
final class MovieDetailViewController: DetailBaseViewController {

    // MARK: - Properties

    private let movieID: Int
    private let viewModel: MovieDetailViewModel
    private var sections: [MovieDetailSectionItem] = []
    private var loadTask: Task<Void, Never>?
    private var favoriteTask: Task<Void, Never>?
    private lazy var router: MovieDetailRouting = MovieDetailRouter(
        sourceViewController: self,
        movieID: movieID
    )
    private let bottomActionBarView = DetailBottomActionBarView()

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
        favoriteTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.largeTitleDisplayMode = .never
        configureActionBar()
        configureCollectionView()
    }

    override func bindViewModel() {
        loadMovieDetail()
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(bottomActionBarView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        bottomActionBarView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewBottomInset()
    }

    // MARK: - Setup

    private enum Layout {
        static let factsSectionHeight: CGFloat = 96
        static let castSectionHeight: CGFloat = 220
        static let videosSectionHeight: CGFloat = 160
        static let recommendationsSectionHeight: CGFloat = 220
    }

    override var updatesFlowLayoutItemSizeAutomatically: Bool {
        false
    }

    override func makeCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self, sectionIndex < self.sections.count else {
                return DetailCompositionalLayout.singleItemSection(
                    height: .absolute(1),
                    contentInsets: .zero,
                    header: .none
                )
            }

            return self.makeLayoutSection(for: self.sections[sectionIndex])
        }
    }

    private func configureActionBar() {
        bottomActionBarView.configureFavorite(isFavorite: false, isEnabled: false)
        bottomActionBarView.setFavoriteAction(target: self, action: #selector(handleBottomFavoriteButtonTapped))
        bottomActionBarView.setReviewAction(target: self, action: #selector(handleReviewButtonTapped))
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ThemeColor.background

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

    private func makeLayoutSection(for section: MovieDetailSectionItem) -> NSCollectionLayoutSection {
        let contentWidth = max(
            collectionView.bounds.width - (DetailCompositionalLayout.Metrics.horizontalInset * 2),
            0
        )

        return DetailCompositionalLayout.singleItemSection(
            height: itemHeightDimension(for: section, width: contentWidth),
            contentInsets: sectionContentInsets(for: section),
            header: sectionHeader(for: section)
        )
    }

    private func sectionHeader(for section: MovieDetailSectionItem) -> DetailCompositionalLayout.SectionHeader {
        switch section {
        case .overview:
            return .estimatedHero

        default:
            return section.title == nil ? .none : .sectionTitle
        }
    }

    private func sectionContentInsets(for section: MovieDetailSectionItem) -> NSDirectionalEdgeInsets {
        if case .overview(let item) = section {
            return DetailCompositionalLayout.contentInsets(
                top: item.overview == nil ? 0 : DetailCompositionalLayout.Metrics.headerContentSpacing
            )
        }

        return DetailCompositionalLayout.contentInsets(
            top: section.title == nil ? 0 : DetailCompositionalLayout.Metrics.headerContentSpacing
        )
    }

    private func itemHeightDimension(
        for section: MovieDetailSectionItem,
        width: CGFloat
    ) -> NSCollectionLayoutDimension {
        switch section {
        case .overview(let item):
            guard let overview = item.overview else {
                return .absolute(1)
            }

            return .absolute(
                MovieDetailOverviewCollectionViewCell.fittingHeight(
                    for: overview,
                    width: width
                )
            )

        case .facts:
            return .absolute(Layout.factsSectionHeight)

        case .attributes(let item):
            return .absolute(MovieDetailAttributesCollectionViewCell.fittingHeight(for: item))

        case .cast:
            return .absolute(Layout.castSectionHeight)

        case .videos:
            return .absolute(Layout.videosSectionHeight)

        case .recommendations:
            return .absolute(Layout.recommendationsSectionHeight)
        }
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
            updateFavoriteButton()
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
        router.showReviewList()
    }

    @objc private func handleBottomFavoriteButtonTapped() {
        handleFavoriteButtonTapped()
    }

    private func handleFavoriteButtonTapped() {
        if shouldNavigateToLogin() {
            router.showLogin()
            return
        }

        setPendingFavoriteButtonState()
        favoriteTask?.cancel()
        favoriteTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let message = await viewModel.toggleFavorite(movieID: movieID)

            guard !Task.isCancelled else { return }
            updateFavoriteButton()

            if let message {
                presentAlert(title: message.title, message: message.message, actionTitle: message.actionTitle ?? "OK")
            }
        }
    }

    private func detailNavigationTitle(from sections: [MovieDetailSectionItem]) -> String? {
        guard case .overview(let item) = sections.first else { return nil }
        return item.hero.title.isEmpty ? item.hero.originalTitle : item.hero.title
    }

    private func updateFavoriteButton() {
        bottomActionBarView.configureFavorite(
            isFavorite: viewModel.favoriteState.isFavorite,
            isEnabled: viewModel.favoriteState.isButtonEnabled
        )
    }

    private func setPendingFavoriteButtonState() {
        guard case .ready(let isFavorite) = viewModel.favoriteState else { return }
        bottomActionBarView.configureFavorite(isFavorite: !isFavorite, isEnabled: false)
    }

    private func shouldNavigateToLogin() -> Bool {
        if case .requiresUserLogin = viewModel.favoriteState {
            return true
        }

        return false
    }

    private func updateCollectionViewBottomInset() {
        let bottomInset = bottomActionBarView.bounds.height
        guard collectionView.contentInset.bottom != bottomInset else { return }

        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
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

// MARK: - UICollectionViewDelegate

extension MovieDetailViewController: UICollectionViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDetailNavigationTitleVisibility(for: scrollView)
    }
}
