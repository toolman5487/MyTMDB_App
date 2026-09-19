//
//  PersonDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import UIKit

@MainActor
final class PersonDetailViewController: DetailBaseViewController {

    // MARK: - Properties

    private let personID: Int
    private let viewModel: PersonDetailViewModel
    private let sceneBuilder: DetailSceneBuilding
    private lazy var router: DetailRouting = DetailRouter(
        sourceViewController: self,
        sceneBuilder: sceneBuilder,
        interfaceLocalization: interfaceLocalization
    )

    private var sections: [PersonDetailSectionItem] = []

    private var loadTask: Task<Void, Never>?
    private var creditsListTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        personID: Int,
        viewModel: PersonDetailViewModel,
        sceneBuilder: DetailSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.personID = personID
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
        creditsListTask?.cancel()
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
        static var creditsSectionHeight: CGFloat {
            DetailImageTitleStripCollectionViewCell.fittingHeight(
                minimumHeight: 220,
                imageHeight: 168
            )
        }

        static var profileImagesSectionHeight: CGFloat {
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
            PersonDetailBiographyCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailBiographyCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            PersonDetailFactsCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailFactsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            PersonDetailMovieCreditsCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailMovieCreditsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            PersonDetailTVCreditsCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailTVCreditsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            PersonDetailProfileImagesCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailProfileImagesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            PersonDetailAliasesCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailAliasesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            PersonDetailExternalLinksCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailExternalLinksCollectionViewCell.reuseIdentifier
        )
        registerDetailSectionHeader()
        collectionView.register(
            PersonDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PersonDetailHeroHeaderView.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitialContent(personID: personID)
        }
    }

    private func loadCreditsList(mediaType: PersonCreditMediaType) {
        creditsListTask?.cancel()
        creditsListTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            setLoadingVisible(true)
            let result = await viewModel.loadCreditsList(
                personID: personID,
                mediaType: mediaType
            )
            setLoadingVisible(false)

            guard !Task.isCancelled else { return }

            switch result {
            case .loaded(let configuration):
                router.showContentList(configuration)

            case .failed(let message):
                presentAlert(title: message.title, message: message.message)
            }
        }
    }

    private func render(state: PersonDetailViewState) {
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

    private func detailNavigationTitle(from sections: [PersonDetailSectionItem]) -> String? {
        guard case .biography(let item) = sections.first else { return nil }
        return item.hero.name
    }
}

// MARK: - UICollectionViewDataSource

extension PersonDetailViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if case .biography(let item) = sections[section] {
            return item.biography == nil ? 0 : 1
        }

        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch sections[indexPath.section] {
        case .biography(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonDetailBiographyCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? PersonDetailBiographyCollectionViewCell)?.configure(
                biography: item.biography ?? "",
                localization: interfaceLocalization
            )
            return cell

        case .facts(let facts):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonDetailFactsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? PersonDetailFactsCollectionViewCell)?.configure(facts: facts)
            return cell

        case .movieCredits(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonDetailMovieCreditsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? PersonDetailMovieCreditsCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            ) { [weak self] item in
                guard let kind = item.mediaKind else { return }
                self?.router.showMediaDetail(kind: kind, id: item.sourceID)
            }
            return cell

        case .tvCredits(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonDetailTVCreditsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? PersonDetailTVCreditsCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            ) { [weak self] item in
                guard let kind = item.mediaKind else { return }
                self?.router.showMediaDetail(kind: kind, id: item.sourceID)
            }
            return cell

        case .profileImages(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonDetailProfileImagesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? PersonDetailProfileImagesCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            ) { [weak self] imageURL in
                self?.showImagePreview(selectedImageURL: imageURL)
            }
            return cell

        case .aliases(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonDetailAliasesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? PersonDetailAliasesCollectionViewCell)?.configure(
                items: items,
                localization: interfaceLocalization
            )
            return cell

        case .externalLinks(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PersonDetailExternalLinksCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? PersonDetailExternalLinksCollectionViewCell)?.configure(
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

        if case .biography(let item) = sections[indexPath.section] {
            let reusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PersonDetailHeroHeaderView.reuseIdentifier,
                for: indexPath
            )

            if let headerView = reusableView as? PersonDetailHeroHeaderView {
                headerView.configure(
                    with: item.hero,
                    localization: interfaceLocalization
                ) { [weak self] imageURL in
                    self?.showImagePreview(selectedImageURL: imageURL)
                }
            }

            return reusableView
        }

        let section = sections[indexPath.section]
        let onTap: (() -> Void)?

        if let mediaType = section.creditsMediaType {
            onTap = { [weak self] in
                guard let self else { return }
                self.loadCreditsList(mediaType: mediaType)
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

    private func showImagePreview(selectedImageURL: URL) {
        router.showImagePreview(
            imageURLs: personImageURLs(),
            selectedImageURL: selectedImageURL,
            title: personName()
        )
    }

    private func personName() -> String? {
        guard case .biography(let item) = sections.first else { return nil }
        return item.hero.name
    }

    private func personImageURLs() -> [URL] {
        var imageURLs: [URL] = []

        sections.forEach { section in
            switch section {
            case .biography(let item):
                if let profileURL = item.hero.profileURL {
                    imageURLs.append(profileURL)
                }

            case .profileImages(let items):
                imageURLs.append(contentsOf: items.compactMap(\.imageURL))

            case .facts, .movieCredits, .tvCredits, .aliases, .externalLinks:
                break
            }
        }

        return imageURLs
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PersonDetailViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDetailNavigationTitleVisibility(for: scrollView)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        if case .biography = sections[section] {
            return CGSize(
                width: collectionView.bounds.width,
                height: PersonDetailHeroHeaderView.headerHeight()
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
        if case .biography(let item) = sections[section] {
            return DetailLayoutMetrics.sectionInsets(
                top: item.biography == nil ? 0 : DetailLayoutMetrics.headerContentSpacing
            )
        }

        let topInset = sections[section].title(localization: interfaceLocalization) == nil
            ? 0
            : DetailLayoutMetrics.headerContentSpacing

        return DetailLayoutMetrics.sectionInsets(top: topInset)
    }

    private func height(for section: PersonDetailSectionItem, width: CGFloat) -> CGFloat {
        switch section {
        case .biography(let item):
            guard let biography = item.biography else { return 0 }

            return PersonDetailBiographyCollectionViewCell.fittingHeight(
                for: biography,
                width: width,
                localization: interfaceLocalization
            )

        case .facts:
            return DetailLayoutMetrics.factsSectionHeight

        case .movieCredits, .tvCredits:
            return Layout.creditsSectionHeight

        case .profileImages:
            return Layout.profileImagesSectionHeight

        case .aliases(let items):
            return PersonDetailAliasesCollectionViewCell.fittingHeight(for: items)

        case .externalLinks(let items):
            return PersonDetailExternalLinksCollectionViewCell.fittingHeight(for: items)
        }
    }
}
