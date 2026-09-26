//
//  CompanyLogoImagePreviewViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/26.
//

import UIKit

// MARK: - CompanyLogoImagePreviewViewController

@MainActor
final class CompanyLogoImagePreviewViewController: DetailImagePreviewViewController {

    override var previewBackgroundColor: UIColor {
        .label
    }

    override var previewForegroundColor: UIColor {
        .systemBackground
    }
}
