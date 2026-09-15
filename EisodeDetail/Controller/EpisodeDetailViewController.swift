//
//  EpisodeDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/8.
//

import Foundation
import UIKit

@MainActor
final class EpisodeDetailViewController: DetailActionBarViewController {

    // MARK: - Properties

    private let viewModel: EpisodeDetailViewModel
    private let sceneBuilder: DetailSceneBuilding
    private lazy var router: DetailRouting = DetailRouter(
        sourceViewController: self,
        sceneBuilder: sceneBuilder
    )

    private var sections: [EpisodeDetailSectionItem] = []

    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        viewModel: EpisodeDetailViewModel,
        sceneBuilder: DetailSceneBuilding
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
        configureActionBar()
        configureCollectionView()
    }

    override func bindViewModel() {
        viewModel.bind(
            onStateChange: { [weak self] state in
                self?.render(state: state)
            },
            onRatingStateChange: { [weak self] state in
                self?.updateRatingAction(with: state)
            }
        )
        loadInitialContent()
    }

    // MARK: - Setup

    private enum Layout {
        static var trailerStyleSectionHeight: CGFloat {
            DetailImageTitleStripMetrics.landscapePreviewSectionHeight
        }

        static var imageStripSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 220,
                imageHeight: 168
            )
        }
        static let textSectionMinimumHeight: CGFloat = 80
    }

    private func configureActionBar() {
        configureDetailActions(
            showsFavorite: false,
            showsRating: true,
            showsReview: false,
            ratingAction: { [weak self] in self?.handleRatingButtonTapped() }
        )
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ThemeColor.background
        collectionViewFlowLayout.minimumLineSpacing = 8

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
        registerDetailSectionHeader()
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitialContent()
        }
    }

    private func render(state: EpisodeDetailViewState) {
        switch state {
        case .idle:
            sections = []
            renderDetailContent(.idle)

        case .loading:
            sections = []
            renderDetailContent(.loading)

        case .loaded(let content):
            sections = content.sections
            renderDetailContent(.loaded(navigationTitle: content.navigationTitle))

        case .failed(let message):
            sections = []
            renderDetailContent(
                .failed(message: message) { [weak self] in self?.loadInitialContent() }
            )
        }

        collectionView.reloadData()
    }

    // MARK: - Actions

    private func handleRatingButtonTapped() {
        if viewModel.ratingState.requiresUserLogin {
            router.showLogin()
            return
        }

        presentRatingSheet()
    }

    private func presentRatingSheet() {
        router.showRatingPageSheet(
            title: "為這集評分",
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
                return await viewModel.submitRating(value: value)
            }
        )
    }

    private func deleteRating() {
        performRatingUpdate(
            pendingValue: nil,
            operation: { [weak self] in
                guard let self else { return nil }
                return await viewModel.deleteRating()
            }
        )
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
            (cell as? EpisodeDetailGuestStarsCollectionViewCell)?.configure(
                guestStars: people
            ) { [weak self] personID in
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
            (cell as? EpisodeDetailImagesCollectionViewCell)?.configure(images: images) { [weak self] image in
                self?.showImagePreview(selectedImage: image)
            }
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
            (cell as? EpisodeDetailAccountStateCollectionViewCell)?.configure(
                items: accountStateRows(from: accountState)
            )
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

        return dequeueDetailSectionHeader(
            at: indexPath,
            title: sections[indexPath.section].title
        )
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
            height: DetailLayoutMetrics.sectionHeaderHeight
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
        let itemWidth = collectionView.bounds.width
        let itemHeight = height(for: sections[indexPath.section], width: itemWidth)

        return CGSize(width: itemWidth, height: itemHeight)
    }

    private func sectionInset(for section: Int) -> UIEdgeInsets {
        if case .overview(let item) = sections[section] {
            return DetailLayoutMetrics.sectionInsets(
                top: item.overview == nil ? 0 : DetailLayoutMetrics.headerContentSpacing
            )
        }

        let topInset = sections[section].title == nil ? 0 : DetailLayoutMetrics.headerContentSpacing

        return DetailLayoutMetrics.sectionInsets(top: topInset)
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
            return DetailLayoutMetrics.factsSectionHeight

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

    func showImagePreview(selectedImage: EpisodeImageItem) {
        guard let selectedImageURL = selectedImage.imageURL else { return }

        router.showImagePreview(
            imageURLs: episodeImageURLs(),
            selectedImageURL: selectedImageURL,
            title: episodeTitle()
        )
    }

    func episodeImageURLs() -> [URL] {
        sections.flatMap { section in
            switch section {
            case .images(let images):
                return images.compactMap(\.imageURL)

            default:
                return []
            }
        }
    }

    func episodeTitle() -> String? {
        guard case .overview(let item) = sections.first else { return nil }
        return item.hero.title
    }
}
