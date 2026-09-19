//
//  SearchTypingLoadingView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SnapKit
import UIKit

// MARK: - SearchTypingLoadingView

@MainActor
final class SearchTypingLoadingView: UIView {

    private enum Layout {
        static let animationSize: CGFloat = 200
    }

    private let animationView = AppFactory.Animation.searchLoading(size: Layout.animationSize)
    private let localization: AppInterfaceLocalization

    init(
        localization: AppInterfaceLocalization,
        frame: CGRect = .zero
    ) {
        self.localization = localization
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        animationView.isAccessibilityElement = false
        applyAccessibilityText(
            AccessibilityText(
                label: localization.string("search.typing.label", defaultValue: "Searching"),
                value: localization.string(
                    "search.typing.value",
                    defaultValue: "Entering a keyword"
                )
            )
        )
        accessibilityTraits.insert(.updatesFrequently)
    }
}
