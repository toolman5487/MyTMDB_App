//
//  MainMemberCenterMenuItemCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import SnapKit
import UIKit

// MARK: - MainMemberCenterMenuItemCollectionViewCell

@MainActor
final class MainMemberCenterMenuItemCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMemberCenterMenuItemCollectionViewCell.self)

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 12
        static let contentSpacing: CGFloat = 12
        static let iconContainerSize: CGFloat = 36
        static let cornerRadius: CGFloat = 8
    }

    // MARK: - UI Components

    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.primary.withAlphaComponent(0.16)
        view.layer.cornerRadius = Layout.iconContainerSize / 2
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.primary
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let accessoryImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.textTertiary
        return imageView
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = Layout.cornerRadius
        containerView.layer.masksToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(accessoryImageView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        iconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Layout.horizontalInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.iconContainerSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        accessoryImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainerView.snp.trailing).offset(Layout.contentSpacing)
            make.trailing.lessThanOrEqualTo(accessoryImageView.snp.leading).offset(-Layout.contentSpacing)
            make.top.equalToSuperview().offset(Layout.verticalInset)
            make.bottom.equalToSuperview().inset(Layout.verticalInset)
            make.centerY.equalToSuperview()
        }
    }

    override func resetForReuse() {
        iconImageView.image = nil
        titleLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with item: MainMemberCenterMenuItem) {
        iconImageView.image = UIImage(systemName: item.systemImageName)
        titleLabel.text = item.title
    }
}
