//
//  AppFactory.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import UIKit

// MARK: - AppFactory

@MainActor
enum AppFactory {

    // MARK: - Metrics

    enum Metrics {
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let fieldHeight: CGFloat = 56
        static let buttonHeight: CGFloat = 48
    }

    // MARK: - Animation

    @MainActor
    enum Animation {

        // MARK: - Kind

        enum Kind {
            case loadingAir
            case searchLoading
            case popcornLoading
            case error

            var animationName: String {
                switch self {
                case .loadingAir:
                    return "loadingAir"

                case .searchLoading:
                    return "loadingAnimation_blue"

                case .popcornLoading:
                    return "Animation_popcorn"

                case .error:
                    return "ErrorAnimation"
                }
            }
        }

        // MARK: - Public Factory Methods

        static func loadingAir(
            size: CGFloat,
            message: String? = nil,
            startsAnimating: Bool = true
        ) -> AppAnimationView {
            AppAnimationView(
                animation: .loadingAir,
                size: size,
                message: message,
                startsAnimating: startsAnimating
            )
        }

        static func searchLoading(
            size: CGFloat,
            message: String? = nil,
            startsAnimating: Bool = true
        ) -> AppAnimationView {
            AppAnimationView(
                animation: .searchLoading,
                size: size,
                message: message,
                startsAnimating: startsAnimating
            )
        }

        static func popcornLoading(
            size: CGFloat,
            message: String? = nil,
            startsAnimating: Bool = true
        ) -> AppAnimationView {
            AppAnimationView(
                animation: .popcornLoading,
                size: size,
                message: message,
                startsAnimating: startsAnimating
            )
        }

        static func error(
            size: CGFloat,
            message: String? = nil,
            startsAnimating: Bool = true
        ) -> AppAnimationView {
            AppAnimationView(
                animation: .error,
                size: size,
                message: message,
                startsAnimating: startsAnimating
            )
        }
    }

    // MARK: - Label

    @MainActor
    enum Label {

        // MARK: - Title Styles

        static func largeTitle(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textPrimary,
            alignment: NSTextAlignment = .center,
            lines: Int = 0
        ) -> UILabel {
            make(text: text, textStyle: .largeTitle, color: color, alignment: alignment, lines: lines)
        }

        static func title1(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textPrimary,
            alignment: NSTextAlignment = .center,
            lines: Int = 0
        ) -> UILabel {
            make(text: text, textStyle: .title1, color: color, alignment: alignment, lines: lines)
        }

        static func title2(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textPrimary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 2
        ) -> UILabel {
            make(text: text, textStyle: .title2, color: color, alignment: alignment, lines: lines)
        }

        static func title3(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textPrimary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 1
        ) -> UILabel {
            make(text: text, textStyle: .title3, color: color, alignment: alignment, lines: lines)
        }

        // MARK: - Content Styles

        static func headline(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textPrimary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 1
        ) -> UILabel {
            make(text: text, textStyle: .headline, color: color, alignment: alignment, lines: lines)
        }

        static func body(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textSecondary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 0
        ) -> UILabel {
            make(text: text, textStyle: .body, color: color, alignment: alignment, lines: lines)
        }

        static func callout(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textPrimary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 1
        ) -> UILabel {
            make(text: text, textStyle: .callout, color: color, alignment: alignment, lines: lines)
        }

        static func subheadline(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textSecondary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 1
        ) -> UILabel {
            make(text: text, textStyle: .subheadline, color: color, alignment: alignment, lines: lines)
        }

        static func footnote(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textTertiary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 1
        ) -> UILabel {
            make(text: text, textStyle: .footnote, color: color, alignment: alignment, lines: lines)
        }

        // MARK: - Caption Styles

        static func caption1(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textPrimary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 1
        ) -> UILabel {
            make(text: text, textStyle: .caption1, color: color, alignment: alignment, lines: lines)
        }

        static func caption2(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textTertiary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 1
        ) -> UILabel {
            make(text: text, textStyle: .caption2, color: color, alignment: alignment, lines: lines)
        }

        // MARK: - Semantic Aliases

        static func sectionTitle(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textPrimary,
            alignment: NSTextAlignment = .natural
        ) -> UILabel {
            title3(text, color: color, alignment: alignment, lines: 1)
        }

