//
//  CompanyDetailViewController.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import UIKit

@MainActor
final class CompanyDetailViewController: DetailBaseViewController {

    // MARK: - Properties

    private let companyID: Int
    private let viewModel: CompanyDetailViewModel
    private let sceneBuilder: DetailSceneBuilding
    private lazy var router: DetailRouting = DetailRouter(
        sourceViewController: self,
        sceneBuilder: sceneBuilder,
        interfaceLocalization: interfaceLocalization
    )

    private var sections: [CompanyDetailSectionItem] = []

    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        companyID: Int,
        viewModel: CompanyDetailViewModel,
        sceneBuilder: DetailSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.companyID = companyID
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
        navigationItem.largeTitleDisplayMode = .never
        configureCollectionView()
    }

    override func bindViewModel() {
        viewModel.bind { [weak self] state in
            self?.render(state: state)
        }
        loadInitialContent()
    }

    // MARK: - Setup

    private enum Layout {
        static var mediaStripSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 220,
                imageHeight: 168
            )
        }

        static var logosSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 220,
                imageHeight: 168
            )
        }
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ThemeColor.background
        collectionViewFlowLayout.minimumLineSpacing = 8

        collectionView.register(
            CompanyDetailDescriptionCollectionViewCell.self,
            forCellWithReuseIdentifier: CompanyDetailDescriptionCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            CompanyDetailFactsCollectionViewCell.self,
            forCellWithReuseIdentifier: CompanyDetailFactsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            CompanyDetailMoviesCollectionViewCell.self,
            forCellWithReuseIdentifier: CompanyDetailMoviesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            CompanyDetailTVShowsCollectionViewCell.self,
            forCellWithReuseIdentifier: CompanyDetailTVShowsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            CompanyDetailLogosCollectionViewCell.self,
            forCellWithReuseIdentifier: CompanyDetailLogosCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            CompanyDetailAlternativeNamesCollectionViewCell.self,
            forCellWithReuseIdentifier: CompanyDetailAlternativeNamesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            CompanyDetailExternalLinksCollectionViewCell.self,
            forCellWithReuseIdentifier: CompanyDetailExternalLinksCollectionViewCell.reuseIdentifier
        )
        registerDetailSectionHeader()
        collectionView.register(
            CompanyDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CompanyDetailHeroHeaderView.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitialContent(companyID: companyID)
        }
    }

    private func render(state: CompanyDetailViewState) {
        switch state {
        case .idle:
            sections = []
            renderDetailContent(.idle)

        case .loading:
            sections = []
            renderDetailContent(.loading)

        case .loaded(let loadedSections):
            sections = loadedSections
            renderDetailContent(
                .loaded(navigationTitle: detailNavigationTitle(from: loadedSections))
            )

        case .failed(let message):
            sections = []
            renderDetailContent(
                .failed(message: message) { [weak self] in self?.loadInitialContent() }
            )
        }

        collectionView.reloadData()
    }

    private func detailNavigationTitle(from sections: [CompanyDetailSectionItem]) -> String? {
        guard case .header(let item) = sections.first else { return nil }
        return item.hero.name
    }
}

// MARK: - UICollectionViewDataSource

