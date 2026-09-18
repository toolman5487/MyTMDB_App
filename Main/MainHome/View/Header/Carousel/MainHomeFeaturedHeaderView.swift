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
final class MainHomeFeaturedHeaderView: MainHomeSectionHeaderView {

    // MARK: - Constants

    static func featuredHeight(
        for width: CGFloat,
        userInterfaceIdiom: UIUserInterfaceIdiom
    ) -> CGFloat {
        let platform = Platform(userInterfaceIdiom: userInterfaceIdiom)

        return Layout.carouselHeight(for: width, platform: platform)
            + Layout.carouselTitleSpacing
            + SectionHeaderLayoutMetrics.height
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
        static let maximumCarouselWidthForPad: CGFloat = 720
        static let fallbackCarouselHeight: CGFloat = 224
        static let backdropAspectRatio: CGFloat = 9.0 / 16.0
        static let carouselTitleSpacing: CGFloat = 8

        static func carouselHeight(for width: CGFloat, platform: Platform) -> CGFloat {
            guard width > 0 else { return fallbackCarouselHeight }
            let carouselWidth = platform.carouselWidth(for: width)
            return floor(carouselWidth * backdropAspectRatio)
        }
    }

    // MARK: - Properties

    var onCarouselSelected: ((HomeContentItem) -> Void)?

    // MARK: - UI Components

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Layout.carouselTitleSpacing
        return stackView
    }()

    private let carouselView = MainHomeCarouselView()

    // MARK: - Setup

    override func setupHierarchy() {
        super.setupHierarchy()
        addSubview(stackView)
        stackView.addArrangedSubview(carouselView)
    }

    override func placeTitleRow() {
        stackView.addArrangedSubview(titleRowView)
        titleRowView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(SectionHeaderLayoutMetrics.height)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

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
    }

    override func resetForReuse() {
        super.resetForReuse()
        carouselView.configure(items: [])
        onCarouselSelected = nil
    }

    // MARK: - Configuration

    func configure(
        title: String?,
        carouselItems: [HomeContentItem],
        onTitleTap: (() -> Void)?
    ) {
        configure(title: title, onTitleTap: onTitleTap)
        carouselView.configure(items: carouselItems)
        carouselView.onItemSelected = { [weak self] item in
            self?.onCarouselSelected?(item)
        }
    }
}
