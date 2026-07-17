//
//  MemberSettingViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/13.
//

import SDWebImage
import UIKit

@MainActor
final class MemberSettingViewController: BaseListViewController {

    // MARK: - Constants

    private enum Layout {
        static let profileItemHeight: CGFloat = 88
        static let itemHeight: CGFloat = 56
        static let minimumLineSpacing: CGFloat = 4
        static let sectionHeaderHeight: CGFloat = 32
        static let sectionHorizontalInset: CGFloat = 16
        static let sectionBottomInset: CGFloat = 24
    }

    // MARK: - Properties

    private let viewModel: MemberSettingViewModel
    private lazy var router: MemberSettingRouting = MemberSettingRouter(sourceViewController: self)
    private var profileRefreshTask: Task<Void, Never>?

    override var collectionViewItemHeight: CGFloat {
        Layout.itemHeight
    }

    // MARK: - Initialization

    init(viewModel: MemberSettingViewModel = MemberSettingViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MemberSettingViewModel()
        super.init(coder: coder)
    }

    deinit {
        profileRefreshTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.title = "設定"
        view.backgroundColor = .systemGroupedBackground
        configureCollectionView()
    }

    // MARK: - Setup

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionViewFlowLayout.minimumLineSpacing = Layout.minimumLineSpacing
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        registerCells()
        collectionView.register(
            MemberSettingSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MemberSettingSectionHeaderView.reuseIdentifier
        )
    }

    private func registerCells() {
        collectionView.register(
            MemberSettingProfileSummaryCollectionViewCell.self,
            forCellWithReuseIdentifier: MemberSettingProfileSummaryCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MemberSettingRefreshProfileCollectionViewCell.self,
            forCellWithReuseIdentifier: MemberSettingRefreshProfileCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MemberSettingDefaultCollectionViewCell.self,
            forCellWithReuseIdentifier: MemberSettingDefaultCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MemberSettingClearProfileCacheCollectionViewCell.self,
            forCellWithReuseIdentifier: MemberSettingClearProfileCacheCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MemberSettingAppVersionCollectionViewCell.self,
            forCellWithReuseIdentifier: MemberSettingAppVersionCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MemberSettingTMDBAttributionCollectionViewCell.self,
            forCellWithReuseIdentifier: MemberSettingTMDBAttributionCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MemberSettingLogoutButtonCollectionViewCell.self,
            forCellWithReuseIdentifier: MemberSettingLogoutButtonCollectionViewCell.reuseIdentifier
        )
    }

    // MARK: - Actions

    private func refreshProfile() {
        profileRefreshTask?.cancel()
        profileRefreshTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await viewModel.refreshProfile()
                collectionView.reloadData()
                router.showProfileRefreshCompleted()
            } catch {
                router.showProfileRefreshFailed()
            }
        }
    }

    private func presentClearProfileCacheConfirmation() {
        router.showClearProfileCacheConfirmation { [weak self] in
            self?.clearProfileCache()
        }
    }

    private func clearProfileCache() {
        viewModel.clearProfileCache()
        collectionView.reloadData()
        router.showProfileCacheCleared()
    }

    private func presentClearImageCacheConfirmation() {
        router.showClearImageCacheConfirmation { [weak self] in
            self?.clearImageCache()
        }
    }

    private func clearImageCache() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk { [weak self] in
            Task { @MainActor in
                self?.router.showImageCacheCleared()
            }
        }
    }

    private func presentClearAllLocalDataConfirmation() {
        router.showClearAllLocalDataConfirmation { [weak self] in
            self?.clearAllLocalData()
        }
    }

    private func clearAllLocalData() {
        viewModel.clearAllLocalData()
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk { [weak self] in
            Task { @MainActor in
                self?.router.showLoggedOut()
            }
        }
    }

    private func openTMDBAttribution() {
        guard let url = viewModel.tmdbAttributionURL else { return }
        router.openTMDBAttribution(url)
    }

    private func presentLogoutConfirmation() {
        router.showLogoutConfirmation { [weak self] in
            self?.logout()
        }
    }

    private func logout() {
        viewModel.logout()
        router.showLoggedOut()
    }
}

