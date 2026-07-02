//
//  BaseWebViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import SnapKit
import UIKit
import WebKit

// MARK: - BaseWebViewController

@MainActor
final class BaseWebViewController: BaseViewController {

    // MARK: - Properties

    private let url: URL
    private let preferredTitle: String?

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = ThemeColor.background
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    // MARK: - Initialization

    init(url: URL, title: String? = nil) {
        self.url = url
        self.preferredTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.url = URL(string: "about:blank") ?? URL(fileURLWithPath: "/")
        self.preferredTitle = nil
        super.init(coder: coder)
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        title = preferredTitle ?? url.host()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(handleReloadButtonTapped)
        )
    }

    override func setupHierarchy() {
        view.addSubview(webView)
    }

    override func setupConstraints() {
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func bindViewModel() {
        loadURL()
    }

    // MARK: - Actions

    @objc private func handleReloadButtonTapped() {
        webView.reload()
    }

    // MARK: - Private Methods

    private func loadURL() {
        webView.load(URLRequest(url: url))
    }
}

// MARK: - WKNavigationDelegate

extension BaseWebViewController: WKNavigationDelegate {

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.targetFrame == nil,
           let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        setLoadingVisible(true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setLoadingVisible(false)

        if preferredTitle == nil,
           let webTitle = webView.title,
           !webTitle.isEmpty {
            title = webTitle
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        handleLoadFailure(error)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        handleLoadFailure(error)
    }

    private func handleLoadFailure(_ error: Error) {
        setLoadingVisible(false)
        presentAlert(
            title: "無法開啟連結",
            message: error.localizedDescription
        )
    }
}
