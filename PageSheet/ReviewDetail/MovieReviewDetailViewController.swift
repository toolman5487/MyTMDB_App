//
//  MovieReviewDetailViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SDWebImage
import SnapKit
import UIKit

@MainActor
final class MovieReviewDetailViewController: GlassBaseViewController {

    // MARK: - Properties

    private let review: MovieDetailReviewItem
    private let navigationTitle: String
    private var isShowingCompactTitle = false

    // MARK: - Layout

    private enum Layout {
        static let estimatedContainerHeight: CGFloat = 280
    }

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderTopPadding = 0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Layout.estimatedContainerHeight
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            MovieReviewDetailContainerTableViewCell.self,
            forCellReuseIdentifier: MovieReviewDetailContainerTableViewCell.reuseIdentifier
        )
        return tableView
    }()

    private lazy var compactTitleView = MovieReviewDetailNavigationTitleView()

    // MARK: - Initialization

    init(review: MovieDetailReviewItem, title: String = "評論") {
        self.review = review
        self.navigationTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        isShowingCompactTitle = false
        applyNavigationTitle(compact: false)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshNavigationTitle()
    }

    // MARK: - Actions

    @objc private func handleCloseButtonTapped() {
        dismiss(animated: true)
    }

    private func applyNavigationTitle(compact: Bool) {
        if compact {
            compactTitleView.configure(with: review)
            navigationItem.titleView = compactTitleView
            navigationItem.title = nil
        } else {
            navigationItem.titleView = nil
            navigationItem.title = navigationTitle
        }
    }

    private func refreshNavigationTitle() {
        applyNavigationTitle(compact: isShowingCompactTitle)
    }

    private func updateNavigationTitle(compact: Bool) {
        guard isShowingCompactTitle != compact else { return }
        isShowingCompactTitle = compact
        applyNavigationTitle(compact: compact)
    }

    private func updateNavigationTitleForScroll() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
            as? MovieReviewDetailContainerTableViewCell else {
            return
        }

        let scrollableHeight = tableView.contentSize.height
            - tableView.bounds.height
            + tableView.adjustedContentInset.top
            + tableView.adjustedContentInset.bottom
        guard scrollableHeight > 1 else {
            updateNavigationTitle(compact: false)
            return
        }

        updateNavigationTitle(compact: cell.isAuthorRowScrolledOff(in: tableView))
    }
}

// MARK: - UITableViewDataSource

extension MovieReviewDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MovieReviewDetailContainerTableViewCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? MovieReviewDetailContainerTableViewCell)?.configure(with: review)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MovieReviewDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        Layout.estimatedContainerHeight
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard tableView.isDragging || tableView.isDecelerating else { return }
        updateNavigationTitleForScroll()
    }
}

// MARK: - MovieReviewDetailContainerTableViewCell

@MainActor
private final class MovieReviewDetailContainerTableViewCell: UITableViewCell {

    static let reuseIdentifier = String(describing: MovieReviewDetailContainerTableViewCell.self)

    // MARK: - Layout

    private enum Layout {
        static let contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let contentSpacing: CGFloat = 12
    }

    // MARK: - UI Components

    private let glassBackgroundView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: nil)
        view.backgroundColor = .clear
        return view
    }()

    private let authorView = MovieReviewDetailAuthorView()
    private let reviewContentView = MovieReviewDetailContentView()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            authorView,
            reviewContentView
        ])
        stackView.axis = .vertical
        stackView.spacing = Layout.contentSpacing
        return stackView
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        backgroundConfiguration = .clear()
        glassBackgroundView.effect = GlassBackgroundEffect.make()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        authorView.prepareForReuse()
        reviewContentView.prepareForReuse()
    }

    // MARK: - Configuration

    func configure(with review: MovieDetailReviewItem) {
        authorView.configure(with: review)
        reviewContentView.configure(content: review.content)
    }

    func isAuthorRowScrolledOff(in tableView: UITableView) -> Bool {
        guard let containerIndexPath = tableView.indexPath(for: self) else { return false }
        contentView.layoutIfNeeded()

        let cellFrame = tableView.rectForRow(at: containerIndexPath)
        guard cellFrame.height > 0 else { return false }

        let authorBottomY = cellFrame.minY + Layout.contentInset.top + authorView.frame.maxY
        let visibleTop = tableView.contentOffset.y + tableView.adjustedContentInset.top

        return authorBottomY <= visibleTop
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

        contentStackView.snp.makeConstraints { make in
            make.edges.equalTo(glassBackgroundView).inset(Layout.contentInset)
        }
    }
}

// MARK: - MovieReviewDetailAuthorView

@MainActor
private final class MovieReviewDetailAuthorView: UIView {

    // MARK: - Layout

    private enum Layout {
        static let avatarSize: CGFloat = 44
        static let headerSpacing: CGFloat = 12
    }

    // MARK: - UI Components

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.avatarSize / 2
        return imageView
    }()

    private let authorLabel = AppFactory.Label.headline(lines: 0)

    private let dateLabel = AppFactory.Label.subheadline(alignment: .right)

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func prepareForReuse() {
        avatarImageView.sd_cancelCurrentImageLoad()
        avatarImageView.image = nil
        avatarImageView.isHidden = false
        authorLabel.text = nil
        dateLabel.text = nil
        dateLabel.isHidden = false
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(contentStackView)
    }

    private func setupConstraints() {
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.avatarSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
}

// MARK: - MovieReviewDetailContentView

@MainActor
private final class MovieReviewDetailContentView: UIView {

    // MARK: - Layout

    private enum Layout {
        static let bodyLineSpacing: CGFloat = 4
    }

    // MARK: - UI Components

    private let contentLabel = AppFactory.Label.body(color: ThemeColor.textPrimary, lines: 0)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func prepareForReuse() {
        contentLabel.text = nil
        contentLabel.attributedText = nil
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(contentLabel)
    }

    private func setupConstraints() {
        contentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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

// MARK: - MovieReviewDetailNavigationTitleView

@MainActor
private final class MovieReviewDetailNavigationTitleView: UIView {

    // MARK: - Layout

    private enum Layout {
        static let avatarSize: CGFloat = 20
        static let spacing: CGFloat = 6
        static let maxWidth: CGFloat = 240
    }

    // MARK: - UI Components

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.avatarSize / 2
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = AppFactory.Label.subheadline(color: ThemeColor.textPrimary)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let ratingLabel: UILabel = {
        let label = AppFactory.Label.subheadline(color: ThemeColor.highlight)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            avatarImageView,
            nameLabel,
            ratingLabel
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.spacing
        return stackView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        let fittingSize = contentStackView.systemLayoutSizeFitting(
            CGSize(width: Layout.maxWidth, height: UIView.noIntrinsicMetric),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(
            width: min(fittingSize.width, Layout.maxWidth),
            height: fittingSize.height
        )
    }

    // MARK: - Configuration

    func configure(with item: MovieDetailReviewItem) {
        nameLabel.text = item.authorText.isEmpty ? "匿名使用者" : item.authorText
        ratingLabel.text = item.ratingText.map { "評分 \($0)" }
        ratingLabel.isHidden = item.ratingText == nil

        if let avatarURL = item.avatarURL {
            avatarImageView.isHidden = false
            avatarImageView.sd_setImage(with: avatarURL)
        } else {
            avatarImageView.isHidden = true
            avatarImageView.sd_cancelCurrentImageLoad()
            avatarImageView.image = nil
        }

        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(contentStackView)
    }

    private func setupConstraints() {
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.avatarSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.leading.trailing.centerY.equalToSuperview()
        }

        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
}
