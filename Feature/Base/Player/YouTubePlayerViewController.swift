//
//  YouTubePlayerViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import SnapKit
import UIKit
@preconcurrency import YouTubeiOSPlayerHelper

// MARK: - YouTubePlayerViewController

@MainActor
final class YouTubePlayerViewController: BaseViewController {

    // MARK: - Properties

    private let videoKey: String
    private let preferredTitle: String?

    // MARK: - UI Components

    private lazy var playerView: YTPlayerView = {
        let playerView = YTPlayerView()
        playerView.backgroundColor = ThemeColor.background
        playerView.delegate = self
        return playerView
    }()

    // MARK: - Initialization

    init(
        videoKey: String,
        title: String? = nil,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.videoKey = videoKey
        self.preferredTitle = title
        super.init(nibName: nil, bundle: nil)
        setInterfaceLocalization(interfaceLocalization)
    }

    required init?(coder: NSCoder) {
        self.videoKey = ""
        self.preferredTitle = nil
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            playerView.stopVideo()
        }
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        title = preferredTitle ?? interfaceLocalization.string(
            "player.fallback_title",
            defaultValue: "Trailer"
        )
        view.accessibilityViewIsModal = true
        navigationItem.largeTitleDisplayMode = .never
        let closeButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(handleCloseButtonTapped)
        )
        closeButtonItem.accessibilityLabel = interfaceLocalization.string(
            "common.action.close",
            defaultValue: "Close"
        )
        closeButtonItem.accessibilityHint = interfaceLocalization.string(
            "player.close.accessibility_hint",
            defaultValue: "Double-tap to close the video player"
        )
        navigationItem.rightBarButtonItem = closeButtonItem

        playerView.isAccessibilityElement = false
        playerView.accessibilityLabel = interfaceLocalization.string(
            "player.accessibility_label",
            defaultValue: "Video Player"
        )
        playerView.accessibilityHint = interfaceLocalization.string(
            "player.accessibility_hint",
            defaultValue: "Use the player controls to play, pause, or adjust the video"
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIAccessibility.post(notification: .screenChanged, argument: title)
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(playerView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        playerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(playerView.snp.width).multipliedBy(9.0 / 16.0)
        }
    }

    override func bindViewModel() {
        playerView.load(
            withVideoId: videoKey,
            playerVars: [
                "playsinline": 1,
                "modestbranding": 1,
                "rel": 0
            ]
        )
    }

    // MARK: - Actions

    @objc private func handleCloseButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - YTPlayerViewDelegate

extension YouTubePlayerViewController: YTPlayerViewDelegate {

    nonisolated func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        Task(priority: .userInitiated) { @MainActor [weak self] in
            self?.handlePlayerError()
        }
    }

    private func handlePlayerError() {
        presentAlert(
            title: interfaceLocalization.string(
                "player.error.title",
                defaultValue: "Unable to Play Video"
            ),
            message: interfaceLocalization.string(
                "player.error.message",
                defaultValue: "Try again later, or choose another trailer."
            )
        )
    }
}
