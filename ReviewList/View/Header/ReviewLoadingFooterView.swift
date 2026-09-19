//
//  ReviewLoadingFooterView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SnapKit
import UIKit

// MARK: - ReviewLoadingFooterView

@MainActor
final class ReviewLoadingFooterView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: ReviewLoadingFooterView.self)

    // MARK: - UI Components

    private let loadingView = {
        AppFactory.Animation.popcornLoading(
            size: AppAnimationView.Metrics.footerSize,
            startsAnimating: false
        )
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
        accessibilityTraits.insert(.updatesFrequently)
        loadingView.isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
        accessibilityTraits.insert(.updatesFrequently)
        loadingView.isAccessibilityElement = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadingView.setAnimating(false)
        applyAccessibilityText(nil)
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(loadingView)
    }

    private func setupConstraints() {
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(
        isAnimating: Bool,
        localization: AppInterfaceLocalization
    ) {
        loadingView.setAnimating(isAnimating)
        applyAccessibilityText(
            isAnimating
                ? AccessibilityText(
                    label: localization.string(
                        "review_list.loading_more.accessibility_label",
                        defaultValue: "Loading more reviews"
                    )
                )
                : nil
        )
    }
}
