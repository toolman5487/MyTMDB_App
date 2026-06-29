//
//  MainMyAccountViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Observation
import UIKit

@MainActor
final class MainMyAccountViewController: MainBaseViewController {

    // MARK: - Section

    private enum Section: Int, CaseIterable {
        case profile
    }

    private typealias Item = MainMyAccountProfileCell.Content

    // MARK: - Properties

    private let session: AuthSession
    private let viewModel = MainMyAccountViewModel()

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private lazy var dataSource = makeDataSource()

    override var pageTitle: String {
        session.isGuest ? "訪客中心" : "個人中心"
    }

    // MARK: - Initializer

    init(session: AuthSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.session = .guest(sessionId: "")
        super.init(coder: coder)
    }

    // MARK: - Template Methods

    override func configureCollectionView() {
        super.configureCollectionView()
        collectionView.register(
            MainMyAccountProfileCell.self,
            forCellWithReuseIdentifier: MainMyAccountProfileCell.reuseIdentifier
        )
    }

    override func bindViewModel() {
        super.bindViewModel()
        observeViewModel()
        applySnapshot(for: viewModel.state)
    }

    override func pageDidBecomeVisible() {
        super.pageDidBecomeVisible()
        loadProfile(force: false)
    }

    override func tabDidReselect() {
        super.tabDidReselect()
        loadProfile(force: true)
    }

    override func makeCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else {
                return nil
            }

            switch section {
            case .profile:
                return self.makeProfileSectionLayout()
            }
        }
    }

    // MARK: - Private Methods

    private func loadProfile(force: Bool) {
        Task(priority: .userInitiated) {
            await viewModel.loadProfile(for: session, force: force)
        }
    }

    private func observeViewModel() {
        withObservationTracking {
            _ = viewModel.state
        } onChange: { [weak self] in
            Task(priority: .userInitiated) { @MainActor in
                guard let self else { return }
                self.handleState(self.viewModel.state)
                self.observeViewModel()
            }
        }
    }

    private func handleState(_ state: MainMyAccountState) {
        switch state {
        case .idle, .loading, .guest, .loaded, .failed:
            setLoadingVisible(false)
        }

        applySnapshot(for: state)
    }

    private func applySnapshot(for state: MainMyAccountState) {
        var snapshot = Snapshot()
        snapshot.appendSections([.profile])

        switch state {
        case .idle:
            break

        case .loading:
            snapshot.appendItems([.skeleton], toSection: .profile)

        case .guest:
            snapshot.appendItems([.guest], toSection: .profile)

        case .loaded(let profile):
            snapshot.appendItems([.profile(MainMyAccountProfileItem(profile: profile))], toSection: .profile)

        case .failed(let message):
            snapshot.appendItems([.message(message)], toSection: .profile)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func makeDataSource() -> DataSource {
        DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainMyAccountProfileCell.reuseIdentifier,
                for: indexPath
            ) as? MainMyAccountProfileCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: item)

            return cell
        }
    }

    private func makeProfileSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(MainMyAccountProfileCell.height)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(MainMyAccountProfileCell.height)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        return section
    }
}
