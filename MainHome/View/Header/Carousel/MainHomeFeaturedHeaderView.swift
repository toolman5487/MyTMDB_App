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

    static func featuredHeight(
        for width: CGFloat,
        userInterfaceIdiom: UIUserInterfaceIdiom
    ) -> CGFloat {
        let platform = Platform(userInterfaceIdiom: userInterfaceIdiom)

        return Layout.carouselHeight(for: width, platform: platform)
            + Layout.carouselTitleSpacing
            + MainHomeSectionHeaderView.standardHeight
    }

    private enum Platform {
        case phone
        case pad

        init(userInterfaceIdiom: UIUserInterfaceIdiom) {
            switch userInterfaceIdiom {
            case .pad:
                self = .pad

            default:
                self = .phone
            }
        }

        func maximumCarouselWidth(for width: CGFloat) -> CGFloat {
            switch self {
            case .phone:
                return width

            case .pad:
                return min(width, Layout.maximumCarouselWidthForPad)
            }
        }

        func carouselWidth(for width: CGFloat) -> CGFloat {
            maximumCarouselWidth(for: width)
        }
    }

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let maximumCarouselWidthForPad: CGFloat = 720
        static let fallbackCarouselHeight: CGFloat = 224
        static let backdropAspectRatio: CGFloat = 9.0 / 16.0
        static let carouselTitleSpacing: CGFloat = 8
        static let titleTrailingSymbolName = "chevron.right.2"

        static func carouselHeight(for width: CGFloat, platform: Platform) -> CGFloat {
            guard width > 0 else { return fallbackCarouselHeight }
            let carouselWidth = platform.carouselWidth(for: width)
            return floor(carouselWidth * backdropAspectRatio)
        }
    }

    // MARK: - Properties

    var onCarouselSelected: ((MainHomeContentItem) -> Void)?
    var onTitleTapped: (() -> Void)?

    // MARK: - UI Components

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Layout.carouselTitleSpacing
        return stackView
    }()

    private let carouselView = MainHomeCarouselView()

    private let titleLabel = AppFactory.Label.sectionTitle(color: ThemeColor.highlight)

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
            let platform = Platform(userInterfaceIdiom: traitCollection.userInterfaceIdiom)

            make.width.lessThanOrEqualToSuperview()
            switch platform {
            case .phone:
                break

            case .pad:
                make.width.lessThanOrEqualTo(Layout.maximumCarouselWidthForPad)
            }
            make.width.equalToSuperview().priority(.high)
            make.height.equalTo(carouselView.snp.width).multipliedBy(Layout.backdropAspectRatio)
        }

        titleRowStackView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(MainHomeSectionHeaderView.standardHeight)
        }
    }

    // MARK: - Configuration

    func configure(title: String?, carouselItems: [MainHomeContentItem] = []) {
        let font = titleLabel.font ?? .preferredFont(forTextStyle: .title3)
        let trailingImage = UIImage(
            systemName: Layout.titleTrailingSymbolName,
            withConfiguration: UIImage.SymbolConfiguration(font: font, scale: .small)
        )

        titleLabel.attributedText = MainHomeSectionTitleAttributedStringFactory.make(
            title: title,
            trailingImage: trailingImage,
            font: font,
            textColor: ThemeColor.highlight
        )
        carouselView.configure(items: carouselItems)
        carouselView.onItemSelected = { [weak self] item in
            self?.onCarouselSelected?(item)
        }
    }

    @objc private func handleTitleTap() {
        onTitleTapped?()
    }
}
