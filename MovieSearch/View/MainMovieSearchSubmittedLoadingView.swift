//
//  MainMovieSearchSubmittedLoadingView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SnapKit
import UIKit

// MARK: - MainMovieSearchSubmittedLoadingView

@MainActor
final class MainMovieSearchSubmittedLoadingView: UIView {

    private let animationView = AppFactory.Animation.searchLoading(size: AppAnimationView.Metrics.searchSize)

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.headline(alignment: .center, lines: 0)
        label.text = "正在搜尋"
        return label
    }()

    private let messageLabel = AppFactory.Label.subheadline(alignment: .center, lines: 0)

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            animationView,
            titleLabel,
            messageLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    init(keyword: String) {
        super.init(frame: .zero)
        messageLabel.text = "正在搜尋「\(keyword)」"
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }
    }
}
