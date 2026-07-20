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

    static let tmdbDarkBlueHex = "#0D253F"
    static let tmdbLightBlueHex = "#01B4E4"
    static let tmdbDarkBlue: UIColor = UIColor(hex: tmdbDarkBlueHex) ?? .systemBlue
    static let tmdbLightBlue: UIColor = UIColor(hex: tmdbLightBlueHex) ?? .systemCyan

    static let primary: UIColor = tmdbDarkBlue
    static let accent: UIColor = tmdbLightBlue
    static let highlight: UIColor = tmdbLightBlue

    static let lightBlueGlass: UIColor = UIColor(hex: tmdbLightBlueHex, alpha: 0.20) ?? .systemCyan.withAlphaComponent(0.20)

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

    static let groupedBackground: UIColor = background
    static let groupedBackgroundSecondary: UIColor = backgroundSecondary
    static let groupedBackgroundTertiary: UIColor = backgroundTertiary

    // MARK: Fill

    static let fillSecondary: UIColor = lightBlueGlass
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
