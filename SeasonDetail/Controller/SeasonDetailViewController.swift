//
//  SeasonDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import UIKit

@MainActor
final class SeasonDetailViewController: DetailBaseViewController {

    // MARK: - Properties

    private let seriesID: Int
    private let seasonNumber: Int
    private let viewModel: SeasonDetailViewModel
    private lazy var router: SeasonDetailRouting = SeasonDetailRouter(
        sourceViewController: self,
        seriesID: seriesID,
        seasonNumber: seasonNumber
    )

    private var sections: [SeasonDetailSectionItem] = []

    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    convenience init(
        seriesID: Int,
        seasonNumber: Int
    ) {
        self.init(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            viewModel: SeasonDetailViewModel()
        )
    }

    init(
        seriesID: Int,
        seasonNumber: Int,
        viewModel: SeasonDetailViewModel
    ) {
        self.seriesID = seriesID
        self.seasonNumber = seasonNumber
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.seriesID = 0
        self.seasonNumber = 0
        self.viewModel = SeasonDetailViewModel()
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        configureCollectionView()
    }

    override func bindViewModel() {
        loadSeasonDetail()
    }

    // MARK: - Setup

    private enum Layout {
        static let headerHeight: CGFloat = 28
        static let headerContentSpacing: CGFloat = 8
        static let defaultHorizontalInset: CGFloat = 16
        static let defaultSectionBottomInset: CGFloat = 24
        static let factsSectionHeight: CGFloat = 96
        static let trailerStyleSectionHeight: CGFloat = 160
        static let imageStripSectionHeight: CGFloat = 220
        static let watchProvidersSectionHeight: CGFloat = 144
        static let textSectionMinimumHeight: CGFloat = 80
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ThemeColor.background
        collectionViewFlowLayout.minimumLineSpacing = 8
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(
            top: 0,
            left: Layout.defaultHorizontalInset,
            bottom: 0,
            right: Layout.defaultHorizontalInset
        )

        collectionView.register(
            SeasonDetailOverviewCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailOverviewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailFactsCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailFactsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailEpisodesCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailEpisodesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailVideosCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailVideosCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailCastCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailCastCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailCrewCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailCrewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailImagesCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailImagesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailWatchProvidersCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailWatchProvidersCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailTextListCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailTextListCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SeasonDetailHeroHeaderView.reuseIdentifier
        )
        collectionView.register(
            SeasonDetailSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SeasonDetailSectionHeaderView.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadSeasonDetail() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadSeasonDetail(
                seriesID: seriesID,
                seasonNumber: seasonNumber
            )

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func render(state: SeasonDetailViewState) {
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

        case .loaded(let content):
            sections = content.sections
            setDetailNavigationTitle(content.navigationTitle)
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .failed(let message):
            sections = []
            setDetailNavigationTitle(nil)
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadSeasonDetail()
            }
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension SeasonDetailViewController: UICollectionViewDataSource {

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
                withReuseIdentifier: SeasonDetailOverviewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? SeasonDetailOverviewCollectionViewCell)?.configure(overview: item.overview ?? "")
            return cell

        case .facts(let facts):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SeasonDetailFactsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? SeasonDetailFactsCollectionViewCell)?.configure(facts: facts)
            return cell

        case .episodes(let episodes):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SeasonDetailEpisodesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? SeasonDetailEpisodesCollectionViewCell)?.configure(episodes: episodes) { [weak self] episodeNumber in
                self?.router.showEpisodeDetail(episodeNumber: episodeNumber)
            }
            return cell

        case .videos(let videos):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SeasonDetailVideosCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? SeasonDetailVideosCollectionViewCell)?.configure(videos: videos) { [weak self] video in
                guard let self else { return }
                if let youtubeVideoKey = video.youtubeVideoKey {
                    router.showYouTubeVideo(videoKey: youtubeVideoKey, title: video.title)
                } else if let videoURL = video.videoURL {
                    router.showWebVideo(url: videoURL, title: video.title)
                }
            }
            return cell

        case .cast(let cast):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SeasonDetailCastCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? SeasonDetailCastCollectionViewCell)?.configure(cast: cast) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .crew(let crew):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SeasonDetailCrewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? SeasonDetailCrewCollectionViewCell)?.configure(crew: crew) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .images(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SeasonDetailImagesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? SeasonDetailImagesCollectionViewCell)?.configure(gallery: item)
            return cell

        case .watchProviders(let providers):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SeasonDetailWatchProvidersCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? SeasonDetailWatchProvidersCollectionViewCell)?.configure(providers: providers) { [weak self] provider in
                guard let linkURL = provider.linkURL else { return }
                self?.router.showWatchProvider(url: linkURL, title: provider.title)
            }
            return cell

        case .accountState(let accountState):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SeasonDetailTextListCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? SeasonDetailTextListCollectionViewCell)?.configure(items: accountStateRows(from: accountState))
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
                withReuseIdentifier: SeasonDetailHeroHeaderView.reuseIdentifier,
                for: indexPath
            )

            if let headerView = reusableView as? SeasonDetailHeroHeaderView {
                headerView.configure(with: item.hero)
            }

            return reusableView
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SeasonDetailSectionHeaderView.reuseIdentifier,
            for: indexPath
        )
        (reusableView as? SeasonDetailSectionHeaderView)?.configure(title: sections[indexPath.section].title)
        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SeasonDetailViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDetailNavigationTitleVisibility(for: scrollView)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        if case .overview = sections[section] {
            return CGSize(
                width: collectionView.bounds.width,
                height: SeasonDetailHeroHeaderView.headerHeight
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
        let sectionInsets = sectionInset(for: indexPath.section)
        let width = collectionView.bounds.width
            - sectionInsets.left
            - sectionInsets.right
        let itemWidth = max(width, 0)
        let itemHeight = height(for: sections[indexPath.section], width: itemWidth)

        return CGSize(width: itemWidth, height: itemHeight)
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

    private func height(
        for section: SeasonDetailSectionItem,
        width: CGFloat
    ) -> CGFloat {
        switch section {
        case .overview(let item):
            guard let overview = item.overview else { return 0 }

            return SeasonDetailOverviewCollectionViewCell.fittingHeight(
                for: overview,
                width: width
            )

        case .facts:
            return Layout.factsSectionHeight

        case .episodes, .videos:
            return Layout.trailerStyleSectionHeight

        case .cast, .crew, .images:
            return Layout.imageStripSectionHeight

        case .watchProviders:
            return Layout.watchProvidersSectionHeight

        case .accountState(let accountState):
            return max(
                Layout.textSectionMinimumHeight,
                SeasonDetailTextListCollectionViewCell.fittingHeight(
                    for: accountStateRows(from: accountState),
                    width: width
                )
            )
        }
    }
}

// MARK: - Presentation Mapping

private extension SeasonDetailViewController {

    func accountStateRows(from accountState: SeasonAccountStateItem) -> [SeasonDetailTextListItem] {
        [
            SeasonDetailTextListItem(
                id: "rating",
                title: "你的評分",
                subtitle: accountState.ratingText
            )
        ]
    }
}
