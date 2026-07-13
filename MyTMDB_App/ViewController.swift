//
//  ViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import SnapKit
import UIKit

@MainActor
final class ViewController: BaseViewController {

    // MARK: - Properties

    private let displayTitle: String
    private let placeholderContent: PlaceholderContent
    private let sessionStore: SessionStoring = SessionStore()

    // MARK: - UI Components

    private lazy var placeholderContentView: PlaceholderTabContentView = {
        let view = PlaceholderTabContentView(
            title: displayTitle,
            subtitleText: placeholderContent.subtitle,
            actionTitle: placeholderContent.actionTitle,
            actionButtonColor: placeholderContent.actionConfirmation?.buttonBackgroundColor
        )
        view.onActionTap = { [weak self] in
            self?.presentActionConfirmation()
        }
        return view
    }()

    // MARK: - Initializer

    init(
        displayTitle: String = "MyTMDB",
        tabKind: MainTabKind = .home,
        session: AuthSession = .loggedOut
    ) {
        self.displayTitle = displayTitle
        self.placeholderContent = PlaceholderContent(
            title: displayTitle,
            tabKind: tabKind,
            session: session
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.displayTitle = "MyTMDB"
        self.placeholderContent = PlaceholderContent(title: "MyTMDB", tabKind: .home, session: .loggedOut)
        super.init(coder: coder)
    }

    // MARK: - BaseViewController

    override func configureView() {
        title = displayTitle
    }

    override func setupHierarchy() {
        view.addSubview(placeholderContentView)
    }

    override func setupConstraints() {
        placeholderContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Alert

    private func presentActionConfirmation() {
        guard let actionConfirmation = placeholderContent.actionConfirmation else { return }
        let alert = UIAlertController(
            title: actionConfirmation.title,
            message: actionConfirmation.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(
            UIAlertAction(
                title: actionConfirmation.confirmTitle,
                style: actionConfirmation.confirmStyle
            ) { [weak self] _ in
                self?.performExit()
            }
        )
        present(alert, animated: true)
    }

    // MARK: - Exit

    private func performExit() {
        sessionStore.clear()
        navigateToLoginScreen()
    }

    private func navigateToLoginScreen() {
        guard let windowScene = view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else {
            return
        }
        AppRootFactory.replaceRoot(in: window, for: .loggedOut)
    }
}

// MARK: - PlaceholderContent

private struct PlaceholderContent {
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let actionConfirmation: PlaceholderActionConfirmation?

    init(title: String, tabKind: MainTabKind, session: AuthSession) {
        switch tabKind {
        case .home, .movie, .series:
            self.init(title: title)

        case .memberCenter:
            self.init(title: title, session: session)
        }
    }

    private init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        actionConfirmation: PlaceholderActionConfirmation? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.actionConfirmation = actionConfirmation
    }

    private init(title: String, session: AuthSession) {
        switch session {
        case .loggedOut:
            self.init(
                title: title,
                subtitle: "尚未登入",
                actionTitle: "前往登入",
                actionConfirmation: .returnToLogin
            )

        case .guest:
            self.init(
                title: title,
                subtitle: "目前為訪客模式",
                actionTitle: "返回登入",
                actionConfirmation: .leaveGuestMode
            )

        case .user:
            self.init(
                title: title,
                subtitle: "已成功登入",
                actionTitle: "登出",
                actionConfirmation: .logout
            )
        }
    }
}

// MARK: - PlaceholderActionConfirmation

private enum PlaceholderActionConfirmation {
    case logout
    case leaveGuestMode
    case returnToLogin

    var title: String {
        switch self {
        case .logout:
            return "登出"

        case .leaveGuestMode:
            return "離開訪客模式"

        case .returnToLogin:
            return "前往登入"
        }
    }

    var message: String {
        switch self {
        case .logout:
            return "確定要登出嗎？"

        case .leaveGuestMode:
            return "確定要離開訪客模式並返回登入頁嗎？"

        case .returnToLogin:
            return "確定要返回登入頁嗎？"
        }
    }

    var confirmTitle: String {
        switch self {
        case .logout:
            return "登出"

        case .leaveGuestMode:
            return "離開"

        case .returnToLogin:
            return "返回"
        }
    }
}

// MARK: - PlaceholderTabContentView

@MainActor
private final class PlaceholderTabContentView: UIView {

    // MARK: - Properties

    var onActionTap: (() -> Void)?

    private let displayTitle: String
    private let subtitleText: String?
    private let actionTitle: String?
    private let actionButtonColor: UIColor?

    // MARK: - UI Components

    private lazy var actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        var title = AttributedString(actionTitle ?? "")
        title.font = UIFont.preferredFont(forTextStyle: .headline)
        config.attributedTitle = title
        config.baseBackgroundColor = actionButtonColor ?? ThemeColor.primary
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = AppFactory.Label.largeTitle(alignment: .center)
        label.text = displayTitle
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = AppFactory.Label.body(alignment: .center)
        label.text = subtitleText
        return label
    }()

    // MARK: - Initializer

    init(
        title: String,
        subtitleText: String?,
        actionTitle: String?,
        actionButtonColor: UIColor?
    ) {
        self.displayTitle = title
        self.subtitleText = subtitleText
        self.actionTitle = actionTitle
        self.actionButtonColor = actionButtonColor
        super.init(frame: .zero)
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        self.displayTitle = "MyTMDB"
        self.subtitleText = nil
        self.actionTitle = nil
        self.actionButtonColor = nil
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(titleLabel)

        if subtitleText != nil {
            addSubview(subtitleLabel)
        }

        if actionTitle != nil {
            addSubview(actionButton)
        }
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.centerY.equalToSuperview().offset(-48)
        }

        if subtitleText != nil {
            subtitleLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(24)
            }
        }

        guard actionTitle != nil else { return }

        actionButton.snp.makeConstraints { make in
            let topAnchor = subtitleText == nil ? titleLabel.snp.bottom : subtitleLabel.snp.bottom
            make.top.equalTo(topAnchor).offset(32)
            make.leading.trailing.equalToSuperview().inset(32)
            make.height.equalTo(48)
        }
    }

    // MARK: - Actions

    @objc private func actionButtonTapped() {
        onActionTap?()
    }
}

// MARK: - PlaceholderActionConfirmation UIKit Mapping

private extension PlaceholderActionConfirmation {

    var confirmStyle: UIAlertAction.Style {
        switch self {
        case .logout:
            return .destructive

        case .leaveGuestMode, .returnToLogin:
            return .default
        }
    }

    var buttonBackgroundColor: UIColor {
        switch self {
        case .logout:
            return ThemeColor.systemRed

        case .leaveGuestMode, .returnToLogin:
            return ThemeColor.primary
        }
    }
}
