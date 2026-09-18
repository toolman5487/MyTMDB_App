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
            label: "\(title) 分類",
            value: isTappable ? "可查看更多" : nil,
            hint: isTappable ? "點兩下查看\(title)完整列表" : nil
        )
    }
}
