//
//  MainHomeViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import UIKit

@MainActor
final class MainHomeViewController: MainBaseViewController {

    // MARK: - Constants

    private enum CellIdentifier {
        static let content = String(describing: MainHomeContentCollectionViewCell.self)
    }

    private enum Layout {
        static let headerHeight: CGFloat = 32
        static let itemHeight: CGFloat = 232
        static let headerContentSpacing: CGFloat = 8
        static let sectionBottomSpacing: CGFloat = 16
    }

    // MARK: - Properties

    private let viewModel: MainHomeViewModel
    private var sections: [MainHomeSectionItem] = []
    private var loadTask: Task<Void, Never>?

    override var collectionViewItemHeight: CGFloat {
        Layout.itemHeight
    }

    // MARK: - Initialization

    init() {
        self.viewModel = MainHomeViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    init(viewModel: MainHomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MainHomeViewModel()
        super.init(coder: coder)
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        configureCollectionView()
    }

    override func bindViewModel() {
        loadHome()
    }

    // MARK: - Setup

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionViewFlowLayout.minimumLineSpacing = 0
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(
            top: Layout.headerContentSpacing,
            left: 0,
            bottom: Layout.sectionBottomSpacing,
            right: 0
        )
        collectionView.register(
            MainHomeContentCollectionViewCell.self,
            forCellWithReuseIdentifier: CellIdentifier.content
        )
        collectionView.register(
            MainHomeSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadHome() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadHome()

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func render(state: MainHomeViewState) {
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

        case .empty:
            sections = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: .emptyContent)

        case .failed(let message):
            sections = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadHome()
            }
        }

        collectionView.reloadData()
    }

    // MARK: - Navigation

    private func showDetail(for item: MainHomeContentItem, in section: MainHomeSectionItem) {
        guard section.category.mediaType == .movie else { return }

        let detailViewController = MovieDetailViewController(movieID: item.id)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CellIdentifier.content,
            for: indexPath
        )

        if let cell = cell as? MainHomeContentCollectionViewCell {
            let section = sections[indexPath.section]
            cell.configure(contents: section.contents)
            cell.onContentSelected = { [weak self] item in
                self?.showDetail(for: item, in: section)
            }
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MainHomeSectionHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MainHomeSectionHeaderView {
            headerView.configure(title: sections[indexPath.section].title)
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegate

extension MainHomeViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(
            width: collectionView.bounds.width,
            height: collectionViewItemHeight
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(
            width: collectionView.bounds.width,
            height: Layout.headerHeight
        )
    }
}
