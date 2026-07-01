//
//  MovieDetailReviewDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SDWebImage
import SnapKit
import UIKit

@MainActor
final class MovieDetailReviewDetailViewController: GlassBaseViewController {

    // MARK: - Properties

    private let review: MovieDetailReviewItem

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let sectionBottomInset: CGFloat = 24
        static let estimatedHeaderHeight: CGFloat = 88
        static let estimatedRowHeight: CGFloat = 200
    }

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderTopPadding = 0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = Layout.estimatedHeaderHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Layout.estimatedRowHeight
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            MovieDetailReviewDetailTableViewCell.self,
            forCellReuseIdentifier: MovieDetailReviewDetailTableViewCell.reuseIdentifier
        )
        tableView.register(
            MovieDetailReviewDetailSectionHeaderView.self,
            forHeaderFooterViewReuseIdentifier: MovieDetailReviewDetailSectionHeaderView.reuseIdentifier
        )
        return tableView
    }()

    // MARK: - Initialization

    init(review: MovieDetailReviewItem) {
        self.review = review
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        title = "評論"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(handleCloseButtonTapped)
        )
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(tableView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func handleCloseButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension MovieDetailReviewDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MovieDetailReviewDetailTableViewCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? MovieDetailReviewDetailTableViewCell)?.configure(content: review.content)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MovieDetailReviewDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: MovieDetailReviewDetailSectionHeaderView.reuseIdentifier
        )
        (headerView as? MovieDetailReviewDetailSectionHeaderView)?.configure(with: review)
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        Layout.sectionBottomInset
    }
}

// MARK: - MovieDetailReviewDetailSectionHeaderView

@MainActor
private final class MovieDetailReviewDetailSectionHeaderView: UITableViewHeaderFooterView {

    static let reuseIdentifier = String(describing: MovieDetailReviewDetailSectionHeaderView.self)

    // MARK: - Layout

    private enum Layout {
        static let contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 12, right: 16)
        static let avatarSize: CGFloat = 44
        static let headerSpacing: CGFloat = 12
    }

    // MARK: - UI Components

    private let glassBackgroundView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: nil)
        view.backgroundColor = .clear
        return view
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.avatarSize / 2
        return imageView
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 0
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    private lazy var leadingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            avatarImageView,
            authorLabel
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.headerSpacing
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            leadingStackView,
            dateLabel
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.headerSpacing
        return stackView
    }()

    // MARK: - Initialization

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        glassBackgroundView.effect = Self.makeGlassBackgroundEffect()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.sd_cancelCurrentImageLoad()
        avatarImageView.image = nil
        avatarImageView.isHidden = false
        authorLabel.text = nil
        dateLabel.text = nil
        dateLabel.isHidden = false
    }

    // MARK: - Setup

    private func setupHierarchy() {
        contentView.addSubview(glassBackgroundView)
        contentView.addSubview(contentStackView)
    }

    private func setupConstraints() {
        glassBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.avatarSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.contentInset)
        }

        authorLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leadingStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    // MARK: - Configuration

    func configure(with item: MovieDetailReviewItem) {
        authorLabel.text = item.authorText.isEmpty ? "匿名使用者" : item.authorText
        dateLabel.text = item.updatedDateText
        dateLabel.isHidden = item.updatedDateText == nil

        if let avatarURL = item.avatarURL {
            avatarImageView.isHidden = false
            avatarImageView.sd_setImage(with: avatarURL)
        } else {
            avatarImageView.isHidden = true
            avatarImageView.image = nil
        }
    }

    private static func makeGlassBackgroundEffect() -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            effect.tintColor = ThemeColor.background.withAlphaComponent(0.18)
            effect.isInteractive = false
            return effect
        }

        return UIBlurEffect(style: .systemUltraThinMaterial)
    }
}

// MARK: - MovieDetailReviewDetailTableViewCell

@MainActor
private final class MovieDetailReviewDetailTableViewCell: UITableViewCell {

    static let reuseIdentifier = String(describing: MovieDetailReviewDetailTableViewCell.self)

    // MARK: - Layout

    private enum Layout {
        static let contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let bodyLineSpacing: CGFloat = 4
    }

    // MARK: - UI Components

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentLabel.text = nil
        contentLabel.attributedText = nil
    }

    // MARK: - Setup

    private func setupHierarchy() {
        contentView.addSubview(contentLabel)
    }

    private func setupConstraints() {
        contentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.contentInset)
        }
    }

    // MARK: - Configuration

    func configure(content: String) {
        contentLabel.attributedText = Self.makeContentAttributedText(content)
    }

    private static func makeContentAttributedText(_ content: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Layout.bodyLineSpacing

        return NSAttributedString(
            string: content,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: ThemeColor.textPrimary,
                .paragraphStyle: paragraphStyle
            ]
        )
    }
}
