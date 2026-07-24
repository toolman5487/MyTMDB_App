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

    // MARK: - Layout

    private enum Layout {
        static let tabBarContentHeight: CGFloat = 49
        static let tabButtonSize: CGFloat = 44
        static let horizontalInset: CGFloat = 8
        static let urlFieldHeight: CGFloat = 36
        static let urlFieldSpacing: CGFloat = 8
        static let urlFieldHorizontalPadding: CGFloat = 12
        static let urlFieldIconSpacing: CGFloat = 8
        static let urlSecurityIconSize: CGFloat = 14
    }

    // MARK: - Properties

    private let url: URL
    private let preferredTitle: String?

    private var bottomTabBarBottomConstraint: Constraint?

    // MARK: - UI Components

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = ThemeColor.background
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    private let bottomTabBarView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.backgroundSecondary
        return view
    }()

    private let bottomTabBarSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.separator
        return view
    }()

    private let bottomTabBarContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var backButton = makeTabBarButton(
        symbolName: "chevron.backward",
        action: #selector(handleBackButtonTapped)
    )

    private lazy var forwardButton = makeTabBarButton(
        symbolName: "chevron.forward",
        action: #selector(handleForwardButtonTapped)
    )

    private let urlFieldContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.fillSecondary
        view.clipsToBounds = true
        return view
    }()

    private let urlSecurityIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.textSecondary
        imageView.image = UIImage(systemName: "globe")
        return imageView
    }()

    private lazy var urlTextField: UITextField = {
        let textField = UITextField()
        textField.font = .preferredFont(forTextStyle: .callout)
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = ThemeColor.textPrimary
        textField.tintColor = ThemeColor.highlight
        textField.borderStyle = .none
        textField.returnKeyType = .go
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.keyboardType = .URL
        textField.clearButtonMode = .whileEditing
        textField.delegate = self
        textField.isAccessibilityElement = false
        textField.attributedPlaceholder = NSAttributedString(
            string: "搜尋或輸入網址",
            attributes: [.foregroundColor: ThemeColor.textTertiary]
        )
        return textField
    }()

    // MARK: - Initialization

    init(url: URL, title: String? = nil) {
        self.url = url
        self.preferredTitle = title
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        self.url = URL(string: "about:blank") ?? URL(fileURLWithPath: "/")
        self.preferredTitle = nil
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
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

        urlFieldContainerView.layer.cornerRadius = Layout.urlFieldHeight / 2
    }

    override func setupHierarchy() {
        view.addSubview(webView)
        view.addSubview(bottomTabBarView)

        bottomTabBarView.addSubview(bottomTabBarSeparatorView)
        bottomTabBarView.addSubview(bottomTabBarContentView)

        bottomTabBarContentView.addSubview(backButton)
        bottomTabBarContentView.addSubview(urlFieldContainerView)
        bottomTabBarContentView.addSubview(forwardButton)

        urlFieldContainerView.addSubview(urlSecurityIconView)
        urlFieldContainerView.addSubview(urlTextField)
    }

    override func setupConstraints() {
        setupWebViewConstraints()
        setupBottomTabBarConstraints()
        setupBottomTabBarContentConstraints()
        setupURLFieldConstraints()
    }

    override func bindViewModel() {
        enableKeyboardDismissOnTap()
        updateNavigationState()
        loadURL()
    }

    // MARK: - Actions

    @objc private func handleReloadButtonTapped() {
        webView.reload()
    }

    @objc private func handleBackButtonTapped() {
        guard webView.canGoBack else { return }
        webView.goBack()
    }

    @objc private func handleForwardButtonTapped() {
        guard webView.canGoForward else { return }
        webView.goForward()
    }

    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrameInView.minY)
        bottomTabBarBottomConstraint?.update(offset: -overlap)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveValue << 16)
        ) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - Setup

private extension BaseWebViewController {

