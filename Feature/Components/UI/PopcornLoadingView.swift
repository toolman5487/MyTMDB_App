//
//  PopcornLoadingView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/15.
//

import SnapKit
import UIKit

// MARK: - PopcornLoadingView

@MainActor
final class PopcornLoadingView: UIView {

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

    private let animationView = AppFactory.Animation.popcornLoading()

    // MARK: - Initialization

    init(size: CGFloat, startsAnimating: Bool = true) {
        self.size = size
        self.isAnimationActive = startsAnimating
        super.init(frame: .zero)
        isHidden = !startsAnimating
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        self.size = Metrics.overlaySize
        self.isAnimationActive = true
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
}
