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
        static let stackSpacing: CGFloat = 24
        static let buttonSpacing: CGFloat = 12
        static let buttonHeight: CGFloat = 48
        static let starSliderHeight: CGFloat = 64
    }

    fileprivate enum RatingStarValue {
        static let minimum = AccountMediaRatingValue.minimum
        static let maximum = AccountMediaRatingValue.maximum
        static let step = AccountMediaRatingValue.step
        static let stepCount = Int(maximum / step)

        static func normalized(_ value: Double) -> Double {
            let roundedValue = (value / step).rounded() * step
            return min(max(roundedValue, minimum), maximum)
        }
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

    private lazy var starSliderView: RatingStarSliderView = {
        let view = RatingStarSliderView(value: selectedValue)
        view.addTarget(self, action: #selector(handleRatingValueChanged), for: .valueChanged)
        view.addTarget(self, action: #selector(handleRatingEditingEnded), for: .editingDidEnd)
        return view
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
            starSliderView
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Metrics.stackSpacing
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
        self.selectedValue = RatingStarValue.normalized(currentValue ?? defaultValue)
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        self.currentValue = nil
        self.onSubmit = { _ in }
        self.onDelete = {}
        self.selectedValue = RatingStarValue.normalized(AccountMediaRatingValue.fallback)
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
            make.center.equalToSuperview()
            make.width.equalToSuperview().offset(-Metrics.horizontalInset)
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(Metrics.verticalInset)
            make.bottom.lessThanOrEqualTo(actionStackView.snp.top).offset(-Metrics.stackSpacing)
        }

        starSliderView.snp.makeConstraints { make in
            make.height.equalTo(Metrics.starSliderHeight)
        }

        actionStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Metrics.horizontalInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(Metrics.verticalInset)
            make.height.equalTo(Metrics.buttonHeight)
        }
    }

    // MARK: - Actions

    @objc private func handleRatingValueChanged() {
        selectedValue = starSliderView.value
        updateValueLabel()
        enlargeValueLabel()
    }

    @objc private func handleRatingEditingEnded() {
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

// MARK: - RatingStarSliderView

@MainActor
private final class RatingStarSliderView: UIControl {

    private enum Metrics {
        static let starSize: CGFloat = 44
        static let starSpacing: CGFloat = 8
        static let shakeOffset: CGFloat = 4
        static let shakeDuration: CFTimeInterval = 0.18
    }

    private enum Symbol {
        static let empty = "star"
        static let filled = "star.fill"
    }

    var value: Double {
        didSet {
            value = RatingPageSheetViewController.RatingStarValue.normalized(value)
            updateStarImages()
        }
    }

    private var filledWidthConstraint: Constraint?

    private let emptyStarImageViews: [UIImageView] = (0..<5).map { _ in
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.textTertiary
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.image = UIImage(systemName: Symbol.empty)
        return imageView
    }

    private let filledStarImageViews: [UIImageView] = (0..<5).map { _ in
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.highlight
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.image = UIImage(systemName: Symbol.filled)
        return imageView
    }

    private let starContainerView = UIView()

    private let filledContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private lazy var emptyStackView = makeStarStackView(imageViews: emptyStarImageViews)

    private lazy var filledStackView = makeStarStackView(imageViews: filledStarImageViews)

    init(value: Double) {
        self.value = RatingPageSheetViewController.RatingStarValue.normalized(value)
        super.init(frame: .zero)
        configureView()
        setupHierarchy()
        setupConstraints()
        updateStarImages()
    }

    required init?(coder: NSCoder) {
        self.value = RatingPageSheetViewController.RatingStarValue.normalized(AccountMediaRatingValue.fallback)
        super.init(coder: coder)
        configureView()
        setupHierarchy()
        setupConstraints()
        updateStarImages()
    }

    override var intrinsicContentSize: CGSize {
        let width = Metrics.starSize * 5 + Metrics.starSpacing * 4
        return CGSize(width: width, height: Metrics.starSize)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateValue(for: touch)
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateValue(for: touch)
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let touch {
            updateValue(for: touch)
        }
        sendActions(for: .editingDidEnd)
    }

    override func cancelTracking(with event: UIEvent?) {
        sendActions(for: .editingDidEnd)
    }

    private func configureView() {
        backgroundColor = .clear
        starContainerView.isUserInteractionEnabled = false
        filledContainerView.isUserInteractionEnabled = false
    }

    private func setupHierarchy() {
        addSubview(starContainerView)
        starContainerView.addSubview(emptyStackView)
        starContainerView.addSubview(filledContainerView)
        filledContainerView.addSubview(filledStackView)
    }

    private func setupConstraints() {
        starContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.width.equalTo(intrinsicContentSize.width)
            make.height.equalTo(Metrics.starSize)
        }

        emptyStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        filledContainerView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            filledWidthConstraint = make.width.equalTo(0).constraint
        }

        filledStackView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(starContainerView)
        }

        (emptyStarImageViews + filledStarImageViews).forEach { imageView in
            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(Metrics.starSize)
            }
        }
    }

    private func updateValue(for touch: UITouch) {
        guard bounds.width > 0 else { return }
        guard starContainerView.frame.width > 0 else { return }

        let locationX = touch.location(in: self).x - starContainerView.frame.minX
        let clampedX = min(max(locationX, 0), starContainerView.frame.width)
        let progress = clampedX / starContainerView.frame.width
        let step = max(
            1,
            min(
                RatingPageSheetViewController.RatingStarValue.stepCount,
                Int(ceil(progress * CGFloat(RatingPageSheetViewController.RatingStarValue.stepCount)))
            )
        )
        let newValue = Double(step) * RatingPageSheetViewController.RatingStarValue.step

        guard value != newValue else { return }
        value = newValue
        animateStarShake()
        sendActions(for: .valueChanged)
    }

    private func updateStarImages() {
        let progress = value / RatingPageSheetViewController.RatingStarValue.maximum
        let filledWidth = intrinsicContentSize.width * progress
        filledWidthConstraint?.update(offset: filledWidth)
    }

    private func animateStarShake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [
            -Metrics.shakeOffset,
            Metrics.shakeOffset,
            -Metrics.shakeOffset / 2,
            Metrics.shakeOffset / 2,
            0
        ]
        animation.duration = Metrics.shakeDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        starContainerView.layer.removeAnimation(forKey: "ratingStarShake")
        starContainerView.layer.add(animation, forKey: "ratingStarShake")
    }

    private func makeStarStackView(imageViews: [UIImageView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: imageViews)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = Metrics.starSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }
}
