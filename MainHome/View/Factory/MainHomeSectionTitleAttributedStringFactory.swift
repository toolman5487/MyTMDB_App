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

    private enum Layout {
        static let titleSymbolSpacing = " "
    }

    static func make(
        title: String?,
        trailingImage: UIImage?,
        font: UIFont = .preferredFont(forTextStyle: .title3),
        textColor: UIColor = ThemeColor.textPrimary
    ) -> NSAttributedString? {
        guard let title else { return nil }

        let attributedString = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: font,
                .foregroundColor: textColor
            ]
        )

        guard let trailingImage else {
            return attributedString
        }

        attributedString.append(NSAttributedString(string: Layout.titleSymbolSpacing))

        let attachment = NSTextAttachment()
        attachment.image = trailingImage.withTintColor(
            textColor,
            renderingMode: .alwaysOriginal
        )
        attachment.bounds = CGRect(
            x: 0,
            y: (font.capHeight - trailingImage.size.height) / 2,
            width: trailingImage.size.width,
            height: trailingImage.size.height
        )
        attributedString.append(NSAttributedString(attachment: attachment))

        return attributedString
    }
}
