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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        animationView.isAccessibilityElement = false
        applyAccessibilityText(
            AccessibilityText(
                label: "搜尋中",
                value: "正在輸入關鍵字"
            )
        )
        accessibilityTraits.insert(.updatesFrequently)
    }
}
