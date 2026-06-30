//
//  MovieDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import UIKit

@MainActor
final class MovieDetailViewController: DetailBaseViewController {

    // MARK: - Properties

    private let movieID: Int
    private let viewModel: MovieDetailViewModel
    private var sections: [MovieDetailSectionItem] = []
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    convenience init(movieID: Int) {
        self.init(
            movieID: movieID,
            viewModel: MovieDetailViewModel()
        )
    }

    init(
        movieID: Int,
        viewModel: MovieDetailViewModel
    ) {
        self.movieID = movieID
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.movieID = 0
        self.viewModel = MovieDetailViewModel()
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        hidesBottomBarWhenPushed = true
        navigationItem.largeTitleDisplayMode = .never
        configureCollectionView()
    }

    override func bindViewModel() {
        loadMovieDetail()
    }

    // MARK: - Setup

    private enum Layout {
        static let headerHeight: CGFloat = 28
        static let headerContentSpacing: CGFloat = 8
        static let factsSectionHeight: CGFloat = 96
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ThemeColor.background
        collectionViewFlowLayout.minimumLineSpacing = 16
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)

        collectionView.register(
            MovieDetailOverviewCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailOverviewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailFactsCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailFactsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailCastCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailCastCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailVideosCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailVideosCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailRecommendationsCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailRecommendationsCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MovieDetailSectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            MovieDetailHeroHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MovieDetailHeroHeaderView.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadMovieDetail() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadMovieDetail(id: movieID)

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func render(state: MovieDetailViewState) {
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
                self?.loadMovieDetail()
            }
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension MovieDetailViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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

        case .overview(let overview):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailOverviewCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailOverviewCollectionViewCell)?.configure(overview: overview)
            return cell

        case .facts(let facts):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailFactsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailFactsCollectionViewCell)?.configure(facts: facts)
            return cell

        case .cast(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailCastCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailCastCollectionViewCell)?.configure(items: items)
            return cell

        case .videos(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailVideosCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailVideosCollectionViewCell)?.configure(items: items)
            return cell

        case .recommendations(let items):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieDetailRecommendationsCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? MovieDetailRecommendationsCollectionViewCell)?.configure(items: items)
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
            let reusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MovieDetailHeroHeaderView.reuseIdentifier,
                for: indexPath
            )

            if let headerView = reusableView as? MovieDetailHeroHeaderView {
                headerView.configure(with: item)
            }

            return reusableView
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MovieDetailSectionHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MovieDetailSectionHeaderView {
            headerView.configure(title: sections[indexPath.section].title)
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MovieDetailViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        if case .hero(let item) = sections[section] {
            return CGSize(
                width: collectionView.bounds.width,
                height: MovieDetailHeroHeaderView.headerHeight(
                    for: item,
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
        if case .hero = sections[section] {
            return UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        }

        let topInset = sections[section].title == nil ? 0 : Layout.headerContentSpacing

        return UIEdgeInsets(top: topInset, left: 16, bottom: 24, right: 16)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width
            - collectionViewFlowLayout.sectionInset.left
            - collectionViewFlowLayout.sectionInset.right

        return CGSize(
            width: max(width, 0),
            height: height(for: sections[indexPath.section])
        )
    }

    private func height(for section: MovieDetailSectionItem) -> CGFloat {
        switch section {
        case .hero:
            return 0

        case .overview:
            return 148

        case .facts:
            return Layout.factsSectionHeight

        case .cast:
            return 168

        case .videos:
            return 148

        case .recommendations:
            return 220
        }
    }

}
