//
//  ThemeColor.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import UIKit

// MARK: - Theme Color

enum ThemeColor {

    // MARK: Brand

    static let sakuraHex = "#FFB7C5"

    static let sakura: UIColor = UIColor(hex: sakuraHex) ?? .systemPink
    static let primary: UIColor = sakura
    static let accent: UIColor = sakura

    static let sakuraGlass: UIColor = UIColor(hex: sakuraHex, alpha: 0.20) ?? .systemPink.withAlphaComponent(0.20)
    static let sakuraGlassStrong: UIColor = UIColor(hex: sakuraHex, alpha: 0.35) ?? .systemPink.withAlphaComponent(0.35)

    // MARK: Text

    static let textPrimary: UIColor = .label
    static let textSecondary: UIColor = .secondaryLabel
    static let textTertiary: UIColor = .tertiaryLabel
    static let textQuaternary: UIColor = .quaternaryLabel
    static let textPlaceholder: UIColor = .placeholderText
    static let textLink: UIColor = .link

    // MARK: Background

    static let background: UIColor = .systemBackground
    static let backgroundSecondary: UIColor = .secondarySystemBackground
    static let backgroundTertiary: UIColor = .tertiarySystemBackground

    // MARK: Grouped Background

    static let groupedBackground: UIColor = .systemGroupedBackground
    static let groupedBackgroundSecondary: UIColor = .secondarySystemGroupedBackground
    static let groupedBackgroundTertiary: UIColor = .tertiarySystemGroupedBackground

    // MARK: Fill

    static let fill: UIColor = .systemFill
    static let fillSecondary: UIColor = .secondarySystemFill
    static let fillTertiary: UIColor = .tertiarySystemFill
    static let fillQuaternary: UIColor = .quaternarySystemFill

    // MARK: Separator

    static let separator: UIColor = .separator
    static let opaqueSeparator: UIColor = .opaqueSeparator

    // MARK: System Feedback

    static let systemRed: UIColor = .systemRed
    static let systemOrange: UIColor = .systemOrange
    static let systemYellow: UIColor = .systemYellow
    static let systemGreen: UIColor = .systemGreen
    static let systemMint: UIColor = .systemMint
    static let systemTeal: UIColor = .systemTeal
    static let systemCyan: UIColor = .systemCyan
    static let systemBlue: UIColor = .systemBlue
    static let systemIndigo: UIColor = .systemIndigo
    static let systemPurple: UIColor = .systemPurple
    static let systemPink: UIColor = .systemPink
    static let systemBrown: UIColor = .systemBrown

    // MARK: Gray Scale

    static let gray: UIColor = .systemGray
    static let gray2: UIColor = .systemGray2
    static let gray3: UIColor = .systemGray3
    static let gray4: UIColor = .systemGray4
    static let gray5: UIColor = .systemGray5
    static let gray6: UIColor = .systemGray6
}