extension CompanyDetailViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if case .header(let item) = sections[section] {
            return item.description == nil ? 0 : 1
        }

        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch sections[indexPath.section] {
        case .header(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CompanyDetailDescriptionCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? CompanyDetailDescriptionCollectionViewCell)?.configure(
                description: item.description ?? "",
                localization: interfaceLocalization
            )
            return cell

        case .facts(let facts):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CompanyDetailFactsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? CompanyDetailFactsCollectionViewCell)?.configure(facts: facts)
            return cell

        case .movies(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CompanyDetailMoviesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? CompanyDetailMoviesCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            ) { [weak self] item in
                self?.router.showMediaDetail(kind: item.mediaKind, id: item.sourceID)
            }
            return cell

        case .tvShows(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CompanyDetailTVShowsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? CompanyDetailTVShowsCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            ) { [weak self] item in
                self?.router.showMediaDetail(kind: item.mediaKind, id: item.sourceID)
            }
            return cell

        case .logos(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CompanyDetailLogosCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? CompanyDetailLogosCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            ) { [weak self] imageURL in
                self?.showImagePreview(selectedImageURL: imageURL)
            }
            return cell

        case .alternativeNames(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CompanyDetailAlternativeNamesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? CompanyDetailAlternativeNamesCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            )
            return cell

        case .externalLinks(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CompanyDetailExternalLinksCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? CompanyDetailExternalLinksCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            ) { [weak self] url in
                self?.router.openExternalURL(url)
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

        if case .header(let item) = sections[indexPath.section] {
            let reusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: CompanyDetailHeroHeaderView.reuseIdentifier,
                for: indexPath
            )

            if let headerView = reusableView as? CompanyDetailHeroHeaderView {
                headerView.configure(
                    with: item.hero,
                    localization: interfaceLocalization
                )
            }

            return reusableView
        }

        let section = sections[indexPath.section]
        let onTap: (() -> Void)?

        if let mediaKind = section.mediaKindForContentList {
            onTap = { [weak self] in
                self?.showContentList(for: mediaKind)
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

    private func showContentList(for mediaKind: MediaKind) {
        guard let result = viewModel.contentList(companyID: companyID, mediaKind: mediaKind) else { return }
        router.showContentList(result.configuration, pageProvider: result.pageProvider)
    }

    private func showImagePreview(selectedImageURL: URL) {
        router.showImagePreview(
            imageURLs: companyLogoURLs(),
            selectedImageURL: selectedImageURL,
            title: companyName()
        )
    }

    private func companyName() -> String? {
        guard case .header(let item) = sections.first else { return nil }
        return item.hero.name
    }

    private func companyLogoURLs() -> [URL] {
        for section in sections {
            if case .logos(let items) = section {
                return items.compactMap(\.imageURL)
            }
        }

        return []
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CompanyDetailViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDetailNavigationTitleVisibility(for: scrollView)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        if case .header = sections[section] {
            return CGSize(
                width: collectionView.bounds.width,
                height: CompanyDetailHeroHeaderView.headerHeight()
            )
        }

        guard sections[section].title(localization: interfaceLocalization) != nil else {
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
        let width = collectionView.bounds.width

        return CGSize(
            width: width,
            height: height(for: sections[indexPath.section], width: width)
        )
    }

    private func sectionInset(for section: Int) -> UIEdgeInsets {
        if case .header(let item) = sections[section] {
            return DetailLayoutMetrics.sectionInsets(
                top: item.description == nil ? 0 : DetailLayoutMetrics.headerContentSpacing
            )
        }

        let topInset = sections[section].title(localization: interfaceLocalization) == nil
            ? 0
            : DetailLayoutMetrics.headerContentSpacing

        return DetailLayoutMetrics.sectionInsets(top: topInset)
    }

    private func height(for section: CompanyDetailSectionItem, width: CGFloat) -> CGFloat {
        switch section {
        case .header(let item):
            guard let description = item.description else { return 0 }

            return CompanyDetailDescriptionCollectionViewCell.fittingHeight(
                for: description,
                width: width,
                localization: interfaceLocalization
            )

        case .facts:
            return DetailLayoutMetrics.factsSectionHeight

        case .movies, .tvShows:
            return Layout.mediaStripSectionHeight

        case .logos:
            return Layout.logosSectionHeight

        case .alternativeNames(let items):
            return CompanyDetailAlternativeNamesCollectionViewCell.fittingHeight(for: items)

        case .externalLinks(let items):
            return CompanyDetailExternalLinksCollectionViewCell.fittingHeight(for: items)
        }
    }
}
