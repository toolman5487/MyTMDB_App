//
//  MemberSettingButtonCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import SnapKit
import UIKit

// MARK: - MemberSettingButtonCollectionViewCell

@MainActor
class MemberSettingButtonCollectionViewCell: BaseCollectionViewCell {

    // MARK: - UI Components

    private let buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.systemRed
        view.layer.cornerRadius = 8
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            iconImageView,
            titleLabel
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.buttonContainerView.alpha = self.isHighlighted ? 0.72 : 1
                self.buttonContainerView.transform = self.isHighlighted
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
        containerView.addSubview(buttonContainerView)
        buttonContainerView.addSubview(contentStackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        buttonContainerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(20)
        }

        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    override func resetForReuse() {
        titleLabel.text = nil
        iconImageView.image = nil
        accessibilityLabel = nil
        accessibilityTraits = []
    }

    // MARK: - Configuration

    func configure(with item: MemberSettingRowItem) {
        titleLabel.text = item.title
        iconImageView.image = UIImage(systemName: item.systemImageName)
        accessibilityLabel = item.title
        accessibilityTraits = [.button]
    }
}
