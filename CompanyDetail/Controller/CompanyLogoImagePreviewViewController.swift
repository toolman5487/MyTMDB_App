//
//  CompanyLogoImagePreviewViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/26.
//

import UIKit

// MARK: - CompanyLogoImagePreviewViewController

@MainActor
final class CompanyLogoImagePreviewViewController: BaseImagePreviewViewController {

    // MARK: - Alpha

    private enum Alpha {
        static let pageIndicator: CGFloat = 0.32
        static let closeButtonBackground: CGFloat = 0.48
    }

    // MARK: - Style

    override var previewBackgroundColor: UIColor {
        ThemeColor.backgroundInverted
    }

    override var previewForegroundColor: UIColor {
        ThemeColor.textInverted
    }

    override var previewPageIndicatorColor: UIColor {
        ThemeColor.textInverted.withAlphaComponent(Alpha.pageIndicator)
    }

    override var previewTitleColor: UIColor {
        ThemeColor.highlight
    }

    override var previewCloseButtonBackgroundColor: UIColor {
        ThemeColor.backgroundInverted.withAlphaComponent(Alpha.closeButtonBackground)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }
}
