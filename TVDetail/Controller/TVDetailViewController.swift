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
        static let defaultSectionBottomInset: CGFloat = 24
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ThemeColor.background
        collectionViewFlowLayout.minimumLineSpacing = 8
        collectionViewFlowLayout.sectionInset = .zero

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
            sections = loadedSections.filter { section in
                if case .overview = section { return true }
                return false
            }
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
        0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        UICollectionViewCell()
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
            withReuseIdentifier: TVDetailHeroHeaderView.reuseIdentifier,
            for: indexPath
        )

        if case .overview(let item) = sections[indexPath.section],
           let headerView = reusableView as? TVDetailHeroHeaderView {
            headerView.configure(with: item.hero)
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

        return .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        if case .overview = sections[section] {
            return UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: Layout.defaultSectionBottomInset,
                right: 0
            )
        }

        return .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(
            width: collectionView.bounds.width,
            height: 0
        )
    }
}