    func setupWebViewConstraints() {
        webView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomTabBarView.snp.top)
        }
    }

    func setupBottomTabBarConstraints() {
        bottomTabBarView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            bottomTabBarBottomConstraint = make.bottom.equalToSuperview().constraint
        }

        bottomTabBarSeparatorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomTabBarContentView.snp.top)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }

    func setupBottomTabBarContentConstraints() {
        bottomTabBarContentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomTabBarView.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(Layout.tabBarContentHeight)
        }

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Layout.tabButtonSize)
        }

        forwardButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Layout.tabButtonSize)
        }

        urlFieldContainerView.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(Layout.urlFieldSpacing)
            make.trailing.equalTo(forwardButton.snp.leading).offset(-Layout.urlFieldSpacing)
            make.centerY.equalToSuperview()
            make.height.equalTo(Layout.urlFieldHeight)
        }
    }

    func setupURLFieldConstraints() {
        urlSecurityIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.urlFieldHorizontalPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Layout.urlSecurityIconSize)
        }

        urlTextField.snp.makeConstraints { make in
            make.leading.equalTo(urlSecurityIconView.snp.trailing).offset(Layout.urlFieldIconSpacing)
            make.trailing.equalToSuperview().inset(Layout.urlFieldHorizontalPadding)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - Navigation State

private extension BaseWebViewController {

    func makeTabBarButton(
        symbolName: String,
        action: Selector
    ) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbolName)
        configuration.baseForegroundColor = ThemeColor.highlight
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: Layout.horizontalInset,
            leading: Layout.horizontalInset,
            bottom: Layout.horizontalInset,
            trailing: Layout.horizontalInset
        )

        let button = UIButton(configuration: configuration)
        button.isAccessibilityElement = false
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func updateNavigationState() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward

        guard !urlTextField.isFirstResponder else { return }
        updateURLField()
    }

    func updateURLField() {
        let currentURL = webView.url ?? url
        urlTextField.text = displayText(for: currentURL)
        updateSecurityIcon(for: currentURL)
    }

    func updateSecurityIcon(for url: URL) {
        switch url.scheme?.lowercased() {
        case "https":
            urlSecurityIconView.image = UIImage(systemName: "lock.fill")

        case "http":
            urlSecurityIconView.image = UIImage(systemName: "lock.open.fill")

        default:
            urlSecurityIconView.image = UIImage(systemName: "globe")
        }
    }

    func loadURL(from input: String? = nil) {
        if let input,
           let destinationURL = url(from: input) {
            webView.load(URLRequest(url: destinationURL))
            return
        }

        updateURLField()
        webView.load(URLRequest(url: url))
    }
}

// MARK: - URL Handling

private extension BaseWebViewController {

    func displayText(for url: URL) -> String {
        var text = url.absoluteString

        if text.hasPrefix("https://") {
            text = String(text.dropFirst("https://".count))
        } else if text.hasPrefix("http://") {
            text = String(text.dropFirst("http://".count))
        }

        if text.hasSuffix("/"), text.count > 1 {
            text.removeLast()
        }

        return text
    }

    func url(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }

        return URL(string: "https://\(trimmed)")
    }
}

// MARK: - Keyboard

private extension BaseWebViewController {

    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
}

// MARK: - WKNavigationDelegate

extension BaseWebViewController: WKNavigationDelegate {

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
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
        updateNavigationState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setLoadingVisible(false)
        updateNavigationState()

        if preferredTitle == nil,
           let webTitle = webView.title,
           !webTitle.isEmpty {
            title = webTitle
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateNavigationState()
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
        updateNavigationState()
        presentAlert(
            title: "無法開啟連結",
            message: error.localizedDescription
        )
    }
}

// MARK: - UITextFieldDelegate

extension BaseWebViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = (webView.url ?? url).absoluteString
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateURLField()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let destinationURL = url(from: textField.text ?? "") else {
            textField.resignFirstResponder()
            return true
        }

        webView.load(URLRequest(url: destinationURL))
        textField.resignFirstResponder()
        return true
    }
}
