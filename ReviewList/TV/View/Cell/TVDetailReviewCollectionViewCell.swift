//
//  TVDetailReviewCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import SnapKit
import UIKit

// MARK: - TVDetailReviewCollectionViewCell

@MainActor
final class TVDetailReviewCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailReviewCollectionViewCell.self)

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 16
        static let rowSpacing: CGFloat = 8
        static let metadataSpacing: CGFloat = 8
        static let maxContentLineCount = 3
    }

    // MARK: - UI Components

    private let authorLabel = AppFactory.Label.headline()

    private let ratingLabel = AppFactory.Label.subheadline(color: ThemeColor.highlight)

    private let dateLabel = AppFactory.Label.subheadline(alignment: .right)

    private let contentLabel = AppFactory.Label.body(lines: Layout.maxContentLineCount)

    private lazy var metadataStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            ratingLabel,
            dateLabel
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.metadataSpacing
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            authorLabel,
            metadataStackView,
            contentLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Layout.rowSpacing
        return stackView
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.layer.masksToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(stackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: Layout.verticalInset,
                    left: Layout.horizontalInset,
                    bottom: Layout.verticalInset,
                    right: Layout.horizontalInset
                )
            )
        }
    }

    override func resetForReuse() {
        authorLabel.text = nil
        ratingLabel.text = nil
        dateLabel.text = nil
        contentLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with item: TVReviewDetailItem) {
        authorLabel.text = item.authorText.isEmpty ? "匿名使用者" : item.authorText
        ratingLabel.text = item.ratingText.map { "評分 \($0)" }
        ratingLabel.isHidden = item.ratingText == nil
        dateLabel.text = item.updatedDateText
        dateLabel.isHidden = item.updatedDateText == nil
        metadataStackView.isHidden = ratingLabel.isHidden && dateLabel.isHidden
        contentLabel.text = item.content
    }

    static func fittingHeight(for item: TVReviewDetailItem, width: CGFloat) -> CGFloat {
        let contentWidth = max(width - Layout.horizontalInset * 2, 0)
        let authorHeight = UIFont.preferredFont(forTextStyle: .headline).lineHeight
        let metadataHeight = metadataHeight(for: item)
        let contentHeight = contentHeight(for: item.content, width: contentWidth)
        let metadataSpacing = metadataHeight == 0 ? 0 : Layout.rowSpacing

        return Layout.verticalInset * 2
            + authorHeight
            + metadataSpacing
            + metadataHeight
            + Layout.rowSpacing
            + contentHeight
    }

    private static func metadataHeight(for item: TVReviewDetailItem) -> CGFloat {
        guard item.ratingText != nil || item.updatedDateText != nil else { return 0 }
        return UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
    }

    private static func contentHeight(for text: String, width: CGFloat) -> CGFloat {
        guard !text.isEmpty, width > 0 else { return 0 }

        let font = UIFont.preferredFont(forTextStyle: .body)
        let maxHeight = font.lineHeight * CGFloat(Layout.maxContentLineCount)
        let boundingSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let height = (text as NSString).boundingRect(
            with: boundingSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height

        return min(ceil(height), ceil(maxHeight))
    }
}
