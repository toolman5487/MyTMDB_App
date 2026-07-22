//
//  DetailBottomActionBarView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/14.
//

import SnapKit
import UIKit

@MainActor
final class DetailBottomActionBarView: UIView {

    // MARK: - Metrics

    enum Metrics {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 12
        static let buttonSpacing: CGFloat = 12
        static let buttonHeight: CGFloat = 48
        static let separatorHeight: CGFloat = 1
    }

    // MARK: - Properties

    private var favoriteButtonWidthConstraint: Constraint?
    private var ratingMatchesReviewWidthConstraint: Constraint?
    private var isFavoriteActionVisible = true
    private var isRatingActionVisible = true
    private var isReviewActionVisible = true

    // MARK: - UI Components

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.separator
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            favoriteButton,
            ratingButton,
            reviewButton
        ])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = Metrics.buttonSpacing
        return stackView
    }()

    private lazy var favoriteButton: UIButton = {
        UIButton(configuration: favoriteButtonConfiguration(isFavorite: false))
    }()

    private lazy var ratingButton: UIButton = {
        UIButton(configuration: ratingButtonConfiguration(value: nil))
    }()

    private lazy var reviewButton: UIButton = {
        UIButton(configuration: reviewButtonConfiguration())
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

    // MARK: - Configuration

    func configureFavorite(isFavorite: Bool, isEnabled: Bool) {
        favoriteButton.configuration = favoriteButtonConfiguration(isFavorite: isFavorite)
        favoriteButton.isEnabled = isEnabled
    }

    func configureRating(value: Double?, isEnabled: Bool) {
        ratingButton.configuration = ratingButtonConfiguration(value: value)
        ratingButton.isEnabled = isEnabled
    }

    func setFavoriteAction(target: Any?, action: Selector) {
        favoriteButton.removeTarget(nil, action: nil, for: .allEvents)
        favoriteButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func setRatingAction(target: Any?, action: Selector) {
        ratingButton.removeTarget(nil, action: nil, for: .allEvents)
        ratingButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func setReviewAction(target: Any?, action: Selector) {
        reviewButton.removeTarget(nil, action: nil, for: .allEvents)
        reviewButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func setVisibleActions(
        favorite: Bool,
        rating: Bool,
        review: Bool
    ) {
        isFavoriteActionVisible = favorite
        isRatingActionVisible = rating
        isReviewActionVisible = review

        favoriteButton.isHidden = !favorite
        ratingButton.isHidden = !rating
        reviewButton.isHidden = !review

        updateButtonWidthConstraints()
    }

    // MARK: - Setup

    private func configureView() {
        backgroundColor = ThemeColor.backgroundSecondary
    }

    private func setupHierarchy() {
        addSubview(separatorView)
        addSubview(stackView)
    }

    private func setupConstraints() {
        separatorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Metrics.separatorHeight)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Metrics.verticalInset)
            make.leading.trailing.equalToSuperview().inset(Metrics.horizontalInset)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(Metrics.verticalInset)
            make.height.equalTo(Metrics.buttonHeight)
        }

        favoriteButton.snp.makeConstraints { make in
            favoriteButtonWidthConstraint = make.width.equalTo(Metrics.buttonHeight).constraint
        }

        ratingButton.snp.makeConstraints { make in
            ratingMatchesReviewWidthConstraint = make.width.equalTo(reviewButton.snp.width).constraint
        }

        updateButtonWidthConstraints()
    }

    private func updateButtonWidthConstraints() {
        let visibleActionCount = [
            isFavoriteActionVisible,
            isRatingActionVisible,
            isReviewActionVisible
        ].filter { $0 }.count
        let shouldUseFixedFavoriteWidth = visibleActionCount > 1 && isFavoriteActionVisible
        let shouldMatchRatingAndReviewWidth = isRatingActionVisible && isReviewActionVisible

        if shouldUseFixedFavoriteWidth {
            favoriteButtonWidthConstraint?.activate()
        } else {
            favoriteButtonWidthConstraint?.deactivate()
        }

        if shouldMatchRatingAndReviewWidth {
            ratingMatchesReviewWidthConstraint?.activate()
        } else {
            ratingMatchesReviewWidthConstraint?.deactivate()
        }
    }

    // MARK: - Button Configuration

    private func favoriteButtonConfiguration(isFavorite: Bool) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        configuration.image = UIImage(
            systemName: isFavorite ? "heart.fill" : "heart",
            withConfiguration: imageConfiguration
        )
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = .clear
        configuration.baseForegroundColor = isFavorite
            ? ThemeColor.systemPink
            : ThemeColor.textPrimary
        return configuration
    }

    private func ratingButtonConfiguration(value: Double?) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.attributedTitle = attributedTitle(ratingButtonTitle(value: value), textStyle: .headline)
        configuration.image = UIImage(systemName: "star.fill")
        configuration.imagePlacement = .leading
        configuration.imagePadding = 8
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = ThemeColor.primary
        configuration.baseForegroundColor = ThemeColor.highlight
        return configuration
    }

    private func reviewButtonConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.attributedTitle = attributedTitle("評論", textStyle: .headline)
        configuration.image = UIImage(systemName: "text.bubble")
        configuration.imagePlacement = .leading
        configuration.imagePadding = 8
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = ThemeColor.primary
        configuration.baseForegroundColor = ThemeColor.textPrimary
        return configuration
    }

    private func attributedTitle(_ title: String, textStyle: UIFont.TextStyle) -> AttributedString {
        var attributedTitle = AttributedString(title)
        attributedTitle.font = UIFont.preferredFont(forTextStyle: textStyle)
        return attributedTitle
    }

    private func ratingButtonTitle(value: Double?) -> String {
        guard let value else { return "評分" }
        return BaseDisplayTextFormatter.decimal(value)
    }
}