// MARK: - UICollectionViewDataSource

extension MemberSettingViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.section(at: section)?.rows.count ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let section = viewModel.section(at: indexPath.section),
              let row = viewModel.row(at: indexPath) else {
            return UICollectionViewCell()
        }

        let cell = dequeueCell(for: row, at: indexPath)
        if let profileCell = cell as? MemberSettingProfileSummaryCollectionViewCell {
            profileCell.configure(with: viewModel.profileSummary)
            return profileCell
        }

        guard let settingCell = cell as? MemberSettingButtonCollectionViewCell else { return cell }

        configure(
            settingCell,
            with: row,
            section: section,
            indexPath: indexPath
        )
        return settingCell
    }

    private func dequeueCell(for row: MemberSettingRowItem, at indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier: String

        switch row.kind {
        case .profileSummary:
            reuseIdentifier = MemberSettingProfileSummaryCollectionViewCell.reuseIdentifier

        case .accountId,
             .clearImageCache,
             .clearSearchHistory,
             .clearAllLocalData,
             .apiDataLanguage,
             .loginStatus,
             .defaultSort,
             .defaultContentType:
            reuseIdentifier = MemberSettingDefaultCollectionViewCell.reuseIdentifier

        case .refreshProfile:
            reuseIdentifier = MemberSettingRefreshProfileCollectionViewCell.reuseIdentifier

        case .clearProfileCache:
            reuseIdentifier = MemberSettingClearProfileCacheCollectionViewCell.reuseIdentifier

        case .appVersion:
            reuseIdentifier = MemberSettingAppVersionCollectionViewCell.reuseIdentifier

        case .tmdbAttribution:
            reuseIdentifier = MemberSettingTMDBAttributionCollectionViewCell.reuseIdentifier

        case .logout:
            reuseIdentifier = MemberSettingLogoutButtonCollectionViewCell.reuseIdentifier
        }

        return collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        )
    }

    private func configure(
        _ cell: MemberSettingButtonCollectionViewCell,
        with row: MemberSettingRowItem,
        section: MemberSettingSectionItem,
        indexPath: IndexPath
    ) {
        cell.configure(
            with: row,
            isFirstInSection: indexPath.item == 0,
            isLastInSection: indexPath.item == section.rows.count - 1
        )
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
            withReuseIdentifier: MemberSettingSectionHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MemberSettingSectionHeaderView {
            headerView.configure(title: viewModel.section(at: indexPath.section)?.title)
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MemberSettingViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let height = viewModel.row(at: indexPath)?.kind == .profileSummary
            ? Layout.profileItemHeight
            : Layout.itemHeight

        return CGSize(
            width: collectionView.bounds.width - Layout.sectionHorizontalInset * 2,
            height: height
        )
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        viewModel.action(at: indexPath) != nil
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        switch viewModel.action(at: indexPath) {
        case .refreshProfile:
            refreshProfile()

        case .clearProfileCache:
            presentClearProfileCacheConfirmation()

        case .clearImageCache:
            presentClearImageCacheConfirmation()

        case .clearAllLocalData:
            presentClearAllLocalDataConfirmation()

        case .tmdbAttribution:
            openTMDBAttribution()

        case .logout:
            presentLogoutConfirmation()

        case nil:
            return
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        guard viewModel.section(at: section)?.title.isEmpty == false else {
            return .zero
        }

        return CGSize(width: collectionView.bounds.width, height: Layout.sectionHeaderHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: 0,
            left: Layout.sectionHorizontalInset,
            bottom: Layout.sectionBottomInset,
            right: Layout.sectionHorizontalInset
        )
    }
}
