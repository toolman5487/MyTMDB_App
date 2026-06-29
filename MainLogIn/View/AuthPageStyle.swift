//
//  AuthPageStyle.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import SnapKit
import UIKit

// MARK: - Auth Page Style

enum AuthPageStyle {

    // MARK: - Layout

    enum Layout {
        static let pageInset: CGFloat = 16
        static let fieldHeight: CGFloat = 56
        static let buttonHeight: CGFloat = 48
        static let stackSpacing: CGFloat = 16
        static let stackMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let symbolSize: CGFloat = 48
        static let symbolSpacing: CGFloat = 12

        static let cardHeight: CGFloat =
            stackMargins.top
            + fieldHeight
            + stackSpacing
            + fieldHeight
            + stackSpacing
            + buttonHeight
            + stackMargins.bottom

        static let pageHeight: CGFloat = pageInset * 2 + cardHeight
    }

    // MARK: - Card

    static func applyCardStyle(to view: UIView) {
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
    }

    static func applyCardLayout(_ cardView: UIView, in container: UIView) {
        container.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.pageInset)
            make.top.bottom.equalToSuperview().inset(Layout.pageInset)
            make.height.equalTo(Layout.cardHeight)
        }
    }

    static func applyActionButtonLayout(_ button: UIButton, in cardView: UIView) {
        cardView.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.stackMargins.left)
            make.bottom.equalToSuperview().inset(Layout.stackMargins.bottom)
            make.height.equalTo(Layout.buttonHeight)
        }
    }

    // MARK: - Input

    static func makeInputStack(arrangedSubviews: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.axis = .vertical
        stack.spacing = Layout.stackSpacing
        stack.alignment = .fill
        return stack
    }

    static func applyFieldHeight(_ field: UITextField) {
        field.snp.makeConstraints { make in
            make.height.equalTo(Layout.fieldHeight)
        }
    }

    // MARK: - Description

    static func makeDescriptionContentStack(
        symbolName: String,
        label: UILabel
    ) -> UIStackView {
        let symbolImageView = makeSymbolImageView(systemName: symbolName)
        let symbolContainer = UIView()
        symbolContainer.addSubview(symbolImageView)

        symbolImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.height.equalTo(Layout.symbolSize)
        }

        let stack = UIStackView(arrangedSubviews: [symbolContainer, label])
        stack.axis = .vertical
        stack.spacing = Layout.symbolSpacing
        stack.alignment = .fill
        return stack
    }

    static func applyCenteredDescriptionLayout(
        symbolName: String,
        label: UILabel,
        in cardView: UIView,
        above button: UIButton
    ) {
        let contentAreaView = UIView()
        let contentStack = makeDescriptionContentStack(symbolName: symbolName, label: label)

        cardView.addSubview(contentAreaView)
        contentAreaView.addSubview(contentStack)

        contentAreaView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(button.snp.top)
        }

        contentStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Layout.stackMargins.left)
        }
    }

    static func makeSymbolImageView(systemName: String) -> UIImageView {
        let imageView = UIImageView()
        let configuration = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        imageView.image = UIImage(systemName: systemName, withConfiguration: configuration)
        imageView.tintColor = ThemeColor.primary
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityTraits = .image
        return imageView
    }

    // MARK: - Components

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
}
