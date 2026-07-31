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

    static let sectionHeaderHeight: CGFloat = 28
    static let factsSectionHeight: CGFloat = 96
    static let headerContentSpacing: CGFloat = 8
    static let sectionBottomInset: CGFloat = 8
    static let estimatedHeroHeight: CGFloat = 360

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
}
