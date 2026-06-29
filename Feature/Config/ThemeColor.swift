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

    static let midnightHex = "#090712"
    static let midnightElevatedHex = "#151026"
    static let midnightSurfaceHex = "#211637"
    static let cinemaPurpleHex = "#8B5CF6"
    static let amethystHex = "#C084FC"
    static let spotlightGoldHex = "#F5C451"
    static let velvetRedHex = "#B23A63"

    static let cinemaPurple: UIColor = UIColor(hex: cinemaPurpleHex) ?? .systemPurple
    static let amethyst: UIColor = UIColor(hex: amethystHex) ?? .systemPurple
    static let spotlightGold: UIColor = UIColor(hex: spotlightGoldHex) ?? .systemYellow
    static let velvetRed: UIColor = UIColor(hex: velvetRedHex) ?? .systemPink

    static let primary: UIColor = cinemaPurple
    static let accent: UIColor = amethyst
    static let highlight: UIColor = spotlightGold

    static let purpleGlass: UIColor = UIColor(hex: cinemaPurpleHex, alpha: 0.20) ?? .systemPurple.withAlphaComponent(0.20)
    static let purpleGlassStrong: UIColor = UIColor(hex: cinemaPurpleHex, alpha: 0.35) ?? .systemPurple.withAlphaComponent(0.35)
    static let goldGlass: UIColor = UIColor(hex: spotlightGoldHex, alpha: 0.20) ?? .systemYellow.withAlphaComponent(0.20)

    // MARK: Text

    static let textPrimary: UIColor = .label
    static let textSecondary: UIColor = .secondaryLabel
    static let textTertiary: UIColor = .tertiaryLabel
    static let textQuaternary: UIColor = .quaternaryLabel
    static let textPlaceholder: UIColor = .placeholderText
    static let textLink: UIColor = .link

    // MARK: Background

    static let background: UIColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: midnightHex) ?? .systemBackground

        default:
            return UIColor(hex: "#F8F5FF") ?? .systemBackground
        }
    }

    static let backgroundSecondary: UIColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: midnightElevatedHex) ?? .secondarySystemBackground

        default:
            return UIColor(hex: "#EFE8FF") ?? .secondarySystemBackground
        }
    }

    static let backgroundTertiary: UIColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(hex: midnightSurfaceHex) ?? .tertiarySystemBackground

        default:
            return UIColor(hex: "#E5D8FF") ?? .tertiarySystemBackground
        }
    }

    // MARK: Grouped Background

    static let groupedBackground: UIColor = background
    static let groupedBackgroundSecondary: UIColor = backgroundSecondary
    static let groupedBackgroundTertiary: UIColor = backgroundTertiary

    // MARK: Fill

    static let fill: UIColor = purpleGlassStrong
    static let fillSecondary: UIColor = purpleGlass
    static let fillTertiary: UIColor = goldGlass
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
