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

    // MARK: - Layout

    private enum Layout {
        static let messageTopSpacing: CGFloat = 4
    }

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
    private let message: String?

    // MARK: - UI Components

    private let animationView: LottieAnimationView

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            animationView,
            messageLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Layout.messageTopSpacing
        return stackView
    }()

    // MARK: - Initialization

    init(
        animation: AppFactory.Animation.Kind,
        size: CGFloat,
        message: String? = nil,
        startsAnimating: Bool = true
    ) {
        self.size = size
        self.message = message
        self.isAnimationActive = startsAnimating
        self.animationView = Self.makeLottieAnimationView(for: animation)
        super.init(frame: .zero)
        isHidden = !startsAnimating
        configureMessage()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        self.size = Metrics.overlaySize
        self.message = nil
        self.isAnimationActive = true
        self.animationView = Self.makeLottieAnimationView(for: .popcornLoading)
        super.init(coder: coder)
        configureMessage()
        setupHierarchy()
        setupConstraints()
    }

    override var intrinsicContentSize: CGSize {
        guard messageLabel.isHidden == false else {
            return CGSize(width: size, height: size)
        }

        let messageSize = messageLabel.intrinsicContentSize
        return CGSize(
            width: max(size, messageSize.width),
            height: size + Layout.messageTopSpacing + messageSize.height
        )
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
        addSubview(contentStackView)
    }

    private func setupConstraints() {
        animationView.snp.makeConstraints { make in
            make.size.equalTo(size)
        }

        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.edges.lessThanOrEqualToSuperview()
        }
    }

    private func configureMessage() {
        guard let trimmedMessage = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedMessage.isEmpty else {
            messageLabel.text = nil
            messageLabel.isHidden = true
            return
        }

        messageLabel.text = trimmedMessage
        messageLabel.isHidden = false
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
