//
//  MainMovieSearchTypingLoadingView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Lottie
import SnapKit
import UIKit

// MARK: - MainMovieSearchTypingLoadingView

@MainActor
final class MainMovieSearchTypingLoadingView: UIView {

    private enum Layout {
        static let animationSize: CGFloat = 200
    }

    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "loadingAnimation_blue")
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        return view
    }()

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
