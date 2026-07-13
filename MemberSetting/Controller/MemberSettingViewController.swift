//
//  MemberSettingViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/13.
//

import UIKit

@MainActor
final class MemberSettingViewController: BaseListViewController {

    // MARK: - Properties

    private let viewModel: MemberSettingViewModel

    override var collectionViewItemHeight: CGFloat {
        56
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

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.title = "設定"
        view.backgroundColor = ThemeColor.background
        configureCollectionView()
    }

    // MARK: - Setup

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ThemeColor.background
        collectionView.register(
            MemberSettingLogoutButtonCollectionViewCell.self,
            forCellWithReuseIdentifier: MemberSettingLogoutButtonCollectionViewCell.reuseIdentifier
        )
    }

    // MARK: - Actions

    private func presentLogoutConfirmation() {
        let alert = UIAlertController(
            title: "登出",
            message: "確定要登出並返回登入頁嗎？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "登出", style: .destructive) { [weak self] _ in
                self?.logout()
            }
        )
        present(alert, animated: true)
    }

    private func logout() {
        viewModel.logout()
        navigateToLoginScreen()
    }

    private func navigateToLoginScreen() {
        guard let window = view.window else { return }
        AppRootFactory.replaceRoot(in: window, for: .loggedOut)
    }
}

// MARK: - UICollectionViewDataSource

extension MemberSettingViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.rows.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MemberSettingLogoutButtonCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        guard let cell = cell as? MemberSettingLogoutButtonCollectionViewCell,
              let row = viewModel.row(at: indexPath.item) else {
            return cell
        }

        cell.configure(with: row)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MemberSettingViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        switch viewModel.action(at: indexPath.item) {
        case .logout:
            presentLogoutConfirmation()

        case nil:
            return
        }
    }
}
