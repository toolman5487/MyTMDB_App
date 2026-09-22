//
//  BaseDisplayTextFormatter+AttributedText.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/22.
//

import UIKit

// MARK: - BaseDisplayTextFormatter Attributed Text

extension BaseDisplayTextFormatter {

    @MainActor
    static func titleAttributedText(
        title: String?,
        trailingImage: UIImage? = nil,
        font: UIFont,
        textColor: UIColor = ThemeColor.highlight,
        trailingImageColor: UIColor? = nil
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

        attributedString.append(NSAttributedString(string: " "))

        let attachment = NSTextAttachment()
        attachment.image = trailingImage.withTintColor(
            trailingImageColor ?? textColor,
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

    @MainActor
    static func titleAttributedText(
        _ title: String,
        font: UIFont,
        textColor: UIColor = ThemeColor.highlight
    ) -> NSAttributedString {
        titleAttributedText(
            title: title,
            font: font,
            textColor: textColor
        ) ?? NSAttributedString()
    }
}
