//
//  MainHomeFeaturedHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import SnapKit
import UIKit

// MARK: - MainHomeFeaturedHeaderView

@MainActor
final class MainHomeFeaturedHeaderView: UICollectionReusableView {

    // MARK: - Constants

    static let reuseIdentifier = String(describing: MainHomeFeaturedHeaderView.self)
    static let featuredHeight: CGFloat = 264

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let carouselHeight: CGFloat = 224
        static let carouselTitleSpacing: CGFloat = 8
        static let titleTrailingSymbolName = "chevron.right.2"
    }

    // MARK: - Properties

    var onCarouselSelected: ((MainHomeContentItem) -> Void)?
    var onTitleTapped: (() -> Void)?

    // MARK: - UI Components

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.carouselTitleSpacing
        return stackView
    }()

    private let carouselView = MainHomeCarouselView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        return label
    }()

    private let titleRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: Layout.horizontalInset,
            bottom: 0,
            trailing: Layout.horizontalInset
        )
        return stackView
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
        titleLabel.text = nil
        titleLabel.attributedText = nil
        carouselView.configure(items: [])
        onCarouselSelected = nil
        onTitleTapped = nil
    }

    // MARK: - Setup

    private func configureView() {
        backgroundColor = .clear
        titleRowStackView.isUserInteractionEnabled = true
        titleRowStackView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTitleTap))
        )
    }

    private func setupHierarchy() {
        addSubview(stackView)
        stackView.addArrangedSubview(carouselView)
        stackView.addArrangedSubview(titleRowStackView)
        titleRowStackView.addArrangedSubview(titleLabel)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        carouselView.snp.makeConstraints { make in
            make.height.equalTo(Layout.carouselHeight)
        }

        titleRowStackView.snp.makeConstraints { make in
            make.height.equalTo(MainHomeSectionHeaderView.standardHeight)
        }
    }

    // MARK: - Configuration

    func configure(title: String?, carouselItems: [MainHomeContentItem] = []) {
        let font = titleLabel.font ?? .preferredFont(forTextStyle: .title3)
        titleLabel.attributedText = MainHomeSectionTitleAttributedStringFactory.make(
            title: title,
            trailingImage: Self.makeTitleTrailingImage(font: font),
            font: font
        )
        carouselView.configure(items: carouselItems)
        carouselView.onItemSelected = { [weak self] item in
            self?.onCarouselSelected?(item)
        }
    }

    private static func makeTitleTrailingImage(font: UIFont) -> UIImage? {
        UIImage(
            systemName: Layout.titleTrailingSymbolName,
            withConfiguration: UIImage.SymbolConfiguration(font: font, scale: .small)
        )
    }

    @objc private func handleTitleTap() {
        onTitleTapped?()
    }
}
