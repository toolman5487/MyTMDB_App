//
//  DetailFactsCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/7.
//

import SnapKit
import UIKit

// MARK: - DetailFactsCollectionViewCell

@MainActor
class DetailFactsCollectionViewCell: BaseNestedCollectionViewCell {

    private enum Layout {
        static let itemHeight: CGFloat = 96
    }

    private var facts: [DetailFactItem] = []
    private var previousCollectionWidth: CGFloat = 0

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            DetailFactCardCollectionViewCell.self,
            forCellWithReuseIdentifier: DetailFactCardCollectionViewCell.reuseIdentifier
        )
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(collectionView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard collectionView.bounds.width != previousCollectionWidth else { return }

        previousCollectionWidth = collectionView.bounds.width
        collectionViewFlowLayout.invalidateLayout()
    }

    override func resetForReuse() {
        facts = []
        collectionView.reloadData()
    }

    func configure(facts: [DetailFactItem]) {
        self.facts = facts
        collectionViewFlowLayout.invalidateLayout()
        collectionView.reloadData()
    }
}

extension DetailFactsCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        facts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DetailFactCardCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? DetailFactCardCollectionViewCell {
            cell.configure(with: facts[indexPath.item])
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard facts.indices.contains(indexPath.item) else {
            return .zero
        }

        return DetailFactCardCollectionViewCell.fittingSize(
            for: facts[indexPath.item],
            height: Layout.itemHeight,
            maximumWidth: maximumCardWidth(in: collectionView)
        )
    }

    private func maximumCardWidth(in collectionView: UICollectionView) -> CGFloat {
        let availableWidth = collectionView.bounds.width > 0
            ? collectionView.bounds.width
            : bounds.width
        let sectionInset = collectionViewFlowLayout.sectionInset

        return max(
            availableWidth - sectionInset.left - sectionInset.right,
            0
        )
    }
}

// MARK: - DetailFactCardCollectionViewCell

@MainActor
private final class DetailFactCardCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: DetailFactCardCollectionViewCell.self)

    private enum Layout {
        static let accentWidth: CGFloat = 4
        static let titleTopInset: CGFloat = 12
        static let contentLeadingInset: CGFloat = 16
        static let contentTrailingInset: CGFloat = 12
        static let valueBottomInset: CGFloat = 12
        static let minimumWidth: CGFloat = 120
    }

    private let accentView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.highlight
        return view
    }()

    private let titleLabel = AppFactory.Label.callout()

    private let valueLabel: UILabel = {
        let label = AppFactory.Label.sectionTitle()
        return label
    }()

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(accentView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        accentView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(Layout.accentWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.titleTopInset)
            make.leading.equalToSuperview().inset(Layout.contentLeadingInset)
            make.trailing.equalToSuperview().inset(Layout.contentTrailingInset)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(Layout.contentTrailingInset)
            make.bottom.equalToSuperview().inset(Layout.valueBottomInset)
        }
    }

    override func resetForReuse() {
        titleLabel.text = nil
        valueLabel.text = nil
    }

    func configure(with item: DetailFactItem) {
        titleLabel.text = item.title
        valueLabel.text = item.value
    }

    static func fittingSize(
        for item: DetailFactItem,
        height: CGFloat,
        maximumWidth: CGFloat
    ) -> CGSize {
        let textWidth = max(
            measuredWidth(for: item.title, font: .preferredFont(forTextStyle: .callout)),
            measuredWidth(for: item.value, font: .preferredFont(forTextStyle: .title3))
        )
        let fittingWidth = ceil(
            textWidth + Layout.contentLeadingInset + Layout.contentTrailingInset
        )
        let preferredWidth = max(fittingWidth, Layout.minimumWidth)
        let width = maximumWidth > 0
            ? min(preferredWidth, maximumWidth)
            : preferredWidth

        return CGSize(width: width, height: height)
    }

    private static func measuredWidth(for text: String, font: UIFont) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font]).width
    }
}
