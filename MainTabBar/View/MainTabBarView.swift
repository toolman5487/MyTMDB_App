//
//  MainTabBarView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import SnapKit
import UIKit

// MARK: - MainTabBarViewDelegate

@MainActor
protocol MainTabBarViewDelegate: AnyObject {
    func mainTabBarView(_ view: MainTabBarView, didSelect item: MainTabBarItem, at index: Int)
}

// MARK: - MainTabBarView

@MainActor
final class MainTabBarView: UIView {

    // MARK: - Properties

    weak var delegate: MainTabBarViewDelegate?

    private var items: [MainTabBarItem] = []
    private var buttons: [UIButton] = []
    private var selectedIndex = 0
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - UI Components

    private let backgroundView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemChromeMaterial)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()

    private let topSeparatorView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = ThemeColor.separator
        return view
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        return stackView
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    // MARK: - Configuration

    func configure(items: [MainTabBarItem], selectedIndex: Int) {
        self.items = items
        self.selectedIndex = selectedIndex
        buttons.forEach { $0.removeFromSuperview() }
        buttons = items.enumerated().map { index, item in
            makeButton(for: item, at: index)
        }
        buttons.forEach(stackView.addArrangedSubview)
        prepareFeedback()
        updateSelection(selectedIndex)
    }

    func updateSelection(_ index: Int) {
        guard items.indices.contains(index) else { return }
        let previousIndex = selectedIndex
        selectedIndex = index

        updateButton(at: previousIndex)
        updateButton(at: index)
    }

    private func updateButton(at index: Int) {
        guard items.indices.contains(index), buttons.indices.contains(index) else { return }
        let isSelected = index == selectedIndex
        let button = buttons[index]
        button.configuration = makeConfiguration(for: items[index], isSelected: isSelected)
        button.accessibilityTraits = isSelected ? [.button, .selected] : .button
    }

    func prepareFeedback() {
        impactFeedbackGenerator.prepare()
    }

    func performSelectionFeedbackIfNeeded(for index: Int) {
        guard index != selectedIndex else {
            return
        }
        impactFeedbackGenerator.impactOccurred(intensity: 1)
        impactFeedbackGenerator.prepare()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(backgroundView)
        addSubview(topSeparatorView)
        backgroundView.contentView.addSubview(stackView)
    }

    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        topSeparatorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(4)
        }
    }

    // MARK: - Actions

    @objc private func tabButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard items.indices.contains(index) else { return }
        performSelectionFeedbackIfNeeded(for: index)
        delegate?.mainTabBarView(self, didSelect: items[index], at: index)
    }

    @objc private func tabButtonTouchDown(_ sender: UIButton) {
        prepareFeedback()
    }

    // MARK: - Private Methods

    private func makeButton(for item: MainTabBarItem, at index: Int) -> UIButton {
        let button = UIButton(configuration: makeConfiguration(for: item, isSelected: index == selectedIndex))
        button.tag = index
        button.accessibilityLabel = item.title
        button.addTarget(self, action: #selector(tabButtonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(tabButtonTapped), for: .touchUpInside)
        return button
    }

    private func makeConfiguration(for item: MainTabBarItem, isSelected: Bool) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: isSelected ? item.selectedImageSystemName : item.imageSystemName)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        configuration.baseForegroundColor = isSelected ? ThemeColor.primary : ThemeColor.textSecondary
        configuration.background.backgroundColor = .clear
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4)
        return configuration
    }
}
