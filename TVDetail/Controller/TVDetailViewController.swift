//
//  TVDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import UIKit

@MainActor
final class TVDetailViewController: DetailActionBarViewController {

    // MARK: - Properties

    private let seriesID: Int
    private let viewModel: TVDetailViewModel
    private let sceneBuilder: DetailSceneBuilding
    private lazy var router: TVDetailRouting = TVDetailRouter(
        sourceViewController: self,
        seriesID: seriesID,
        sceneBuilder: sceneBuilder,
        interfaceLocalization: interfaceLocalization
    )
    private lazy var shareBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "square.and.arrow.up"),
        primaryAction: UIAction { [weak self] _ in
            self?.handleShareButtonTapped()
        }
    )

    private var shareURL: URL? {
        TMDBResourceURL.tvSeries(id: seriesID)
    }

    private var sections: [TVDetailSectionItem] = []

    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        seriesID: Int,
        viewModel: TVDetailViewModel,
        sceneBuilder: DetailSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.seriesID = seriesID
        self.viewModel = viewModel
        self.sceneBuilder = sceneBuilder
        super.init(nibName: nil, bundle: nil)
        setInterfaceLocalization(interfaceLocalization)
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
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 148,
                imageHeight: 112
            )
        }

        static var seasonsSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 220,
                imageHeight: 168
            )
        }

        static var imagesSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 168,
                imageHeight: 124
            )
        }

        static var recommendationsSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 220,
                imageHeight: 168
            )
        }

        static var watchProvidersSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 144,
                imageHeight: 96
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
            TVDetailOverviewCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailOverviewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            TVDetailFactsCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailFactsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            TVDetailAttributesCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailAttributesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            TVDetailCastCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailCastCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            TVDetailCrewCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailCrewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            TVDetailVideosCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailVideosCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            TVDetailImagesCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailImagesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            TVDetailSeasonsCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailSeasonsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            TVDetailRecommendationsCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailRecommendationsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            TVDetailWatchProvidersCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailWatchProvidersCollectionViewCell.reuseIdentifier
        )
        registerDetailSectionHeader()
        collectionView.register(
            TVDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TVDetailHeroHeaderView.reuseIdentifier
        )
    }

    private func makeLayoutSection(for section: TVDetailSectionItem) -> NSCollectionLayoutSection {
        let contentWidth = collectionView.bounds.width

        return DetailCompositionalLayout.singleItemSection(
            height: itemHeightDimension(for: section, width: contentWidth),
            topContentInset: sectionTopContentInset(for: section),
            header: sectionHeader(for: section)
        )
    }

    private func sectionHeader(for section: TVDetailSectionItem) -> DetailCompositionalLayout.SectionHeader {
        switch section {
        case .overview:
            return .estimatedHero

        default:
            return section.title(localization: interfaceLocalization) == nil
                ? .none
                : .sectionTitle
        }
    }

    private func sectionTopContentInset(for section: TVDetailSectionItem) -> CGFloat {
        if case .overview(let item) = section {
            return item.overview == nil ? 0 : DetailLayoutMetrics.headerContentSpacing
        }

        return section.title(localization: interfaceLocalization) == nil
            ? 0
            : DetailLayoutMetrics.headerContentSpacing
    }

    private func itemHeightDimension(
        for section: TVDetailSectionItem,
        width: CGFloat
    ) -> NSCollectionLayoutDimension {
        switch section {
        case .overview(let item):
            guard let overview = item.overview else {
                return .absolute(1)
            }

            return .absolute(
                TVDetailOverviewCollectionViewCell.fittingHeight(
                    for: overview,
                    width: width,
                    localization: interfaceLocalization
                )
            )

        case .facts:
            return .absolute(DetailLayoutMetrics.factsSectionHeight)

        case .videos:
            return .absolute(Layout.videosSectionHeight)

        case .attributes(let item):
            return .absolute(TVDetailAttributesCollectionViewCell.fittingHeight(for: item))

        case .cast:
            return .absolute(Layout.castSectionHeight)

        case .crew:
            return .absolute(Layout.crewSectionHeight)

        case .seasons:
            return .absolute(Layout.seasonsSectionHeight)

        case .images:
            return .absolute(Layout.imagesSectionHeight)

        case .recommendations, .similar:
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
            await viewModel.loadInitialContent(seriesID: seriesID)
        }
    }

    private func render(state: TVDetailViewState) {
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

    private func updateDetailUserActivity(from sections: [TVDetailSectionItem]) {
        guard let hero = sections.compactMap(\.heroItem).first else {
            clearDetailUserActivity()
            return
        }

        userActivity = DetailUserActivityFactory.tvActivity(hero: hero)
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
                return await viewModel.toggleFavorite(seriesID: seriesID)
            }
        )
    }

    private func presentRatingSheet() {
        router.showRatingPageSheet(
            title: interfaceLocalization.string(
                "tv_detail.rating.title",
                defaultValue: "Rate This TV Show"
            ),
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
                return await viewModel.submitRating(seriesID: seriesID, value: value)
            }
        )
    }

    private func deleteRating() {
        performRatingUpdate(
            pendingValue: nil,
            operation: { [weak self] in
                guard let self else { return nil }
                return await viewModel.deleteRating(seriesID: seriesID)
            }
        )
    }

    private func detailNavigationTitle(from sections: [TVDetailSectionItem]) -> String? {
        guard case .overview(let item) = sections.first else { return nil }
        return item.hero.title.isEmpty ? item.hero.originalTitle : item.hero.title
    }
}

