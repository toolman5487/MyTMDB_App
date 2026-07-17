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
final class DetailImagePreviewViewController: UIViewController {

    private enum Layout {
        static let closeButtonSize: CGFloat = 44
        static let closeButtonInset: CGFloat = 16
        static let minimumZoomScale: CGFloat = 1
        static let maximumZoomScale: CGFloat = 4
    }

    private let imageURL: URL

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
        return imageView
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.48)
        button.layer.cornerRadius = Layout.closeButtonSize / 2
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        return button
    }()

    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    private func configureView() {
        view.backgroundColor = .black
        scrollView.delegate = self
        closeButton.addTarget(self, action: #selector(dismissPreview), for: .touchUpInside)
    }

    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(closeButton)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.closeButtonInset)
            make.trailing.equalToSuperview().inset(Layout.closeButtonInset)
            make.width.height.equalTo(Layout.closeButtonSize)
        }
    }

    private func loadImage() {
        imageView.sd_setImage(with: imageURL) { [weak self] image, _, _, _ in
            guard let self else { return }
            imageView.image = image
            updateImageViewFrame()
        }
    }

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

    @objc
    private func dismissPreview() {
        dismiss(animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension DetailImagePreviewViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
    }
}
