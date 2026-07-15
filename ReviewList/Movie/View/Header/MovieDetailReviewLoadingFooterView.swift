//
//  MovieDetailReviewLoadingFooterView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SnapKit
import UIKit

// MARK: - MovieDetailReviewLoadingFooterView

@MainActor
final class MovieDetailReviewLoadingFooterView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: MovieDetailReviewLoadingFooterView.self)

    // MARK: - UI Components

    private let loadingView = {
        AppFactory.Animation.popcornLoading(
            size: AppAnimationView.Metrics.footerSize,
            startsAnimating: false
        )
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadingView.setAnimating(false)
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(loadingView)
    }

    private func setupConstraints() {
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(isAnimating: Bool) {
        loadingView.setAnimating(isAnimating)
    }
}
