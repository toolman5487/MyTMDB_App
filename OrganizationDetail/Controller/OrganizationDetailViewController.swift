//
//  OrganizationDetailViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import UIKit

@MainActor
final class OrganizationDetailViewController: DetailBaseViewController {

    private enum Layout {
        static let factsHeight: CGFloat = 96
        static let aliasesHeight: CGFloat = 44
        static let logosHeight: CGFloat = 136
        static let linkHeight: CGFloat = 64
    }

    private let organizationID: Int
    private let kind: OrganizationKind
    private let viewModel: OrganizationDetailViewModel
    private lazy var router: DetailRouting = DetailRouter(sourceViewController: self)

    private var sections: [OrganizationDetailSectionItem] = []
    private var loadTask: Task<Void, Never>?

    convenience init(organizationID: Int, kind: OrganizationKind) {
        self.init(
            organizationID: organizationID,
            kind: kind,
            viewModel: OrganizationDetailViewModel()
        )
    }

    init(
        organizationID: Int,
        kind: OrganizationKind,
        viewModel: OrganizationDetailViewModel
    ) {
        self.organizationID = organizationID
        self.kind = kind
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.organizationID = 0
        self.kind = .company
        self.viewModel = OrganizationDetailViewModel()
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
    }

    override var updatesFlowLayoutItemSizeAutomatically: Bool {
        false
    }

    override func configureView() {
        super.configureView()
        configureCollectionView()
    }

    override func bindViewModel() {
        loadDetail()
    }

    override func makeCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self, self.sections.indices.contains(sectionIndex) else {
                return DetailCompositionalLayout.singleItemSection(
                    height: .absolute(1),
                    contentInsets: .zero,
                    header: .none
                )
            }

            let section = self.sections[sectionIndex]
            return DetailCompositionalLayout.singleItemSection(
                height: self.heightDimension(for: section),
                contentInsets: self.contentInsets(for: section),
                header: self.header(for: section)
            )
        }
    }

    private func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = ThemeColor.background

        collectionView.register(
            OrganizationDetailOverviewCollectionViewCell.self,
            forCellWithReuseIdentifier: OrganizationDetailOverviewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            OrganizationDetailFactsCollectionViewCell.self,
            forCellWithReuseIdentifier: OrganizationDetailFactsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            OrganizationDetailAliasesCollectionViewCell.self,
            forCellWithReuseIdentifier: OrganizationDetailAliasesCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            OrganizationDetailLogosCollectionViewCell.self,
            forCellWithReuseIdentifier: OrganizationDetailLogosCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            OrganizationDetailLinkCollectionViewCell.self,
            forCellWithReuseIdentifier: OrganizationDetailLinkCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            OrganizationDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: OrganizationDetailHeroHeaderView.reuseIdentifier
        )
        collectionView.register(
            OrganizationDetailSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: OrganizationDetailSectionHeaderView.reuseIdentifier
        )
    }

    private func loadDetail() {
        loadTask?.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            self.render(state: .loading)
            await self.viewModel.load(
                kind: self.kind,
                id: self.organizationID
            )

            guard !Task.isCancelled else { return }
            self.render(state: self.viewModel.state)
        }
    }

    private func render(state: OrganizationDetailViewState) {
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

        case .loaded(let sections):
            self.sections = sections
            setDetailNavigationTitle(organizationName(in: sections))
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .failed(let message):
            sections = []
            setDetailNavigationTitle(nil)
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadDetail()
            }
        }

        collectionView.reloadData()
    }

    private func heightDimension(
        for section: OrganizationDetailSectionItem
    ) -> NSCollectionLayoutDimension {
        switch section {
        case .hero:
            return .absolute(0)

        case .overview(let text):
            let width = max(
                collectionView.bounds.width - (DetailCompositionalLayout.Metrics.horizontalInset * 2),
                0
            )
            return .absolute(
                OrganizationDetailOverviewCollectionViewCell.fittingHeight(
                    text: text,
                    width: width
                )
            )

        case .facts:
            return .absolute(Layout.factsHeight)

        case .aliases:
            return .absolute(Layout.aliasesHeight)

        case .logos:
            return .absolute(Layout.logosHeight)

        case .homepage:
            return .absolute(Layout.linkHeight)
        }
    }

    private func header(
        for section: OrganizationDetailSectionItem
    ) -> DetailCompositionalLayout.SectionHeader {
        switch section {
        case .hero:
            return .estimatedHero

        default:
            return .sectionTitle
        }
    }

    private func contentInsets(
        for section: OrganizationDetailSectionItem
    ) -> NSDirectionalEdgeInsets {
        switch section {
        case .hero:
            return .zero

        default:
            return DetailCompositionalLayout.contentInsets(
                top: DetailCompositionalLayout.Metrics.headerContentSpacing
            )
        }
    }

    private func organizationName(
        in sections: [OrganizationDetailSectionItem]
    ) -> String? {
        guard case .hero(let item) = sections.first else { return nil }
        return item.name
    }

    private func imageURLs() -> [URL] {
        var urls: [URL] = []
        var seenURLs = Set<URL>()

        for section in sections {
            switch section {
            case .hero(let item):
                if let logoURL = item.logoURL, seenURLs.insert(logoURL).inserted {
                    urls.append(logoURL)
                }

            case .logos(let items):
                for item in items where seenURLs.insert(item.imageURL).inserted {
                    urls.append(item.imageURL)
                }

            case .overview, .facts, .aliases, .homepage:
                break
            }
        }

        return urls
    }

    private func showImagePreview(url: URL) {
        router.showImagePreview(
            imageURLs: imageURLs(),
            selectedImageURL: url,
            title: organizationName(in: sections)
        )
    }
}

extension OrganizationDetailViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if case .hero = sections[section] {
            return 0
        }
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch sections[indexPath.section] {
        case .hero:
            return UICollectionViewCell()

        case .overview(let text):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OrganizationDetailOverviewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? OrganizationDetailOverviewCollectionViewCell)?.configure(text: text)
            return cell

        case .facts(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OrganizationDetailFactsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? OrganizationDetailFactsCollectionViewCell)?.configure(items: items)
            return cell

        case .aliases(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OrganizationDetailAliasesCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? OrganizationDetailAliasesCollectionViewCell)?.configure(items: items)
            return cell

        case .logos(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OrganizationDetailLogosCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? OrganizationDetailLogosCollectionViewCell)?.configure(
                items: items
            ) { [weak self] item in
                self?.showImagePreview(url: item.imageURL)
            }
            return cell

        case .homepage(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OrganizationDetailLinkCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? OrganizationDetailLinkCollectionViewCell)?.configure(
                item: item
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

        if case .hero(let item) = sections[indexPath.section] {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: OrganizationDetailHeroHeaderView.reuseIdentifier,
                for: indexPath
            )
            (header as? OrganizationDetailHeroHeaderView)?.configure(
                item: item
            ) { [weak self] url in
                self?.showImagePreview(url: url)
            }
            return header
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: OrganizationDetailSectionHeaderView.reuseIdentifier,
            for: indexPath
        )
        (header as? OrganizationDetailSectionHeaderView)?.configure(
            title: sections[indexPath.section].title
        )
        return header
    }
}

extension OrganizationDetailViewController: UICollectionViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDetailNavigationTitleVisibility(for: scrollView)
    }
}
