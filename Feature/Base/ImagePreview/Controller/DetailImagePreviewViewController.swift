//
//  DetailImagePreviewViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/17.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - DetailImagePreviewViewController

@MainActor
class DetailImagePreviewViewController: UIViewController {

    // MARK: - Layout

    private enum Layout {
        static let closeButtonSize: CGFloat = 44
        static let closeButtonInset: CGFloat = 16
        static let titleHorizontalInset: CGFloat = 72
        static let pageControlBottomInset: CGFloat = 16
        static let pageTapDebounceInterval: TimeInterval = 0.32
    }

    // MARK: - Properties

    private let imageURLs: [URL]
    private let previewTitle: String?
    private let interfaceLocalization: AppInterfaceLocalization

    private var currentIndex: Int
    private var isPaging = false
    private var lastPageTapDate: Date?

    var previewBackgroundColor: UIColor {
        .black
    }

    var previewForegroundColor: UIColor {
        .white
    }

    // MARK: - UI Components

    private lazy var pageViewController: UIPageViewController = {
        let viewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        viewController.dataSource = self
        viewController.delegate = self
        return viewController
    }()

    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.32)
        pageControl.allowsContinuousInteraction = false
        return pageControl
    }()

    private let pageTextLabel: UILabel = {
        let label = AppFactory.Label.captionPrimary(color: .white, alignment: .center, lines: 1)
        label.isAccessibilityElement = false
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.48)
        button.layer.cornerRadius = Layout.closeButtonSize / 2
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        return button
    }()

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.headline(color: ThemeColor.highlight, alignment: .center, lines: 1)
        label.isAccessibilityElement = false
        return label
    }()

    // MARK: - Initialization

    init(
        imageURLs: [URL],
        selectedIndex: Int,
        title: String?,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        let uniqueImageURLs = Self.uniqueImageURLs(from: imageURLs)
        self.imageURLs = uniqueImageURLs
        self.previewTitle = title
        self.interfaceLocalization = interfaceLocalization
        self.currentIndex = min(max(selectedIndex, 0), max(uniqueImageURLs.count - 1, 0))
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setupHierarchy()
        setupConstraints()
        showInitialPage()
    }

    // MARK: - Setup

    private func configureView() {
        view.backgroundColor = previewBackgroundColor
        pageViewController.view.backgroundColor = previewBackgroundColor
        pageControl.currentPageIndicatorTintColor = previewForegroundColor
        pageControl.pageIndicatorTintColor = previewForegroundColor.withAlphaComponent(0.32)
        pageTextLabel.textColor = previewForegroundColor
        closeButton.tintColor = previewForegroundColor
        pageControl.accessibilityLabel = interfaceLocalization.string(
            "image_preview.page_control.accessibility_label",
            defaultValue: "Image Page"
        )
        closeButton.accessibilityLabel = interfaceLocalization.string(
            "common.action.close",
            defaultValue: "Close"
        )
        closeButton.accessibilityHint = interfaceLocalization.string(
            "image_preview.close.accessibility_hint",
            defaultValue: "Double-tap to close the image preview"
        )
        pageControl.numberOfPages = imageURLs.count
        pageControl.currentPage = currentIndex
        pageControl.isHidden = imageURLs.count <= 1
        updatePageIndicator()
        titleLabel.text = previewTitle
        titleLabel.isHidden = previewTitle?.isEmpty != false
        closeButton.addTarget(self, action: #selector(dismissPreview), for: .touchUpInside)
        configurePageTapGesture()
    }

    private func setupHierarchy() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        view.addSubview(pageControl)
        view.addSubview(pageTextLabel)
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
    }

    private func setupConstraints() {
        pageViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(Layout.pageControlBottomInset)
        }

        pageTextLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top).offset(-4)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.closeButtonInset)
            make.leading.trailing.equalToSuperview().inset(Layout.titleHorizontalInset)
            make.height.equalTo(Layout.closeButtonSize)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.closeButtonInset)
            make.trailing.equalToSuperview().inset(Layout.closeButtonInset)
            make.width.height.equalTo(Layout.closeButtonSize)
        }
    }

    // MARK: - Page Handling

    private func showInitialPage() {
        guard let viewController = imagePageViewController(at: currentIndex) else { return }
        pageViewController.setViewControllers([viewController], direction: .forward, animated: false)
    }

    private func showImage(at index: Int, direction: UIPageViewController.NavigationDirection) {
        guard !isPaging,
              imageURLs.indices.contains(index),
              let viewController = imagePageViewController(at: index) else {
            return
        }

        isPaging = true
        pageViewController.setViewControllers([viewController], direction: direction, animated: true) { [weak self] completed in
            guard let self else { return }
            isPaging = false
            guard completed else { return }
            currentIndex = index
            updatePageIndicator()
        }
    }

    private func imagePageViewController(at index: Int) -> DetailImagePreviewPageViewController? {
        guard imageURLs.indices.contains(index) else { return nil }
        return DetailImagePreviewPageViewController(
            imageURL: imageURLs[index],
            index: index,
            totalCount: imageURLs.count,
            previewTitle: previewTitle,
            backgroundColor: previewBackgroundColor,
            interfaceLocalization: interfaceLocalization
        )
    }

    // MARK: - Gesture Handling

    private func configurePageTapGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handlePageTap(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        pageViewController.view.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc
    private func handlePageTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard imageURLs.count > 1, canHandlePageTap() else { return }

        let location = gestureRecognizer.location(in: pageViewController.view)
        let isPreviousTapArea = location.x < pageViewController.view.bounds.midX
        if isPreviousTapArea {
            showImage(at: currentIndex - 1, direction: .reverse)
        } else {
            showImage(at: currentIndex + 1, direction: .forward)
        }
    }

    private func canHandlePageTap() -> Bool {
        let now = Date()
        defer { lastPageTapDate = now }

        guard let lastPageTapDate else { return true }
        return now.timeIntervalSince(lastPageTapDate) >= Layout.pageTapDebounceInterval
    }

    // MARK: - Actions

    @objc
    private func dismissPreview() {
        dismiss(animated: true)
    }

    // MARK: - Helpers

    private static func uniqueImageURLs(from imageURLs: [URL]) -> [URL] {
        var seen = Set<URL>()
        return imageURLs.filter { seen.insert($0).inserted }
    }

    private func updatePageIndicator() {
        pageControl.currentPage = currentIndex
        pageTextLabel.text = "\(currentIndex + 1) / \(imageURLs.count)"
        pageTextLabel.isHidden = imageURLs.isEmpty
        pageControl.accessibilityValue = imageURLs.isEmpty
            ? nil
            : interfaceLocalization.formatted(
                "image_preview.page.accessibility_value_format",
                defaultValue: "Image %1$lld of %2$lld",
                currentIndex + 1,
                imageURLs.count
            )
        pageControl.accessibilityHint = imageURLs.count > 1
            ? interfaceLocalization.string(
                "image_preview.page_control.accessibility_hint",
                defaultValue: "Swipe left or right to switch images"
            )
            : nil
    }
}

