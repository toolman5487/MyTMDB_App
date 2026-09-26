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

    // MARK: - Override Points

    var containerViewInsets: UIEdgeInsets {
        .zero
    }

    // MARK: - UI Components

    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.clear
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
        resetAccessibility()
        resetForReuse()
    }

    // MARK: - Template Methods

    func configureView() {}

    func setupHierarchy() {
        contentView.addSubview(containerView)
    }

    func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(containerViewInsets)
        }
    }

    func resetForReuse() {}

    func applyAccessibility(_ accessibilityText: AccessibilityText?) {
        guard let accessibilityText else {
            resetAccessibility()
            return
        }

        isAccessibilityElement = true
        accessibilityLabel = accessibilityText.label
        accessibilityValue = accessibilityText.value
        accessibilityHint = accessibilityText.hint
        contentView.isAccessibilityElement = false
        containerView.isAccessibilityElement = false
    }

    func resetAccessibility() {
        isAccessibilityElement = false
        accessibilityLabel = nil
        accessibilityValue = nil
        accessibilityHint = nil
    }
}

// MARK: - UIView Accessibility

@MainActor
extension UIView {

    func applyAccessibilityText(_ accessibilityText: AccessibilityText?) {
        guard let accessibilityText else {
            isAccessibilityElement = false
            accessibilityLabel = nil
            accessibilityValue = nil
            accessibilityHint = nil
            return
        }

        isAccessibilityElement = true
        accessibilityLabel = accessibilityText.label
        accessibilityValue = accessibilityText.value
        accessibilityHint = accessibilityText.hint
    }
}
