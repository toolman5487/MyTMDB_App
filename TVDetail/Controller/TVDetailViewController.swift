//
//  TVDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import UIKit

@MainActor
final class TVDetailViewController: DetailBaseViewController {

    // MARK: - Properties

    private let seriesID: Int
    private let viewModel: TVDetailViewModel
    private var sections: [TVDetailSectionItem] = []
    private var loadTask: Task<Void, Never>?

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
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.largeTitleDisplayMode = .never
        configureCollectionView()
    }

    override func bindViewModel() {
        loadTVDetail()
    }

    // MARK: - Setup

    private enum Layout {
        static let headerHeight: CGFloat = 28
        static let headerContentSpacing: CGFloat = 8
        static let defaultHorizontalInset: CGFloat = 16
        static let defaultSectionBottomInset: CGFloat = 24
        static let factsSectionHeight: CGFloat = 96
        static let attributesSectionHeight: CGFloat = 132
        static let castSectionHeight: CGFloat = 220
        static let videosSectionHeight: CGFloat = 148
        static let seasonsSectionHeight: CGFloat = 220
        static let recommendationsSectionHeight: CGFloat = 220
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ThemeColor.background
        collectionViewFlowLayout.minimumLineSpacing = 8
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

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

    // MARK: - Data Loading

    private func loadTVDetail() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadTVDetail(seriesID: seriesID)

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func render(state: TVDetailViewState) {
        switch state {
        case .idle:
            sections = []
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .loading:
            sections = []
            setLoadingVisible(true)
            collectionView.backgroundView = nil

        case .loaded(let loadedSections):
            sections = loadedSections
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .failed(let message):
            sections = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadTVDetail()
            }
        }

        collectionView.reloadData()
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
            (cell as? TVDetailVideosCollectionViewCell)?.configure(items: items)
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
            (cell as? TVDetailCastCollectionViewCell)?.configure(items: items)
            return cell

        case .seasons(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailSeasonsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailSeasonsCollectionViewCell)?.configure(items: items)
            return cell

        case .recommendations(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TVDetailRecommendationsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? TVDetailRecommendationsCollectionViewCell)?.configure(items: items)
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
            headerView.configure(title: sections[indexPath.section].title)
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TVDetailViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        if case .overview(let item) = sections[section] {
            return CGSize(
                width: collectionView.bounds.width,
                height: TVDetailHeroHeaderView.headerHeight(
                    for: item.hero,
                    width: collectionView.bounds.width
                )
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

        return CGSize(
            width: max(width, 0),
            height: height(for: sections[indexPath.section], width: max(width, 0))
        )
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

    private func height(for section: TVDetailSectionItem, width: CGFloat) -> CGFloat {
        switch section {
        case .overview(let item):
            guard let overview = item.overview else { return 0 }

            return TVDetailOverviewCollectionViewCell.fittingHeight(
                for: overview,
                width: width
            )

        case .facts:
            return Layout.factsSectionHeight

        case .videos:
            return Layout.videosSectionHeight

        case .attributes:
            return Layout.attributesSectionHeight

        case .cast:
            return Layout.castSectionHeight

        case .seasons:
            return Layout.seasonsSectionHeight

        case .recommendations:
            return Layout.recommendationsSectionHeight
        }
    }
}