        static func captionPrimary(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textPrimary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 2
        ) -> UILabel {
            caption1(text, color: color, alignment: alignment, lines: lines)
        }

        static func captionSecondary(
            _ text: String? = nil,
            color: UIColor = ThemeColor.textTertiary,
            alignment: NSTextAlignment = .natural,
            lines: Int = 1
        ) -> UILabel {
            caption2(text, color: color, alignment: alignment, lines: lines)
        }

        // MARK: - Private Helpers

        private static func make(
            text: String?,
            textStyle: UIFont.TextStyle,
            color: UIColor,
            alignment: NSTextAlignment,
            lines: Int = 1
        ) -> UILabel {
            let label = UILabel()
            label.text = text
            label.font = .preferredFont(forTextStyle: textStyle)
            label.textColor = color
            label.textAlignment = alignment
            label.numberOfLines = lines
            label.adjustsFontForContentSizeCategory = true
            return label
        }
    }

    // MARK: - Button

    @MainActor
    enum Button {

        // MARK: - Public Factory Methods

        static func primaryFilled(title: String) -> UIButton {
            var configuration = UIButton.Configuration.filled()
            configuration.attributedTitle = attributedTitle(title, textStyle: .headline)
            configuration.baseBackgroundColor = ThemeColor.primary
            configuration.baseForegroundColor = .white
            configuration.cornerStyle = .medium

            return UIButton(configuration: configuration)
        }

        static func destructiveFilled(title: String) -> UIButton {
            var configuration = UIButton.Configuration.filled()
            configuration.attributedTitle = attributedTitle(title, textStyle: .headline)
            configuration.baseBackgroundColor = ThemeColor.systemRed
            configuration.baseForegroundColor = .white
            configuration.cornerStyle = .medium

            return UIButton(configuration: configuration)
        }

        static func plain(
            title: String,
            color: UIColor = ThemeColor.highlight
        ) -> UIButton {
            var configuration = UIButton.Configuration.plain()
            configuration.attributedTitle = attributedTitle(title, textStyle: .body)
            configuration.baseForegroundColor = color

            return UIButton(configuration: configuration)
        }

        // MARK: - Private Helpers

        private static func attributedTitle(
            _ title: String,
            textStyle: UIFont.TextStyle
        ) -> AttributedString {
            var attribute = AttributedString(title)
            attribute.font = UIFont.preferredFont(forTextStyle: textStyle)
            return attribute
        }
    }

    // MARK: - TextField

    @MainActor
    enum TextField {

        // MARK: - Public Factory Methods

        static func rounded(
            placeholder: String,
            contentType: UITextContentType? = nil,
            isSecure: Bool = false
        ) -> UITextField {
            let textField = UITextField()
            textField.placeholder = placeholder
            textField.clearButtonMode = .whileEditing
            textField.borderStyle = .roundedRect
            textField.layer.borderWidth = 1
            textField.layer.borderColor = UIColor.secondaryLabel.cgColor
            textField.layer.cornerRadius = Metrics.cornerRadiusSmall
            textField.font = .preferredFont(forTextStyle: .body)
            textField.adjustsFontForContentSizeCategory = true
            textField.textContentType = contentType
            textField.isSecureTextEntry = isSecure
            textField.autocapitalizationType = .none
            return textField
        }
    }

    // MARK: - ImageView

    @MainActor
    enum ImageView {

        // MARK: - Public Factory Methods

        static func symbol(
            systemName: String,
            pointSize: CGFloat,
            weight: UIImage.SymbolWeight = .regular,
            color: UIColor = ThemeColor.textTertiary,
            contentMode: UIView.ContentMode = .scaleAspectFit
        ) -> UIImageView {
            let imageView = UIImageView()
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
            imageView.image = UIImage(systemName: systemName, withConfiguration: configuration)
            imageView.tintColor = color
            imageView.contentMode = contentMode
            return imageView
        }

        static func poster(
            cornerRadius: CGFloat = Metrics.cornerRadiusSmall,
            backgroundColor: UIColor = ThemeColor.backgroundTertiary
        ) -> UIImageView {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = backgroundColor
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = cornerRadius
            imageView.layer.cornerCurve = .continuous
            return imageView
        }

