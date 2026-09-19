//
//  DetailBottomActionBarView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/14.
//

import SnapKit
import UIKit

// MARK: - DetailBottomActionBarView

@MainActor
final class DetailBottomActionBarView: UIView {

    // MARK: - Metrics

    enum Metrics {
        static let horizontalInset = DetailLayoutMetrics.horizontalContentInset
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
    private var favoriteAction: (@MainActor () -> Void)?
    private var ratingAction: (@MainActor () -> Void)?
    private var reviewAction: (@MainActor () -> Void)?
    private let localization: AppInterfaceLocalization

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

    init(
        localization: AppInterfaceLocalization,
        frame: CGRect = .zero
    ) {
        self.localization = localization
        super.init(frame: frame)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    private func configureFavorite(isFavorite: Bool, isEnabled: Bool) {
        favoriteButton.configuration = favoriteButtonConfiguration(isFavorite: isFavorite)
        favoriteButton.isEnabled = isEnabled
        favoriteButton.applyAccessibilityText(favoriteAccessibilityText(isFavorite: isFavorite))
    }

    private func configureRating(value: Double?, isEnabled: Bool) {
        ratingButton.configuration = ratingButtonConfiguration(value: value)
        ratingButton.isEnabled = isEnabled
        ratingButton.applyAccessibilityText(ratingAccessibilityText(value: value))
    }

    func configureFavorite(with state: AccountMediaFavoriteState) {
        configureFavorite(
            isFavorite: state.isFavorite,
            isEnabled: state.isButtonEnabled
        )
    }

    func configurePendingFavorite(from state: AccountMediaFavoriteState) {
        guard case .ready(let isFavorite) = state else { return }
        configureFavorite(isFavorite: !isFavorite, isEnabled: false)
    }

    func configureRating(with state: AccountMediaRatingState) {
        configureRating(value: state.value, isEnabled: state.isButtonEnabled)
    }

    func configurePendingRating(value: Double?) {
        configureRating(value: value, isEnabled: false)
    }

    func setActionHandlers(
        favorite: (@MainActor () -> Void)?,
        rating: (@MainActor () -> Void)?,
        review: (@MainActor () -> Void)?
    ) {
        favoriteAction = favorite
        ratingAction = rating
        reviewAction = review
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
        separatorView.isAccessibilityElement = false
        favoriteButton.applyAccessibilityText(favoriteAccessibilityText(isFavorite: false))
        ratingButton.applyAccessibilityText(ratingAccessibilityText(value: nil))
        reviewButton.applyAccessibilityText(
            AccessibilityText(
                label: reviewTitle,
                hint: localization.string(
                    "detail.action.review.accessibility_hint",
                    defaultValue: "Double-tap to view reviews"
                )
            )
        )
        favoriteButton.addTarget(self, action: #selector(handleFavoriteAction), for: .touchUpInside)
        ratingButton.addTarget(self, action: #selector(handleRatingAction), for: .touchUpInside)
        reviewButton.addTarget(self, action: #selector(handleReviewAction), for: .touchUpInside)
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
        configuration.attributedTitle = attributedTitle(reviewTitle, textStyle: .headline)
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
        guard let value else { return ratingTitle }
        return BaseDisplayTextFormatter.decimal(value)
    }

    // MARK: - Localized Text

    private var ratingTitle: String {
        localization.string("detail.action.rating.title", defaultValue: "Rate")
    }

    private var reviewTitle: String {
        localization.string("detail.action.review.title", defaultValue: "Reviews")
    }

    private func favoriteAccessibilityText(isFavorite: Bool) -> AccessibilityText {
        AccessibilityText(
            label: localization.string(
                "detail.action.favorite.accessibility_label",
                defaultValue: "Favorite"
            ),
            value: isFavorite
                ? localization.string("detail.action.favorite.added", defaultValue: "Added to Favorites")
                : localization.string("detail.action.favorite.not_added", defaultValue: "Not in Favorites"),
            hint: localization.string(
                "detail.action.favorite.accessibility_hint",
                defaultValue: "Double-tap to change favorite status"
            )
        )
    }

    private func ratingAccessibilityText(value: Double?) -> AccessibilityText {
        AccessibilityText(
            label: ratingTitle,
            value: value.map {
                localization.formatted(
                    "detail.action.rating.current_value_format",
                    defaultValue: "Current rating: %@",
                    BaseDisplayTextFormatter.decimal($0)
                )
            } ?? BaseDisplayTextFormatter.unratedText(localization: localization),
            hint: localization.string(
                "detail.action.rating.accessibility_hint",
                defaultValue: "Double-tap to rate"
            )
        )
    }

    // MARK: - Actions

    @objc
    private func handleFavoriteAction() {
        favoriteAction?()
    }

    @objc
    private func handleRatingAction() {
        ratingAction?()
    }

    @objc
    private func handleReviewAction() {
        reviewAction?()
    }
}
