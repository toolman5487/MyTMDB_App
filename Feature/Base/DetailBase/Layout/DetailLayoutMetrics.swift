//
//  DetailLayoutMetrics.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/31.
//

import UIKit

// MARK: - DetailLayoutMetrics

nonisolated enum DetailLayoutMetrics {

    // MARK: - Dimensions

    static let sectionHeaderHeight: CGFloat = SectionHeaderLayoutMetrics.height
    static let factsSectionHeight: CGFloat = 96
    static let headerContentSpacing: CGFloat = SectionHeaderLayoutMetrics.contentSpacing
    static let sectionBottomInset: CGFloat = SectionHeaderLayoutMetrics.sectionSpacing
    static let estimatedHeroHeight: CGFloat = 360
    static let horizontalContentInset: CGFloat = 16

    // MARK: - Insets

    static func sectionInsets(
        top: CGFloat,
        bottom: CGFloat = sectionBottomInset
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
    }

    static func directionalSectionInsets(
        top: CGFloat,
        bottom: CGFloat = sectionBottomInset
    ) -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: top, leading: 0, bottom: bottom, trailing: 0)
    }

    static var horizontalContentInsets: UIEdgeInsets {
        UIEdgeInsets(
            top: 0,
            left: horizontalContentInset,
            bottom: 0,
            right: horizontalContentInset
        )
    }

    static func contentWidth(
        for availableWidth: CGFloat,
        horizontalInsetLevelCount: Int = 1
    ) -> CGFloat {
        let totalInset = horizontalContentInset
            * 2
            * CGFloat(max(horizontalInsetLevelCount, 0))
        return max(availableWidth - totalInset, 0)
    }
}
