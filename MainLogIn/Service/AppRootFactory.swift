//
//  AppRootFactory.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import UIKit

// MARK: - AppRootFactory

enum AppRootFactory {

    @MainActor
    static func makeLoadingViewController() -> UIViewController {
        RootLoadingViewController()
    }

    @MainActor
    static func makeRootViewController(for session: AuthSession) -> UIViewController {
        switch session {
        case .loggedOut:
            return UINavigationController(rootViewController: LoginViewController())

        case .guest, .user:
            return MainTabBarController(session: session)
        }
    }

    @MainActor
    static func replaceRoot(in window: UIWindow, for session: AuthSession) {
        window.rootViewController = makeRootViewController(for: session)
        window.makeKeyAndVisible()
    }
}

// MARK: - AuthSessionValidator

struct AuthSessionValidator: Sendable {

    func validatedSession(_ session: AuthSession) async -> AuthSession {
        switch session {
        case .loggedOut, .guest:
            return session

        case .user(let sessionId):
            return await validateUserSession(sessionId: sessionId)
        }
    }

    private func validateUserSession(sessionId: String) async -> AuthSession {
        do {
            _ = try await AccountService().fetchAccount(sessionId: sessionId)
            return .user(sessionId: sessionId)
        } catch let error as NetworkError where [401, 403].contains(error.statusCode ?? 0) {
            AppLogger.authentication.warning(
                "Stored user session is unauthorized: \(error.statusCode ?? 0, privacy: .public)"
            )
            return .loggedOut
        } catch {
            AppLogger.authentication.error(
                "Stored user session validation failed: \(error.errorMessage.message, privacy: .public)"
            )
            return .user(sessionId: sessionId)
        }
    }
}

// MARK: - AuthFlowCoordinating

@MainActor
protocol AuthFlowCoordinating {
    func finishUserLogin(sessionId: String, from sourceViewController: UIViewController) async throws
    func finishGuestLogin(sessionId: String, from sourceViewController: UIViewController)
}

// MARK: - AuthFlowCoordinator

@MainActor
final class AuthFlowCoordinator: AuthFlowCoordinating {

    // MARK: - Properties

    private let sessionStore: SessionStoring
    private let accountService: AccountServiceProtocol
    private let userProfileStore: UserProfileStoring

    // MARK: - Initialization

    init(
        sessionStore: SessionStoring = SessionStore(),
        accountService: AccountServiceProtocol = AccountService(),
        userProfileStore: UserProfileStoring = UserProfileStore()
    ) {
        self.sessionStore = sessionStore
        self.accountService = accountService
        self.userProfileStore = userProfileStore
    }

    // MARK: - AuthFlowCoordinating

    func finishUserLogin(sessionId: String, from sourceViewController: UIViewController) async throws {
        let session = AuthSession.user(sessionId: sessionId)
        sessionStore.save(session)

        let account = try await accountService.fetchAccount(sessionId: sessionId)
        userProfileStore.save(account: account)
        replaceRoot(from: sourceViewController, for: session)
    }

    func finishGuestLogin(sessionId: String, from sourceViewController: UIViewController) {
        let session = AuthSession.guest(sessionId: sessionId)
        sessionStore.save(session)
        userProfileStore.clear()
        replaceRoot(from: sourceViewController, for: session)
    }

    // MARK: - Private Methods

    private func replaceRoot(from sourceViewController: UIViewController, for session: AuthSession) {
        guard let window = sourceViewController.view.window else {
            AppLogger.navigation.warning(
                "Auth flow root replacement failed because source view has no window."
            )
            return
        }

        AppRootFactory.replaceRoot(in: window, for: session)
    }
}

// MARK: - RootLoadingViewController

@MainActor
private final class RootLoadingViewController: UIViewController {

    // MARK: - UI Components

    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .large)
        indicatorView.color = ThemeColor.primary
        indicatorView.hidesWhenStopped = false
        return indicatorView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "正在檢查登入狀態"
        label.textColor = ThemeColor.textSecondary
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.background
        setupHierarchy()
        setupConstraints()
        activityIndicatorView.startAnimating()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        view.addSubview(activityIndicatorView)
        view.addSubview(titleLabel)
    }

    private func setupConstraints() {
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: activityIndicatorView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }
}
