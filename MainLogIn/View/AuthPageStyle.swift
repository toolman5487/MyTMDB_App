//
//  AuthPageStyle.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import UIKit

// MARK: - Auth Page Style

enum AuthPageStyle {

    static func makeTitleLabel(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }

    static func makeDescriptionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }

    static func makeFilledButton(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        var attribute = AttributedString(title)
        attribute.font = UIFont.preferredFont(forTextStyle: .headline)
        config.attributedTitle = attribute
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        config.cornerStyle = .medium
        let button = UIButton(configuration: config, primaryAction: nil)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }

    static func makeTextField(
        placeholder: String,
        contentType: UITextContentType?,
        isSecure: Bool = false
    ) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.secondaryLabel.cgColor
        textField.layer.cornerRadius = 8
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textContentType = contentType
        textField.isSecureTextEntry = isSecure
        textField.autocapitalizationType = .none
        return textField
    }

    static func applyCardStyle(to stack: UIStackView) {
        stack.backgroundColor = .secondarySystemBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true
    }
}