// MARK: - TVDetailSectionItem Intent Support

private extension TVDetailSectionItem {
    var heroItem: TVDetailHeroItem? {
        switch self {
        case .overview(let item):
            return item.hero

        case .facts,
             .videos,
             .attributes,
             .cast,
             .crew,
             .seasons,
             .images,
             .recommendations,
             .similar,
             .watchProviders:
            return nil
        }
    }
}

// MARK: - UICollectionViewDataSource

extension TVDetailViewController: UICollectionViewDataSource {

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
                withReuseIdentifier: TVDetailOverviewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailOverviewCollectionViewCell)?.configure(
                overview: item.overview ?? "",
                localization: interfaceLocalization
            )
            return cell

        case .facts(let facts):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailFactsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailFactsCollectionViewCell)?.configure(facts: facts)
            return cell

        case .videos(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailVideosCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailVideosCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount)),
                localization: interfaceLocalization
            ) { [weak self] item in
                guard let self else { return }

                if let youtubeVideoKey = item.youtubeVideoKey {
                    router.showYouTubeVideo(videoKey: youtubeVideoKey, title: item.title)
                } else if let videoURL = item.videoURL {
                    router.showWebVideo(url: videoURL, title: item.title)
                }
            }
            return cell

        case .attributes(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailAttributesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailAttributesCollectionViewCell)?.configure(
                with: item,
                localization: interfaceLocalization
            ) { [weak self] attribute in
                switch attribute.kind {
                case .genre:
                    self?.router.showGenreList(genreID: attribute.sourceID)

                case .productionCompany:
                    self?.router.showCompanyDetail(companyID: attribute.sourceID)

                case .network:
                    break
                }
            }
            return cell

        case .cast(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailCastCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailCastCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount)),
                localization: interfaceLocalization
            ) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .crew(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailCrewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailCrewCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount)),
                localization: interfaceLocalization
            ) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .seasons(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailSeasonsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailSeasonsCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            ) { [weak self] seasonNumber in
                self?.router.showSeasonDetail(seasonNumber: seasonNumber)
            }
            return cell

        case .images(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailImagesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            let previewItems = Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            let previewTitle = interfaceLocalization.string(
                "detail.section.images",
                defaultValue: "Images"
            )
            (cell as? TVDetailImagesCollectionViewCell)?.configure(
                items: previewItems,
                localization: interfaceLocalization
            ) { [weak self] imageItem in
                self?.router.showImagePreview(
                    imageURLs: items.map(\.imageURL),
                    selectedImageURL: imageItem.imageURL,
                    title: previewTitle
                )
            }
            return cell

        case .recommendations(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailRecommendationsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailRecommendationsCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount)),
                localization: interfaceLocalization
            ) { [weak self] seriesID in
                self?.router.showTVDetail(seriesID: seriesID)
            }
            return cell

        case .similar(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailRecommendationsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailRecommendationsCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount)),
                localization: interfaceLocalization
            ) { [weak self] seriesID in
                self?.router.showTVDetail(seriesID: seriesID)
            }
            return cell

        case .watchProviders(let providers):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailWatchProvidersCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailWatchProvidersCollectionViewCell)?.configure(
                providers: providers,
                localization: interfaceLocalization
            ) { [weak self] provider in
                guard let linkURL = provider.linkURL else { return }
                self?.router.showWatchProvider(url: linkURL, title: provider.title)
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
                withReuseIdentifier: TVDetailHeroHeaderView.reuseIdentifier,
                for: indexPath
            )

            if let headerView = reusableView as? TVDetailHeroHeaderView {
                headerView.configure(with: item.hero)
            }

            return reusableView
        }

        let section = sections[indexPath.section]
        let onTap: (() -> Void)?
        if let configuration = section.contentListConfiguration(
            localization: interfaceLocalization
        ) {
            onTap = { [weak self] in
                self?.router.showContentList(configuration)
            }
        } else {
            onTap = nil
        }
        return dequeueDetailSectionHeader(
            at: indexPath,
            title: section.title(localization: interfaceLocalization),
            onTap: onTap
        )
    }
}

// MARK: - UICollectionViewDelegate

extension TVDetailViewController: UICollectionViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDetailNavigationTitleVisibility(for: scrollView)
    }
}