// MARK: - UIPageViewControllerDataSource

extension DetailImagePreviewViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let imageViewController = viewController as? DetailImagePreviewPageViewController else {
            return nil
        }

        return imagePageViewController(at: imageViewController.index - 1)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let imageViewController = viewController as? DetailImagePreviewPageViewController else {
            return nil
        }

        return imagePageViewController(at: imageViewController.index + 1)
    }
}

// MARK: - UIPageViewControllerDelegate

extension DetailImagePreviewViewController: UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let imageViewController = pageViewController.viewControllers?.first as? DetailImagePreviewPageViewController else {
            return
        }

        isPaging = false
        currentIndex = imageViewController.index
        updatePageIndicator()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension DetailImagePreviewViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

// MARK: - DetailImagePreviewPageViewController

@MainActor
private final class DetailImagePreviewPageViewController: UIViewController {

    // MARK: - Layout

    private enum Layout {
        static let minimumZoomScale: CGFloat = 1
        static let maximumZoomScale: CGFloat = 4
    }

    // MARK: - Properties

    let index: Int
    private let imageURL: URL
    private let totalCount: Int
    private let previewTitle: String?
    private let backgroundColor: UIColor
    private let interfaceLocalization: AppInterfaceLocalization

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = Layout.minimumZoomScale
        scrollView.maximumZoomScale = Layout.maximumZoomScale
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = .image
        return imageView
    }()

    // MARK: - Initialization

    init(
        imageURL: URL,
        index: Int,
        totalCount: Int,
        previewTitle: String?,
        backgroundColor: UIColor,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.imageURL = imageURL
        self.index = index
        self.totalCount = totalCount
        self.previewTitle = previewTitle
        self.backgroundColor = backgroundColor
        self.interfaceLocalization = interfaceLocalization
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setupHierarchy()
        setupConstraints()
        loadImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateImageViewFrame()
    }

    // MARK: - Setup

    private func configureView() {
        view.backgroundColor = backgroundColor
        scrollView.delegate = self
        let titleText = BaseDisplayTextFormatter.nonEmptyText(previewTitle)
            ?? interfaceLocalization.string("image_preview.image.fallback_title", defaultValue: "Image")
        imageView.accessibilityLabel = interfaceLocalization.formatted(
            "image_preview.image.accessibility_label_format",
            defaultValue: "%1$@, image %2$lld of %3$lld",
            titleText,
            index + 1,
            totalCount
        )
        imageView.accessibilityHint = totalCount > 1
            ? interfaceLocalization.string(
                "image_preview.image.paging_zoom_hint",
                defaultValue: "Swipe left or right to switch images. Pinch to zoom."
            )
            : interfaceLocalization.string(
                "image_preview.image.zoom_hint",
                defaultValue: "Pinch to zoom."
            )
    }

    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Image Loading

    private func loadImage() {
        imageView.sd_setImage(with: imageURL) { [weak self] image, _, _, _ in
            guard let self else { return }
            imageView.image = image
            updateImageViewFrame()
        }
    }

    // MARK: - Layout Updates

    private func updateImageViewFrame() {
        guard let image = imageView.image else {
            imageView.frame = scrollView.bounds
            return
        }

        let boundsSize = scrollView.bounds.size
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let widthScale = boundsSize.width / imageSize.width
        let heightScale = boundsSize.height / imageSize.height
        let scale = min(widthScale, heightScale)
        let displaySize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        imageView.frame = CGRect(origin: .zero, size: displaySize)
        scrollView.contentSize = displaySize
        centerImageView()
    }

    private func centerImageView() {
        let boundsSize = scrollView.bounds.size
        let frameSize = imageView.frame.size
        imageView.center = CGPoint(
            x: max(boundsSize.width, frameSize.width) / 2,
            y: max(boundsSize.height, frameSize.height) / 2
        )
    }
}

// MARK: - UIScrollViewDelegate

extension DetailImagePreviewPageViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
    }
}
