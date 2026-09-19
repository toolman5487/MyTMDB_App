//
//  MainMemberSettingViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/13.
//

import UIKit

@MainActor
final class MainMemberSettingViewController: MainBaseViewController {

    // MARK: - Constants

    private enum Layout {
        static let profileItemHeight: CGFloat = 88
        static let guestPromptItemHeight: CGFloat = 232
        static let itemHeight: CGFloat = 56
        static let minimumLineSpacing: CGFloat = 4
        static let sectionHeaderHeight: CGFloat = 32
        static let sectionHorizontalInset: CGFloat = 16
        static let sectionBottomInset: CGFloat = 24
    }

    // MARK: - Properties

    private let viewModel: MainMemberSettingViewModel
    private let sceneBuilder: MemberCenterSceneBuilding
    private let appFlowRouter: AppFlowRouting
    private lazy var router: MainMemberSettingRouting = MainMemberSettingRouter(
        sourceViewController: self,
        sceneBuilder: sceneBuilder,
        appFlowRouter: appFlowRouter,
        interfaceLocalization: viewModel.interfaceLocalization
    )

    private var profileRefreshTask: Task<Void, Never>?
    private var sessionActionTask: Task<Void, Never>?
    private var sessionActionID: UUID?

    // MARK: - Initialization

    init(
        viewModel: MainMemberSettingViewModel,
        sceneBuilder: MemberCenterSceneBuilding,
        appFlowRouter: AppFlowRouting
    ) {
        self.viewModel = viewModel
        self.sceneBuilder = sceneBuilder
        self.appFlowRouter = appFlowRouter
        super.init(nibName: nil, bundle: nil)
        setInterfaceLocalization(viewModel.interfaceLocalization)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        profileRefreshTask?.cancel()
        sessionActionTask?.cancel()
    }

    // MARK: - Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reloadContent()
        collectionView.reloadData()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.title = viewModel.navigationTitle
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
            MainMemberSettingSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainMemberSettingSectionHeaderView.reuseIdentifier
        )
    }

    private func registerCells() {
        collectionView.register(
            MainMemberSettingProfileSummaryCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberSettingProfileSummaryCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainMemberSettingGuestPromptCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberSettingGuestPromptCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainMemberSettingRefreshProfileCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberSettingRefreshProfileCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainMemberSettingDefaultCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberSettingDefaultCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainMemberSettingClearProfileCacheCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberSettingClearProfileCacheCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainMemberSettingAppVersionCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberSettingAppVersionCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainMemberSettingTMDBAttributionCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberSettingTMDBAttributionCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainMemberSettingLogoutButtonCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberSettingLogoutButtonCollectionViewCell.reuseIdentifier
        )
    }

    // MARK: - Actions

    private func refreshProfile() {
        profileRefreshTask?.cancel()
        profileRefreshTask = Task(priority: .userInitiated) { [weak self] in
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
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.clearImageCache()
            router.showImageCacheCleared()
        }
    }

    private func presentClearSearchHistoryConfirmation() {
        router.showClearSearchHistoryConfirmation { [weak self] in
            self?.clearSearchHistory()
        }
    }

    private func clearSearchHistory() {
        viewModel.clearSearchHistory()
        collectionView.reloadData()
        router.showSearchHistoryCleared()
    }

    private func presentClearAllLocalDataConfirmation() {
        router.showClearAllLocalDataConfirmation(isMember: viewModel.isMember) { [weak self] in
            self?.clearAllLocalData()
        }
    }

    private func clearAllLocalData(logoutScope: LogoutScope = .remoteAndLocal) {
        sessionActionTask?.cancel()
        let actionID = UUID()
        sessionActionID = actionID
        setLoadingVisible(true)
        sessionActionTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            defer { finishSessionAction(actionID) }

            do {
                try await viewModel.clearAllLocalData(logoutScope: logoutScope)
                router.showLoggedOut()
            } catch LogoutError.secureSessionUnavailable {
                guard !Task.isCancelled else { return }
                router.showSecureSessionOperationFailed { [weak self] in
                    self?.clearAllLocalData(logoutScope: logoutScope)
                }
            } catch {
                guard !Task.isCancelled else { return }
                router.showClearAllLocalDataFailed(
                    onRetry: { [weak self] in
                        self?.clearAllLocalData()
                    },
                    onClearLocalOnly: { [weak self] in
                        self?.clearAllLocalData(logoutScope: .localOnly)
                    }
                )
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

    private func logout(scope: LogoutScope = .remoteAndLocal) {
        sessionActionTask?.cancel()
        let actionID = UUID()
        sessionActionID = actionID
        setLoadingVisible(true)
        sessionActionTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            defer { finishSessionAction(actionID) }

            do {
                try await viewModel.logout(scope: scope)
                router.showLoggedOut()
            } catch LogoutError.secureSessionUnavailable {
                guard !Task.isCancelled else { return }
                router.showSecureSessionOperationFailed { [weak self] in
                    self?.logout(scope: scope)
                }
            } catch {
                guard !Task.isCancelled else { return }
                router.showLogoutFailed(
                    onRetry: { [weak self] in
                        self?.logout()
                    },
                    onClearLocalOnly: { [weak self] in
                        self?.logout(scope: .localOnly)
                    }
                )
            }
        }
    }

    private func finishSessionAction(_ actionID: UUID) {
        guard sessionActionID == actionID else { return }
        sessionActionID = nil
        setLoadingVisible(false)
    }

    private func showMemberCenter() {
        router.showMemberCenter(session: viewModel.currentSession)
    }

    private func showLogin() {
        router.showLogin()
    }

    private func showRegister() {
        router.showRegister()
    }
}