        static func avatar(
            size: CGFloat,
            placeholderSystemName: String = "person.fill",
            placeholderPointSize: CGFloat = 28
        ) -> UIImageView {
            let imageView = UIImageView()
            imageView.contentMode = .center
            imageView.backgroundColor = ThemeColor.backgroundTertiary
            imageView.tintColor = ThemeColor.textTertiary
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = size / 2
            imageView.layer.cornerCurve = .continuous
            imageView.image = UIImage(
                systemName: placeholderSystemName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: placeholderPointSize, weight: .regular)
            )
            return imageView
        }
    }

    // MARK: - View

    @MainActor
    enum View {

        // MARK: - Public Factory Methods

        static func card(
            backgroundColor: UIColor = ThemeColor.backgroundSecondary,
            cornerRadius: CGFloat = Metrics.cornerRadiusMedium
        ) -> UIView {
            let view = UIView()
            applyCardStyle(to: view, backgroundColor: backgroundColor, cornerRadius: cornerRadius)
            return view
        }

        // MARK: - Style Helpers

        static func applyCardStyle(
            to view: UIView,
            backgroundColor: UIColor = ThemeColor.backgroundSecondary,
            cornerRadius: CGFloat = Metrics.cornerRadiusMedium
        ) {
            view.backgroundColor = backgroundColor
            view.layer.cornerRadius = cornerRadius
            view.layer.cornerCurve = .continuous
            view.layer.masksToBounds = true
        }

        static func applyRoundedCorners(
            to view: UIView,
            radius: CGFloat = Metrics.cornerRadiusSmall
        ) {
            view.layer.cornerRadius = radius
            view.layer.cornerCurve = .continuous
            view.layer.masksToBounds = true
        }
    }

    // MARK: - NavigationBar

    @MainActor
    enum NavigationBar {

        // MARK: - Public Factory Methods

        static func standardAppearance(
            titleColor: UIColor = ThemeColor.highlight,
            backgroundColor: UIColor = ThemeColor.background,
            shadowColor: UIColor = ThemeColor.separator
        ) -> UINavigationBarAppearance {
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: titleColor
            ]

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = shadowColor
            appearance.titleTextAttributes = titleAttributes
            appearance.largeTitleTextAttributes = titleAttributes
            return appearance
        }

        static func transparentAppearance(
            titleColor: UIColor = ThemeColor.highlight
        ) -> UINavigationBarAppearance {
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: titleColor
            ]

            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            appearance.titleTextAttributes = titleAttributes
            appearance.largeTitleTextAttributes = titleAttributes
            return appearance
        }

        // MARK: - Style Helpers

        static func applyStandardAppearance(to navigationItem: UINavigationItem) {
            let appearance = standardAppearance()
            navigationItem.standardAppearance = appearance
            navigationItem.compactAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance
            navigationItem.compactScrollEdgeAppearance = appearance
            navigationItem.largeTitleDisplayMode = .never
        }
    }

    // MARK: - SortMenu

    @MainActor
    enum SortMenu {

        // MARK: - Public Factory Methods

        static func makeMenu<Option: AppSortMenuOption>(
            selectedOption: Option?,
            onSelect: @escaping (Option) -> Void
        ) -> UIMenu {
            let actions = Option.allCases.map { option in
                UIAction(
                    title: option.title,
                    state: selectedOption == option ? .on : .off
                ) { _ in
                    Task(priority: .userInitiated) { @MainActor in
                        onSelect(option)
                    }
                }
            }

            return UIMenu(
                title: "排序",
                options: .singleSelection,
                children: Array(actions)
            )
        }

        static func makeBarButtonItem<Option: AppSortMenuOption>(
            selectedOption: Option?,
            onSelect: @escaping (Option) -> Void
        ) -> UIBarButtonItem {
            let barButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "line.3.horizontal.decrease"),
                menu: makeMenu(selectedOption: selectedOption, onSelect: onSelect)
            )
            barButtonItem.tintColor = ThemeColor.textPrimary
            return barButtonItem
        }
    }
}

// MARK: - AppSortMenuOption

protocol AppSortMenuOption: Hashable, CaseIterable {
    var title: String { get }
}
