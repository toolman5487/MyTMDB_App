//
//  DetailSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/30.
//

import UIKit

// MARK: - DetailSectionHeaderView

@MainActor
final class DetailSectionHeaderView: BaseSectionHeaderView {

    // MARK: - BaseSectionHeaderView

    override func titleAccessibilityText(for title: String, isTappable: Bool) -> AccessibilityText {
        AccessibilityText(
            label: "\(title) 區段",
            hint: isTappable ? "點兩下查看完整列表" : nil
        )
    }
}
