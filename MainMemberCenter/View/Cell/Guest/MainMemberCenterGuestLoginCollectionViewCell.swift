//
//  MainMemberCenterGuestLoginCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import SnapKit
import UIKit

// MARK: - MainMemberCenterGuestLoginCollectionViewCell

@MainActor
final class MainMemberCenterGuestLoginCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMemberCenterGuestLoginCollectionViewCell.self)

    private enum Layout {
        static let stackSpacing: CGFloat = 8
        static let iconSize: CGFloat = 40
        static let actionHeight: CGFloat = 44
        static let horizontalInset: CGFloat = 24
    }

    // MARK: - UI Components

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.textTertiary
        imageView.setContentHuggingPriority(.required, for: .vertical)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var actionButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = ThemeColor.primary
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .medium

        let button = UIButton(configuration: configuration)
        button.isUserInteractionEnabled = false
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            iconImageView,
            titleLabel,
            messageLabel,
            actionButton
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Layout.stackSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.contentStackView.alpha = self.isHighlighted ? 0.72 : 1
                self.contentStackView.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.98, y: 0.98)
                    : .identity
            }
        }
    }

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        containerView.backgroundColor = .clear
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(contentStackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
        }

        actionButton.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Layout.actionHeight)
        }

        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(Layout.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().inset(Layout.horizontalInset)
        }
    }

    override func resetForReuse() {
        iconImageView.image = nil
        titleLabel.text = nil
        messageLabel.text = nil
        actionButton.configuration?.title = nil
    }

    // MARK: - Configuration

    func configure(with prompt: MainMemberCenterGuestLoginPrompt) {
        iconImageView.image = UIImage(systemName: prompt.systemImageName)
        titleLabel.text = prompt.title
        messageLabel.text = prompt.message
        actionButton.configuration?.title = prompt.actionTitle
    }
}
