//
//  MovieDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import UIKit

@MainActor
final class MovieDetailViewController: DetailActionBarViewController {

    // MARK: - Properties

    private let movieID: Int
    private let viewModel: MovieDetailViewModel
    private let sceneBuilder: DetailSceneBuilding
    private lazy var router: MovieDetailRouting = MovieDetailRouter(
        sourceViewController: self,
        movieID: movieID,
        sceneBuilder: sceneBuilder
    )
    private lazy var shareBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "square.and.arrow.up"),
        primaryAction: UIAction { [weak self] _ in
            self?.handleShareButtonTapped()
        }
    )

    private var shareURL: URL? {
        TMDBResourceURL.movie(id: movieID)
    }

    private var sections: [MovieDetailSectionItem] = []

    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        movieID: Int,
        viewModel: MovieDetailViewModel,
        sceneBuilder: DetailSceneBuilding
    ) {
        self.movieID = movieID
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
        configureShareButton()
        configureActionBar()
        configureCollectionView()
    }

    override func bindViewModel() {
        viewModel.bind(
            onStateChange: { [weak self] state in
                self?.render(state: state)
            },
            onAccountStateChange: { [weak self] favoriteState, ratingState in
                self?.updateFavoriteAction(with: favoriteState)
                self?.updateRatingAction(with: ratingState)
            }
        )
        loadInitialContent()
    }

    // MARK: - Setup

    private enum Layout {
        static var castSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 220,
                imageHeight: 168
            )
        }

        static var crewSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 220,
                imageHeight: 168
            )
        }

        static var videosSectionHeight: CGFloat {
            DetailImageTitleStripMetrics.landscapePreviewSectionHeight
        }

        static var imagesSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 168,
                imageHeight: 124
            )
        }

        static var watchProvidersSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 144,
                imageHeight: 96
            )
        }

        static var recommendationsSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 220,
                imageHeight: 168
            )
        }
    }

    override func makeCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self, sectionIndex < self.sections.count else {
                return DetailCompositionalLayout.singleItemSection(
                    height: .absolute(1),
                    topContentInset: 0,
                    bottomContentInset: 0,
                    header: .none
                )
            }

            return self.makeLayoutSection(for: self.sections[sectionIndex])
        }
    }

    private func configureShareButton() {
        navigationItem.rightBarButtonItem = shareBarButtonItem
        shareBarButtonItem.isEnabled = shareURL != nil
    }

    private func configureActionBar() {
        configureDetailActions(
            showsFavorite: true,
            showsRating: true,
            showsReview: true,
            favoriteAction: { [weak self] in self?.handleFavoriteButtonTapped() },
            ratingAction: { [weak self] in self?.handleRatingButtonTapped() },
            reviewAction: { [weak self] in self?.router.showReviewList() }
        )
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
            MovieDetailCrewCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailCrewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailVideosCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailVideosCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailImagesCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailImagesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailCollectionPartsCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailCollectionPartsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailWatchProvidersCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailWatchProvidersCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailRecommendationsCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailRecommendationsCollectionViewCell.reuseIdentifier
        )
        registerDetailSectionHeader()
        collectionView.register(
            MovieDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MovieDetailHeroHeaderView.reuseIdentifier
        )
    }

    private func makeLayoutSection(for section: MovieDetailSectionItem) -> NSCollectionLayoutSection {
        let contentWidth = collectionView.bounds.width

        return DetailCompositionalLayout.singleItemSection(
            height: itemHeightDimension(for: section, width: contentWidth),
            topContentInset: sectionTopContentInset(for: section),
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

    private func sectionTopContentInset(for section: MovieDetailSectionItem) -> CGFloat {
        if case .overview(let item) = section {
            return item.overview == nil ? 0 : DetailLayoutMetrics.headerContentSpacing
        }

        return section.title == nil ? 0 : DetailLayoutMetrics.headerContentSpacing
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
            return .absolute(DetailLayoutMetrics.factsSectionHeight)

        case .attributes(let item):
            return .absolute(MovieDetailAttributesCollectionViewCell.fittingHeight(for: item))

        case .cast:
            return .absolute(Layout.castSectionHeight)

        case .crew:
            return .absolute(Layout.crewSectionHeight)

        case .videos:
            return .absolute(Layout.videosSectionHeight)

        case .images:
            return .absolute(Layout.imagesSectionHeight)

        case .collection, .recommendations, .similar:
            return .absolute(Layout.recommendationsSectionHeight)

        case .watchProviders:
            return .absolute(Layout.watchProvidersSectionHeight)
        }
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitialContent(movieID: movieID)
        }
    }

    private func render(state: MovieDetailViewState) {
        switch state {
        case .idle:
            sections = []
            renderDetailContent(.idle)
            clearDetailUserActivity()

        case .loading:
            sections = []
            renderDetailContent(.loading)
            clearDetailUserActivity()

        case .loaded(let loadedSections):
            sections = loadedSections
            renderDetailContent(
                .loaded(navigationTitle: detailNavigationTitle(from: loadedSections))
            )
            updateDetailUserActivity(from: loadedSections)

        case .failed(let message):
            sections = []
            renderDetailContent(
                .failed(message: message) { [weak self] in self?.loadInitialContent() }
            )
            clearDetailUserActivity()
        }

        collectionView.reloadData()
    }

    private func updateDetailUserActivity(from sections: [MovieDetailSectionItem]) {
        guard let hero = sections.compactMap(\.heroItem).first else {
            clearDetailUserActivity()
            return
        }

        userActivity = DetailUserActivityFactory.movieActivity(hero: hero)
        userActivity?.becomeCurrent()
    }

    private func clearDetailUserActivity() {
        userActivity?.resignCurrent()
        userActivity = nil
    }

    // MARK: - Actions

    private func handleShareButtonTapped() {
        guard let shareURL else { return }
        router.showShareSheet(for: shareURL, sourceItem: shareBarButtonItem)
    }

    private func handleRatingButtonTapped() {
        if viewModel.ratingState.requiresUserLogin {
            router.showLogin()
            return
        }

        presentRatingSheet()
    }

    private func handleFavoriteButtonTapped() {
        if viewModel.favoriteState.requiresUserLogin {
            router.showLogin()
            return
        }

        performFavoriteUpdate(
            from: viewModel.favoriteState,
            operation: { [weak self] in
                guard let self else { return nil }
                return await viewModel.toggleFavorite(movieID: movieID)
            }
        )
    }

    private func presentRatingSheet() {
        router.showRatingPageSheet(
            title: "為這部電影評分",
            currentValue: viewModel.ratingState.value,
            defaultValue: viewModel.ratingDefaultValue,
            onSubmit: { [weak self] value in
                self?.submitRating(value)
            },
            onDelete: { [weak self] in
                self?.deleteRating()
            }
        )
    }

    private func submitRating(_ value: Double) {
        performRatingUpdate(
            pendingValue: value,
            operation: { [weak self] in
                guard let self else { return nil }
                return await viewModel.submitRating(movieID: movieID, value: value)
            }
        )
    }

    private func deleteRating() {
        performRatingUpdate(
            pendingValue: nil,
            operation: { [weak self] in
                guard let self else { return nil }
                return await viewModel.deleteRating(movieID: movieID)
            }
        )
    }

    private func detailNavigationTitle(from sections: [MovieDetailSectionItem]) -> String? {
        guard case .overview(let item) = sections.first else { return nil }
        return item.hero.title.isEmpty ? item.hero.originalTitle : item.hero.title
    }
}

