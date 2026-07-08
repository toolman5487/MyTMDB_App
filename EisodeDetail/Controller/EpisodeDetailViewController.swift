//
//  EpisodeDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/8.
//

import Foundation
import UIKit

@MainActor
final class EpisodeDetailViewController: DetailBaseViewController {

    // MARK: - Properties

    private let seriesID: Int
    private let seasonNumber: Int
    private let episodeNumber: Int
    private let viewModel: EpisodeDetailViewModel
    private var sections: [EpisodeDetailSectionItem] = []
    private var loadTask: Task<Void, Never>?
    private lazy var router: DetailRouting = DetailRouter(sourceViewController: self)

    // MARK: - Initialization

    convenience init(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) {
        self.init(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            viewModel: EpisodeDetailViewModel()
        )
    }

    init(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int,
        viewModel: EpisodeDetailViewModel
    ) {
        self.seriesID = seriesID
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.seriesID = 0
        self.seasonNumber = 0
        self.episodeNumber = 0
        self.viewModel = EpisodeDetailViewModel()
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
        loadEpisodeDetail()
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
            EpisodeDetailOverviewCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailOverviewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailFactsCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailFactsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailVideosCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailVideosCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailCastCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailCastCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailGuestStarsCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailGuestStarsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailCrewCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailCrewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailImagesCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailImagesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailExternalLinksCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailExternalLinksCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailAccountStateCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailAccountStateCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: EpisodeDetailHeroHeaderView.reuseIdentifier
        )
        collectionView.register(
            EpisodeDetailSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: EpisodeDetailSectionHeaderView.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadEpisodeDetail() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadEpisodeDetail(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func render(state: EpisodeDetailViewState) {
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
                self?.loadEpisodeDetail()
            }
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension EpisodeDetailViewController: UICollectionViewDataSource {

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
                withReuseIdentifier: EpisodeDetailOverviewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? EpisodeDetailOverviewCollectionViewCell)?.configure(overview: item.overview ?? "")
            return cell

        case .facts(let facts):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EpisodeDetailFactsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? EpisodeDetailFactsCollectionViewCell)?.configure(facts: facts)
            return cell

        case .videos(let videos):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EpisodeDetailVideosCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? EpisodeDetailVideosCollectionViewCell)?.configure(videos: videos) { [weak self] video in
                guard let self else { return }
                if let youtubeVideoKey = video.youtubeVideoKey {
                    router.showYouTubeVideo(videoKey: youtubeVideoKey, title: video.title)
                } else if let videoURL = video.videoURL {
                    router.showWebVideo(url: videoURL, title: video.title)
                }
            }
            return cell

        case .cast(let people):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EpisodeDetailCastCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? EpisodeDetailCastCollectionViewCell)?.configure(cast: people) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .guestStars(let people):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EpisodeDetailGuestStarsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? EpisodeDetailGuestStarsCollectionViewCell)?.configure(guestStars: people) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .crew(let people):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EpisodeDetailCrewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? EpisodeDetailCrewCollectionViewCell)?.configure(crew: people) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .images(let images):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EpisodeDetailImagesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? EpisodeDetailImagesCollectionViewCell)?.configure(images: images)
            return cell

        case .externalLinks(let links):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EpisodeDetailExternalLinksCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? EpisodeDetailExternalLinksCollectionViewCell)?.configure(items: links) { [weak self] url in
                self?.router.openExternalURL(url)
            }
            return cell

        case .accountState(let accountState):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EpisodeDetailAccountStateCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? EpisodeDetailAccountStateCollectionViewCell)?.configure(items: accountStateRows(from: accountState))
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
                withReuseIdentifier: EpisodeDetailHeroHeaderView.reuseIdentifier,
                for: indexPath
            )

            if let headerView = reusableView as? EpisodeDetailHeroHeaderView {
                headerView.configure(with: item.hero)
            }

            return reusableView
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: EpisodeDetailSectionHeaderView.reuseIdentifier,
            for: indexPath
        )
        (reusableView as? EpisodeDetailSectionHeaderView)?.configure(title: sections[indexPath.section].title)
        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EpisodeDetailViewController: UICollectionViewDelegateFlowLayout {

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
                height: EpisodeDetailHeroHeaderView.headerHeight
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
        for section: EpisodeDetailSectionItem,
        width: CGFloat
    ) -> CGFloat {
        switch section {
        case .overview(let item):
            guard let overview = item.overview else { return 0 }

            return EpisodeDetailOverviewCollectionViewCell.fittingHeight(
                for: overview,
                width: width
            )

        case .facts:
            return Layout.factsSectionHeight

        case .videos, .images:
            return Layout.trailerStyleSectionHeight

        case .cast, .guestStars, .crew:
            return Layout.imageStripSectionHeight

        case .externalLinks(let links):
            return EpisodeDetailExternalLinksCollectionViewCell.fittingHeight(for: links)

        case .accountState(let accountState):
            return max(
                Layout.textSectionMinimumHeight,
                EpisodeDetailAccountStateCollectionViewCell.fittingHeight(
                    for: accountStateRows(from: accountState),
                    width: width
                )
            )
        }
    }
}

// MARK: - Presentation Mapping

private extension EpisodeDetailViewController {

    func accountStateRows(from accountState: EpisodeAccountStateItem) -> [EpisodeDetailTextListItem] {
        [
            EpisodeDetailTextListItem(
                id: "rating",
                title: "你的評分",
                subtitle: accountState.ratingText
            )
        ]
    }

}
