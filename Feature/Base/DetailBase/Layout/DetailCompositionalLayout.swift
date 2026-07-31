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

    // MARK: - Header

    enum SectionHeader {
        case none
        case estimatedHero
        case sectionTitle
    }

    // MARK: - Section Factory

    static func singleItemSection(
        height: NSCollectionLayoutDimension,
        topContentInset: CGFloat,
        bottomContentInset: CGFloat = DetailLayoutMetrics.sectionBottomInset,
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
        section.contentInsets = DetailLayoutMetrics.directionalSectionInsets(
            top: topContentInset,
            bottom: bottomContentInset
        )
        section.boundarySupplementaryItems = boundarySupplementaryItems(for: header)
        return section
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
                        heightDimension: .estimated(DetailLayoutMetrics.estimatedHeroHeight)
                    ),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
            ]

        case .sectionTitle:
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(DetailLayoutMetrics.sectionHeaderHeight)
                ),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            return [header]
        }
    }
}
