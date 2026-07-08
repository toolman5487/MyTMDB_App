//
//  MainHomeCarouselView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import SnapKit
import UIKit

// MARK: - MainHomeCarouselView

@MainActor
final class MainHomeCarouselView: UIView {

    // MARK: - Constants

    private enum CellIdentifier {
        static let carousel = String(describing: MainHomeCarouselCollectionViewCell.self)
    }

    private enum AutoScroll {
        static let interval: TimeInterval = 3
    }

    // MARK: - Properties

    private var items: [MainHomeContentItem] = []
    private var autoScrollTimer: Timer?
    var onItemSelected: ((MainHomeContentItem) -> Void)?

    // MARK: - UI Components

    private let collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MainHomeCarouselCollectionViewCell.self,
            forCellWithReuseIdentifier: CellIdentifier.carousel
        )
        return collectionView
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

    deinit {
        MainActor.assumeIsolated {
            autoScrollTimer?.invalidate()
        }
    }

    // MARK: - Lifecycle

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == nil {
            stopAutoScroll()
        } else {
            startAutoScrollIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let itemSize = collectionView.bounds.size
        guard collectionViewFlowLayout.itemSize != itemSize else { return }

        collectionViewFlowLayout.itemSize = itemSize
        collectionViewFlowLayout.invalidateLayout()
    }

    // MARK: - Setup

    private func configureView() {
        backgroundColor = .clear
    }

    private func setupHierarchy() {
        addSubview(collectionView)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(items: [MainHomeContentItem]) {
        self.items = Array(items.prefix(8))
        isHidden = self.items.isEmpty
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()

        stopAutoScroll()
        startAutoScrollIfNeeded()
    }

    // MARK: - Auto Scroll

    private func startAutoScrollIfNeeded() {
        guard window != nil else { return }
        guard items.count > 1 else { return }
        guard autoScrollTimer == nil else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: AutoScroll.interval, repeats: true) { [weak self] _ in
            Task(priority: .userInitiated) { @MainActor in
                self?.scrollToNextItem()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        autoScrollTimer = timer
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func scrollToNextItem() {
        guard items.count > 1 else { return }
        guard collectionView.bounds.width > 0 else { return }

        let currentIndex = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        let nextIndex = (currentIndex + 1) % items.count
        collectionView.scrollToItem(
            at: IndexPath(item: nextIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeCarouselView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CellIdentifier.carousel,
            for: indexPath
        )

        if let cell = cell as? MainHomeCarouselCollectionViewCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MainHomeCarouselView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onItemSelected?(items[indexPath.item])
    }
}
