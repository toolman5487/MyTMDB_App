//
//  MainHomeSectionTitleAttributedStringFactory.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import UIKit

// MARK: - MainHomeSectionTitleAttributedStringFactory

@MainActor
enum MainHomeSectionTitleAttributedStringFactory {

    static func make(
        title: String?,
        trailingImage: UIImage?,
        font: UIFont = .preferredFont(forTextStyle: .title3),
        textColor: UIColor = ThemeColor.textPrimary
    ) -> NSAttributedString? {
        BaseDisplayTextFormatter.titleAttributedText(
            title: title,
            trailingImage: trailingImage,
            font: font,
            textColor: textColor
        )
    }
}
