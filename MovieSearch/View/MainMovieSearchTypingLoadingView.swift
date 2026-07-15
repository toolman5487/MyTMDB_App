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

    private let animationView = AppFactory.Animation.searchLoading()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == nil {
            animationView.stop()
        } else {
            animationView.play()
        }
    }

    private func setupUI() {
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Layout.animationSize)
        }
    }
}
