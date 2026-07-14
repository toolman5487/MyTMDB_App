//
//  DetailCompositionalLayout.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/14.
//

import UIKit

// MARK: - DetailCompositionalLayout

@MainActor
enum DetailCompositionalLayout {

    // MARK: - Metrics

    enum Metrics {
        static let sectionHeaderHeight: CGFloat = 28
        static let headerContentSpacing: CGFloat = 8
        static let horizontalInset: CGFloat = 16
        static let sectionBottomInset: CGFloat = 24
        static let estimatedHeroHeight: CGFloat = 360
    }

    // MARK: - Header

    enum SectionHeader {
        case none
        case estimatedHero
        case sectionTitle
    }

    // MARK: - Section Factory

    static func singleItemSection(
        height: NSCollectionLayoutDimension,
        contentInsets: NSDirectionalEdgeInsets,
        header: SectionHeader
    ) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: height
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: height
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = contentInsets
        section.boundarySupplementaryItems = boundarySupplementaryItems(for: header)
        return section
    }

    static func contentInsets(
        top: CGFloat,
        horizontalInset: CGFloat = Metrics.horizontalInset,
        bottom: CGFloat = Metrics.sectionBottomInset
    ) -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(
            top: top,
            leading: horizontalInset,
            bottom: bottom,
            trailing: horizontalInset
        )
    }

    // MARK: - Private Helpers

    private static func boundarySupplementaryItems(
        for header: SectionHeader
    ) -> [NSCollectionLayoutBoundarySupplementaryItem] {
        switch header {
        case .none:
            return []

        case .estimatedHero:
            return [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .estimated(Metrics.estimatedHeroHeight)
                    ),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
            ]

        case .sectionTitle:
            return [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(Metrics.sectionHeaderHeight)
                    ),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
            ]
        }
    }
}
