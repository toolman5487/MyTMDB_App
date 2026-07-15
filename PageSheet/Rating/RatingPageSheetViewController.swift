//
//  RatingPageSheetViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/15.
//

import SnapKit
import UIKit

// MARK: - RatingPageSheetViewController

@MainActor
final class RatingPageSheetViewController: UIViewController {

    // MARK: - Metrics

    private enum Metrics {
        static let horizontalInset: CGFloat = 24
        static let verticalInset: CGFloat = 24
        static let stackSpacing: CGFloat = 16
        static let compactSpacing: CGFloat = 8
        static let buttonSpacing: CGFloat = 12
        static let buttonHeight: CGFloat = 48
        static let sliderHeight: CGFloat = 44
    }

    // MARK: - Properties

    private let currentValue: Double?
    private let onSubmit: (Double) -> Void
    private let onDelete: () -> Void
    private var selectedValue: Double
    private var valueLabelScaleAnimator: UIViewPropertyAnimator?

    // MARK: - UI Components

    private let valueLabel: UILabel = {
        let label = AppFactory.Label.title1(nil, color: ThemeColor.highlight, alignment: .center, lines: 1)
        label.font = .preferredFont(forTextStyle: .largeTitle)
        return label
    }()

    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = Float(AccountMediaRatingValue.minimum)
        slider.maximumValue = Float(AccountMediaRatingValue.maximum)
        slider.value = Float(selectedValue)
        slider.minimumTrackTintColor = ThemeColor.highlight
        slider.maximumTrackTintColor = ThemeColor.fillSecondary
        slider.addTarget(self, action: #selector(handleSliderValueChanged), for: .valueChanged)
        slider.addTarget(
            self,
            action: #selector(handleSliderEditingEnded),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
        return slider
    }()

    private let minimumLabel = AppFactory.Label.footnote("0.5", color: ThemeColor.textTertiary)
    private let maximumLabel = AppFactory.Label.footnote("10", color: ThemeColor.textTertiary, alignment: .right)

    private lazy var rangeStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [minimumLabel, maximumLabel])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var submitButton: UIButton = {
        let button = AppFactory.Button.primaryFilled(title: "送出評分")
        button.addTarget(self, action: #selector(handleSubmitButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var deleteButton: UIButton = {
        let button = AppFactory.Button.destructiveFilled(title: "刪除評分")
        button.isHidden = currentValue == nil
        button.addTarget(self, action: #selector(handleDeleteButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            valueLabel,
            slider,
            rangeStackView
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Metrics.stackSpacing
        stackView.setCustomSpacing(Metrics.compactSpacing, after: slider)
        return stackView
    }()

    private lazy var actionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            deleteButton,
            submitButton
        ])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = Metrics.buttonSpacing
        return stackView
    }()

    // MARK: - Initialization

    init(
        title: String,
        currentValue: Double?,
        defaultValue: Double = AccountMediaRatingValue.fallback,
        onSubmit: @escaping (Double) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.currentValue = currentValue
        self.onSubmit = onSubmit
        self.onDelete = onDelete
        self.selectedValue = currentValue ?? AccountMediaRatingValue.normalized(defaultValue)
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        self.currentValue = nil
        self.onSubmit = { _ in }
        self.onDelete = {}
        self.selectedValue = AccountMediaRatingValue.fallback
        super.init(coder: coder)
        title = "評分"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setupHierarchy()
        setupConstraints()
        updateValueLabel()
    }

    // MARK: - Setup

    private func configureView() {
        view.backgroundColor = ThemeColor.backgroundSecondary
    }

    private func setupHierarchy() {
        view.addSubview(contentStackView)
        view.addSubview(actionStackView)
    }

    private func setupConstraints() {
        contentStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().priority(.high)
            make.width.equalToSuperview().offset(-Metrics.horizontalInset * 2)
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(Metrics.verticalInset)
            make.bottom.lessThanOrEqualTo(actionStackView.snp.top).offset(-Metrics.stackSpacing)
        }

        slider.snp.makeConstraints { make in
            make.height.equalTo(Metrics.sliderHeight)
        }

        actionStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Metrics.horizontalInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(Metrics.verticalInset)
            make.height.equalTo(Metrics.buttonHeight)
        }
    }

    // MARK: - Actions

    @objc private func handleSliderValueChanged() {
        selectedValue = AccountMediaRatingValue.normalized(Double(slider.value))
        slider.setValue(Float(selectedValue), animated: false)
        updateValueLabel()
        enlargeValueLabel()
    }

    @objc private func handleSliderEditingEnded() {
        resetValueLabelScale()
    }

    @objc private func handleSubmitButtonTapped() {
        onSubmit(selectedValue)
        dismiss(animated: true)
    }

    @objc private func handleDeleteButtonTapped() {
        onDelete()
        dismiss(animated: true)
    }

    private func updateValueLabel() {
        let scoreText = String(format: "%.1f", selectedValue)
        let suffixText = " / 10.0"
        let scoreFont = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
            for: .systemFont(ofSize: 60, weight: .bold)
        )
        let suffixFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        let attributedText = NSMutableAttributedString(
            string: scoreText,
            attributes: [
                .font: scoreFont,
                .foregroundColor: ThemeColor.highlight
            ]
        )
        attributedText.append(
            NSAttributedString(
                string: suffixText,
                attributes: [
                    .font: suffixFont,
                    .foregroundColor: ThemeColor.highlight
                ]
            )
        )
        valueLabel.attributedText = attributedText
    }

    private func enlargeValueLabel() {
        valueLabelScaleAnimator?.stopAnimation(true)
        valueLabel.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)

        let animator = UIViewPropertyAnimator(duration: 0.24, dampingRatio: 0.45) { [valueLabel] in
            valueLabel.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
        }
        valueLabelScaleAnimator = animator
        animator.addCompletion { [weak self] _ in
            self?.valueLabelScaleAnimator = nil
        }
        animator.startAnimation()
    }

    private func resetValueLabelScale() {
        valueLabelScaleAnimator?.stopAnimation(true)

        let animator = UIViewPropertyAnimator(duration: 0.16, curve: .easeOut) { [valueLabel] in
            valueLabel.transform = .identity
        }
        valueLabelScaleAnimator = animator
        animator.addCompletion { [weak self] _ in
            self?.valueLabelScaleAnimator = nil
        }
        animator.startAnimation()
    }
}
