//
//  MainHomeSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import SnapKit
import UIKit

// MARK: - MainHomeSectionHeaderView

@MainActor
final class MainHomeSectionHeaderView: UICollectionReusableView {

    // MARK: - Constants

    static let reuseIdentifier = String(describing: MainHomeSectionHeaderView.self)
    static let standardHeight: CGFloat = 32
    static let featuredHeight: CGFloat = 264

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let carouselHeight: CGFloat = 224
        static let carouselTitleSpacing: CGFloat = 8
    }

    // MARK: - Properties

    var onCarouselSelected: ((MainHomeContentItem) -> Void)?

    // MARK: - UI Components

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.carouselTitleSpacing
        return stackView
    }()

    private let carouselView = MainHomeCarouselView()
    private let titleContainerView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        return label
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
        configure(title: nil, carouselItems: [])
        onCarouselSelected = nil
    }

    // MARK: - Setup

    private func configureView() {
        backgroundColor = .clear
    }

    private func setupHierarchy() {
        addSubview(stackView)
        stackView.addArrangedSubview(carouselView)
        stackView.addArrangedSubview(titleContainerView)
        titleContainerView.addSubview(titleLabel)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        carouselView.snp.makeConstraints { make in
            make.height.equalTo(Layout.carouselHeight)
        }

        titleContainerView.snp.makeConstraints { make in
            make.height.equalTo(Self.standardHeight)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
        }
    }

    // MARK: - Configuration

    func configure(title: String?, carouselItems: [MainHomeContentItem] = []) {
        titleLabel.text = title
        carouselView.configure(items: carouselItems)
        carouselView.onItemSelected = { [weak self] item in
            self?.onCarouselSelected?(item)
        }
    }
}
