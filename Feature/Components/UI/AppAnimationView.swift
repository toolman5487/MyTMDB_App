//
//  AppAnimationView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/15.
//

import Lottie
import SnapKit
import UIKit

// MARK: - AppAnimationView

@MainActor
final class AppAnimationView: UIView {

    // MARK: - Metrics

    enum Metrics {
        static let overlaySize: CGFloat = 160
        static let rootSize: CGFloat = 144
        static let searchSize: CGFloat = 120
        static let footerSize: CGFloat = 40
    }

    // MARK: - Properties

    private let size: CGFloat
    private var isAnimationActive: Bool

    // MARK: - UI Components

    private let animationView: LottieAnimationView

    // MARK: - Initialization

    init(
        animation: AppFactory.Animation.Kind,
        size: CGFloat,
        startsAnimating: Bool = true
    ) {
        self.size = size
        self.isAnimationActive = startsAnimating
        self.animationView = Self.makeLottieAnimationView(for: animation)
        super.init(frame: .zero)
        isHidden = !startsAnimating
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        self.size = Metrics.overlaySize
        self.isAnimationActive = true
        self.animationView = Self.makeLottieAnimationView(for: .popcornLoading)
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: size, height: size)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateAnimationPlayback()
    }

    // MARK: - Configuration

    func setAnimating(_ isAnimating: Bool) {
        isAnimationActive = isAnimating
        isHidden = !isAnimating
        updateAnimationPlayback()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(animationView)
    }

    private func setupConstraints() {
        snp.makeConstraints { make in
            make.size.equalTo(size)
        }

        animationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func updateAnimationPlayback() {
        if window != nil, isAnimationActive {
            animationView.play()
        } else {
            animationView.stop()
        }
    }

    private static func makeLottieAnimationView(
        for animation: AppFactory.Animation.Kind
    ) -> LottieAnimationView {
        let view = LottieAnimationView(name: animation.animationName)
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        return view
    }
}
