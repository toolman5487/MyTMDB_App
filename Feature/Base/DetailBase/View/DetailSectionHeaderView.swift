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
            label: interfaceLocalization.formatted(
                "detail.section_header.accessibility_label_format",
                defaultValue: "%@ section",
                title
            ),
            hint: isTappable
                ? interfaceLocalization.string(
                    "detail.section_header.accessibility_hint",
                    defaultValue: "Double-tap to view the full list"
                )
                : nil
        )
    }
}
