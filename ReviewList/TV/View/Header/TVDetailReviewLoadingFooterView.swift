//
//  TVDetailReviewLoadingFooterView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import SnapKit
import UIKit

// MARK: - TVDetailReviewLoadingFooterView

@MainActor
final class TVDetailReviewLoadingFooterView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: TVDetailReviewLoadingFooterView.self)

    // MARK: - UI Components

    private let indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.color = ThemeColor.primary
        indicatorView.hidesWhenStopped = true
        return indicatorView
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
        indicatorView.stopAnimating()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(indicatorView)
    }

    private func setupConstraints() {
        indicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(isAnimating: Bool) {
        if isAnimating {
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
        }
    }
}
