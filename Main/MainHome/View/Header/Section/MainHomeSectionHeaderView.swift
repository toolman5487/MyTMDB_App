//
//  MainHomeSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import UIKit

// MARK: - MainHomeSectionHeaderView

@MainActor
class MainHomeSectionHeaderView: BaseSectionHeaderView {

    // MARK: - BaseSectionHeaderView

    override func titleAccessibilityText(for title: String, isTappable: Bool) -> AccessibilityText {
        AccessibilityText(
            label: interfaceLocalization.formatted(
                "home.section.accessibility_label_format",
                defaultValue: "%@ category",
                title
            ),
            value: isTappable
                ? interfaceLocalization.string(
                    "home.section.accessibility_value",
                    defaultValue: "More available"
                )
                : nil,
            hint: isTappable
                ? interfaceLocalization.formatted(
                    "home.section.accessibility_hint_format",
                    defaultValue: "Double-tap to view all %@",
                    title
                )
                : nil
        )
    }
}
