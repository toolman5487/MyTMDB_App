//
//  TVDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import SnapKit
import UIKit

@MainActor
final class TVDetailViewController: DetailBaseViewController {

    // MARK: - Properties

    private let seriesID: Int
    private let viewModel: TVDetailViewModel
    private var sections: [TVDetailSectionItem] = []
    private var loadTask: Task<Void, Never>?
    private var favoriteTask: Task<Void, Never>?
    private var ratingTask: Task<Void, Never>?
    private lazy var router: TVDetailRouting = TVDetailRouter(
        sourceViewController: self,
        seriesID: seriesID
    )
    private let bottomActionBarView = DetailBottomActionBarView()

    // MARK: - Initialization

    convenience init(seriesID: Int) {
        self.init(
            seriesID: seriesID,
            viewModel: TVDetailViewModel()
        )
    }

    init(
        seriesID: Int,
        viewModel: TVDetailViewModel
    ) {
        self.seriesID = seriesID
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.seriesID = 0
        self.viewModel = TVDetailViewModel()
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
        favoriteTask?.cancel()
        ratingTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.largeTitleDisplayMode = .never
        configureActionBar()
        configureCollectionView()
    }

    override func bindViewModel() {
        loadTVDetail()
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
        static let videosSectionHeight: CGFloat = 148
        static let seasonsSectionHeight: CGFloat = 220
        static let imagesSectionHeight: CGFloat = 168
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
        bottomActionBarView.configureRating(value: nil, isEnabled: false)
        bottomActionBarView.setFavoriteAction(target: self, action: #selector(handleBottomFavoriteButtonTapped))
        bottomActionBarView.setRatingAction(target: self, action: #selector(handleRatingButtonTapped))
        bottomActionBarView.setReviewAction(target: self, action: #selector(handleReviewButtonTapped))
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
            TVDetailSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TVDetailSectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            TVDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TVDetailHeroHeaderView.reuseIdentifier
        )
    }

    private func makeLayoutSection(for section: TVDetailSectionItem) -> NSCollectionLayoutSection {
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

    private func sectionHeader(for section: TVDetailSectionItem) -> DetailCompositionalLayout.SectionHeader {
        switch section {
        case .overview:
            return .estimatedHero

        default:
            return section.title == nil ? .none : .sectionTitle
        }
    }

    private func sectionContentInsets(for section: TVDetailSectionItem) -> NSDirectionalEdgeInsets {
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
                    width: width
                )
            )

        case .facts:
            return .absolute(Layout.factsSectionHeight)

        case .videos:
            return .absolute(Layout.videosSectionHeight)

        case .attributes(let item):
            return .absolute(TVDetailAttributesCollectionViewCell.fittingHeight(for: item))

        case .cast:
            return .absolute(Layout.castSectionHeight)

        case .seasons:
            return .absolute(Layout.seasonsSectionHeight)

        case .images:
            return .absolute(Layout.imagesSectionHeight)

        case .recommendations, .similar:
            return .absolute(Layout.recommendationsSectionHeight)
        }
    }

    // MARK: - Data Loading

    private func loadTVDetail() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadTVDetail(seriesID: seriesID)

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
            updateFavoriteButton()
            updateRatingButton()
        }
    }

    private func render(state: TVDetailViewState) {
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
                self?.loadTVDetail()
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

    @objc private func handleRatingButtonTapped() {
        if shouldNavigateToLoginForRating() {
            router.showLogin()
            return
        }

        presentRatingSheet()
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

            let message = await viewModel.toggleFavorite(seriesID: seriesID)

            guard !Task.isCancelled else { return }
            updateFavoriteButton()

            if let message {
                presentAlert(title: message.title, message: message.message, actionTitle: message.actionTitle ?? "OK")
            }
        }
    }

    private func presentRatingSheet() {
        router.showRatingPageSheet(
            title: "為這部影集評分",
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
        bottomActionBarView.configureRating(value: value, isEnabled: false)
        ratingTask?.cancel()
        ratingTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let message = await viewModel.submitRating(seriesID: seriesID, value: value)

            guard !Task.isCancelled else { return }
            updateRatingButton()

            if let message {
                presentAlert(title: message.title, message: message.message, actionTitle: message.actionTitle ?? "OK")
            }
        }
    }

    private func deleteRating() {
        bottomActionBarView.configureRating(value: nil, isEnabled: false)
        ratingTask?.cancel()
        ratingTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let message = await viewModel.deleteRating(seriesID: seriesID)

            guard !Task.isCancelled else { return }
            updateRatingButton()

            if let message {
                presentAlert(title: message.title, message: message.message, actionTitle: message.actionTitle ?? "OK")
            }
        }
    }

    private func detailNavigationTitle(from sections: [TVDetailSectionItem]) -> String? {
        guard case .overview(let item) = sections.first else { return nil }
        return item.hero.title.isEmpty ? item.hero.originalTitle : item.hero.title
    }

    private func updateFavoriteButton() {
        bottomActionBarView.configureFavorite(
            isFavorite: viewModel.favoriteState.isFavorite,
            isEnabled: viewModel.favoriteState.isButtonEnabled
        )
    }

    private func updateRatingButton() {
        bottomActionBarView.configureRating(
            value: viewModel.ratingState.value,
            isEnabled: viewModel.ratingState.isButtonEnabled
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

    private func shouldNavigateToLoginForRating() -> Bool {
        if case .requiresUserLogin = viewModel.ratingState {
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
            (cell as? TVDetailOverviewCollectionViewCell)?.configure(overview: item.overview ?? "")
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

        case .attributes(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailAttributesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailAttributesCollectionViewCell)?.configure(with: item)
            return cell

        case .cast(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailCastCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailCastCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            ) { [weak self] personID in
                self?.router.showPersonDetail(personID: personID)
            }
            return cell

        case .seasons(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailSeasonsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailSeasonsCollectionViewCell)?.configure(items: items) { [weak self] seasonNumber in
                self?.router.showSeasonDetail(seasonNumber: seasonNumber)
            }
            return cell

        case .images(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailImagesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            let previewItems = Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            (cell as? TVDetailImagesCollectionViewCell)?.configure(
                items: previewItems
            ) { [weak self] imageItem in
                self?.router.showImagePreview(
                    imageURLs: items.map(\.imageURL),
                    selectedImageURL: imageItem.imageURL,
                    title: "劇照"
                )
            }
            return cell

        case .recommendations(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailRecommendationsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailRecommendationsCollectionViewCell)?.configure(
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount))
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
                items: Array(items.prefix(DetailSectionPreviewLimit.itemCount))
            ) { [weak self] seriesID in
                self?.router.showTVDetail(seriesID: seriesID)
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

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TVDetailSectionHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? TVDetailSectionHeaderView {
            let section = sections[indexPath.section]
            let onTap: (() -> Void)?
            if let configuration = section.contentListConfiguration {
                onTap = { [weak self] in
                    self?.router.showContentList(configuration)
                }
            } else {
                onTap = nil
            }
            headerView.configure(title: section.title, onTap: onTap)
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegate

extension TVDetailViewController: UICollectionViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDetailNavigationTitleVisibility(for: scrollView)
    }
}
