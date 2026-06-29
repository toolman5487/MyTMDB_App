//
//  BaseCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import SnapKit
import UIKit

// MARK: - BaseCollectionViewCell

@MainActor
class BaseCollectionViewCell: UICollectionViewCell {

    // MARK: - UI Components

    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        resetForReuse()
    }

    // MARK: - Template Methods

    func configureView() {}

    func setupHierarchy() {
        contentView.addSubview(containerView)
    }

    func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func resetForReuse() {}
}
