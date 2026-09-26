//
//  DetailImagePreviewViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/17.
//

import UIKit

// MARK: - DetailImagePreviewViewController

@MainActor
final class DetailImagePreviewViewController: BaseImagePreviewViewController {

    // MARK: - Alpha

    private enum Alpha {
        static let pageIndicator: CGFloat = 0.32
        static let closeButtonBackground: CGFloat = 0.48
    }

    // MARK: - Style

    override var previewBackgroundColor: UIColor {
        ThemeColor.background
    }

    override var previewForegroundColor: UIColor {
        ThemeColor.textPrimary
    }

    override var previewPageIndicatorColor: UIColor {
        ThemeColor.textPrimary.withAlphaComponent(Alpha.pageIndicator)
    }

    override var previewTitleColor: UIColor {
        ThemeColor.highlight
    }

    override var previewCloseButtonBackgroundColor: UIColor {
        ThemeColor.background.withAlphaComponent(Alpha.closeButtonBackground)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}
