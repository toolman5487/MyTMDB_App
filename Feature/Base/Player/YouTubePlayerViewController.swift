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

    private lazy var playerView: YTPlayerView = {
        let playerView = YTPlayerView()
        playerView.backgroundColor = .black
        playerView.delegate = self
        return playerView
    }()

    // MARK: - Initialization

    init(videoKey: String, title: String? = nil) {
        self.videoKey = videoKey
        self.preferredTitle = title
        super.init(nibName: nil, bundle: nil)
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
        title = preferredTitle ?? "預告片"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(handleCloseButtonTapped)
        )
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
            title: "無法播放影片",
            message: "請稍後再試，或改用其他預告片。"
        )
    }
}
