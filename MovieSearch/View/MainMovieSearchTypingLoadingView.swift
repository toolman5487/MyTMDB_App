//
//  MainMovieSearchTypingLoadingView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SnapKit
import UIKit

// MARK: - MainMovieSearchTypingLoadingView

@MainActor
final class MainMovieSearchTypingLoadingView: UIView {

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
    }
}