// MARK: - UICollectionViewDataSource

extension MainMemberSettingViewController: UICollectionViewDataSource {

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
        if let guestPromptCell = cell as? MainMemberSettingGuestPromptCollectionViewCell {
            guestPromptCell.configure(
                with: viewModel.guestPrompt,
                onLogin: { [weak self] in self?.showLogin() },
                onRegister: { [weak self] in self?.showRegister() }
            )
            return guestPromptCell
        }

        if let profileCell = cell as? MainMemberSettingProfileSummaryCollectionViewCell {
            profileCell.configure(
                with: viewModel.profileSummary,
                localization: viewModel.interfaceLocalization
            )
            return profileCell
        }

        guard let settingCell = cell as? MainMemberSettingButtonCollectionViewCell else { return cell }

        configure(
            settingCell,
            with: row,
            section: section,
            indexPath: indexPath
        )
        return settingCell
    }

    private func dequeueCell(for row: MainMemberSettingRowItem, at indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier: String

        switch row.kind {
        case .profileSummary:
            reuseIdentifier = MainMemberSettingProfileSummaryCollectionViewCell.reuseIdentifier

        case .guestPrompt:
            reuseIdentifier = MainMemberSettingGuestPromptCollectionViewCell.reuseIdentifier

        case .accountID,
             .clearImageCache,
             .clearSearchHistory,
             .clearAllLocalData,
             .apiDataLanguage,
             .loginStatus,
             .appInterfaceLanguage,
             .defaultSort,
             .defaultContentType:
            reuseIdentifier = MainMemberSettingDefaultCollectionViewCell.reuseIdentifier

        case .refreshProfile:
            reuseIdentifier = MainMemberSettingRefreshProfileCollectionViewCell.reuseIdentifier

        case .clearProfileCache:
            reuseIdentifier = MainMemberSettingClearProfileCacheCollectionViewCell.reuseIdentifier

        case .appVersion:
            reuseIdentifier = MainMemberSettingAppVersionCollectionViewCell.reuseIdentifier

        case .tmdbAttribution:
            reuseIdentifier = MainMemberSettingTMDBAttributionCollectionViewCell.reuseIdentifier

        case .logout:
            reuseIdentifier = MainMemberSettingLogoutButtonCollectionViewCell.reuseIdentifier
        }

        return collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        )
    }

    private func configure(
        _ cell: MainMemberSettingButtonCollectionViewCell,
        with row: MainMemberSettingRowItem,
        section: MainMemberSettingSectionItem,
        indexPath: IndexPath
    ) {
        cell.configure(
            with: row,
            isFirstInSection: indexPath.item == 0,
            isLastInSection: indexPath.item == section.rows.count - 1,
            localization: viewModel.interfaceLocalization,
            onToggleValueChanged: row.kind == .appInterfaceLanguage
                ? { [weak self] isEnglishEnabled in
                    self?.applyInterfaceLanguage(isEnglishEnabled: isEnglishEnabled)
                }
                : nil
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
            withReuseIdentifier: MainMemberSettingSectionHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MainMemberSettingSectionHeaderView {
            headerView.configure(
                title: viewModel.section(at: indexPath.section)?.title,
                localization: viewModel.interfaceLocalization
            )
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainMemberSettingViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginTabBarVisibilityTracking(for: scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTabBarVisibilityTracking(for: scrollView)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let height: CGFloat

        switch viewModel.row(at: indexPath)?.kind {
        case .profileSummary:
            height = Layout.profileItemHeight

        case .guestPrompt:
            height = Layout.guestPromptItemHeight

        default:
            height = Layout.itemHeight
        }

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
        case .showMemberCenter:
            showMemberCenter()

        case .refreshProfile:
            refreshProfile()

        case .clearProfileCache:
            presentClearProfileCacheConfirmation()

        case .clearImageCache:
            presentClearImageCacheConfirmation()

        case .clearSearchHistory:
            presentClearSearchHistoryConfirmation()

        case .clearAllLocalData:
            presentClearAllLocalDataConfirmation()

        case .tmdbAttribution:
            openTMDBAttribution()

        case .logout:
            presentLogoutConfirmation()

        case .login:
            showLogin()

        case .register:
            showRegister()

        case nil:
            return
        }
    }

    private func applyInterfaceLanguage(isEnglishEnabled: Bool) {
        guard let language = viewModel.interfaceLanguage(
            isEnglishEnabled: isEnglishEnabled
        ) else {
            return
        }

        appFlowRouter.applyInterfaceLanguage(
            language,
            session: viewModel.currentSession
        )
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
