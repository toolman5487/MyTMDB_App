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
        .label
    }

    override var previewForegroundColor: UIColor {
        .systemBackground
    }

    override var previewPageIndicatorColor: UIColor {
        UIColor.systemBackground.withAlphaComponent(Alpha.pageIndicator)
    }

    override var previewTitleColor: UIColor {
        ThemeColor.highlight
    }

    override var previewCloseButtonBackgroundColor: UIColor {
        UIColor.label.withAlphaComponent(Alpha.closeButtonBackground)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }
}