// MARK: - MovieDetailSectionItem Intent Support

private extension MovieDetailSectionItem {
    var heroItem: MovieDetailHeroItem? {
        switch self {
        case .overview(let item):
            return item.hero

        case .facts,
             .attributes,
             .cast,
             .crew,
             .videos,
             .images,
             .collection,
             .watchProviders,
             .recommendations,
             .similar:
            return nil
        }
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
            (cell as? MovieDetailAttributesCollectionViewCell)?.configure(
                with: item
            ) { [weak self] attribute in
                guard attribute.kind == .genre else { return }
                self?.router.showGenreList(genreID: attribute.sourceID)
            }
            return cell

        case .cast(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailCastCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailCastCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            ) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .crew(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailCrewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailCrewCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            ) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .videos(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailVideosCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailVideosCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            ) { [weak self] item in
                guard let self else { return }

                if let youtubeVideoKey = item.youtubeVideoKey {
                    router.showYouTubeVideo(videoKey: youtubeVideoKey, title: item.title)
                } else if let videoURL = item.videoURL {
                    router.showWebVideo(url: videoURL, title: item.title)
                }
            }
            return cell

        case .images(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailImagesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            let previewItems = Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            (cell as? MovieDetailImagesCollectionViewCell)?.configure(
                items: previewItems
            ) { [weak self] imageItem in
                self?.router.showImagePreview(
                    imageURLs: items.map(\.imageURL),
                    selectedImageURL: imageItem.imageURL,
                    title: "劇照"
                )
            }
            return cell

        case .collection(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailCollectionPartsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailCollectionPartsCollectionViewCell)?.configure(
                item: item
            ) { [weak self] movieID in
                self?.router.showMovieDetail(movieID: movieID)
            }
            return cell

        case .watchProviders(let providers):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailWatchProvidersCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailWatchProvidersCollectionViewCell)?.configure(
                providers: providers
            ) { [weak self] provider in
                guard let linkURL = provider.linkURL else { return }
                self?.router.showWatchProvider(url: linkURL, title: provider.title)
            }
            return cell

        case .recommendations(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailRecommendationsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailRecommendationsCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            ) { [weak self] movieID in
                self?.router.showMovieDetail(movieID: movieID)
            }
            return cell

        case .similar(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailRecommendationsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailRecommendationsCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            ) { [weak self] movieID in
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

        let section = sections[indexPath.section]
        let onTap: (() -> Void)?
        if let configuration = section.contentListConfiguration {
            onTap = { [weak self] in
                self?.router.showContentList(configuration)
            }
        } else {
            onTap = nil
        }
        return dequeueDetailSectionHeader(at: indexPath, title: section.title, onTap: onTap)
    }
}

// MARK: - UICollectionViewDelegate

extension MovieDetailViewController: UICollectionViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDetailNavigationTitleVisibility(for: scrollView)
    }
}
