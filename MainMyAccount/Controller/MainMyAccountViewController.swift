//
//  MainMyAccountViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import UIKit

@MainActor
final class MainMyAccountViewController: MainBaseViewController {

    // MARK: - Section

    private enum Section: Int, CaseIterable {
        case profile
    }

    // MARK: - Properties

    private let session: AuthSession

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

    private func makeProfileSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        return section
    }
}
