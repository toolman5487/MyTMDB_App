//
//  SceneDelegate.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var composition: AppComposition?
    private var launchSessionTask: Task<Void, Never>?
    private var pendingIntentDestination: AppIntentDestination?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        let composition = AppComposition(
            onSessionChanged: { [weak self] session in
                self?.replaceRoot(for: session)
            },
            onInterfaceLanguageChanged: { [weak self] session in
                self?.replaceRoot(for: session)
            }
        )

        window.rootViewController = composition.makeRootLoadingViewController()

        self.composition = composition
        self.window = window
        window.makeKeyAndVisible()

        pendingIntentDestination = connectionOptions.urlContexts
            .compactMap { AppIntentDestination(url: $0.url) }
            .first

        resolveLaunchSession()
    }

    private func resolveLaunchSession() {
        guard let composition else { return }
        let sessionResolver = composition.makeLaunchSessionResolver()

        launchSessionTask?.cancel()
        launchSessionTask = Task(priority: .userInitiated) { [weak self] in
            do {
                let resolvedSession = try await sessionResolver.resolve()
                guard !Task.isCancelled, let self else { return }
                guard showInitialRoot(for: resolvedSession) else { return }
                await routePendingIntentDestinationIfNeeded()
            } catch is CancellationError {
                return
            } catch is AuthSessionError {
                guard !Task.isCancelled, let self else { return }
                AppLogger.security.error("Secure authentication session resolution failed")
                showSessionValidationFailure()
            } catch {
                guard !Task.isCancelled, let self else { return }
                AppLogger.authentication.error("Guest session creation failed")
                showGuestLaunchFailure()
            }
        }
    }

    @MainActor
    private func showInitialRoot(for session: AuthSession) -> Bool {
        guard let window, let composition else { return false }

        switch session {
        case .loggedOut:
            AppLogger.authentication.error("Launch session resolved to logged-out state")
            showGuestLaunchFailure()
            return false

        case .guest, .user:
            window.rootViewController = composition.makeMainTabBarController(
                session: session,
                initialTab: .home
            )
            window.makeKeyAndVisible()
            return true
        }
    }

    @MainActor
    private func showSessionValidationFailure() {
        guard let composition,
              let rootViewController = window?.rootViewController,
              rootViewController.presentedViewController == nil else {
            return
        }

        let localization = composition.currentInterfaceLocalization

        let alert = UIAlertController(
            title: localization.string(
                "session_validation.failure.title",
                defaultValue: "Unable to Read Sign-in Status"
            ),
            message: localization.string(
                "session_validation.failure.message",
                defaultValue: "Sign-in data cannot be read securely. Unlock the device and try again."
            ),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: localization.string("common.action.retry", defaultValue: "Retry"),
            style: .default
        ) { [weak self, weak rootViewController] _ in
            rootViewController?.dismiss(animated: true) {
                self?.resolveLaunchSession()
            }
        })
        rootViewController.present(alert, animated: true)
    }

    @MainActor
    private func showGuestLaunchFailure() {
        guard let composition,
              let rootViewController = window?.rootViewController,
              rootViewController.presentedViewController == nil else {
            return
        }

        let localization = composition.currentInterfaceLocalization

        let alert = UIAlertController(
            title: localization.string(
                "guest_launch.failure.title",
                defaultValue: "Unable to Start Guest Mode"
            ),
            message: localization.string(
                "guest_launch.failure.message",
                defaultValue: "Check your connection and try again, or sign in instead."
            ),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: localization.string("common.action.retry", defaultValue: "Retry"),
            style: .default
        ) { [weak self, weak rootViewController] _ in
            rootViewController?.dismiss(animated: true) {
                self?.resolveLaunchSession()
            }
        })
        alert.addAction(UIAlertAction(
            title: localization.string("common.action.sign_in", defaultValue: "Sign In"),
            style: .cancel
        ) { [weak self] _ in
            self?.showLoginRoot()
        })
        rootViewController.present(alert, animated: true)
    }

    @MainActor
    private func showLoginRoot() {
        guard let window, let composition else { return }
        pendingIntentDestination = nil
        window.rootViewController = composition.makeLoginNavigationController(context: .root)
        window.makeKeyAndVisible()
    }

    @MainActor
    private func routePendingIntentDestinationIfNeeded() async {
        guard let destination = pendingIntentDestination,
              let window,
              let composition else {
            return
        }
        pendingIntentDestination = nil
        _ = await AppIntentNavigator.open(
            destination,
            in: window,
            sessionResolver: composition.makeAppIntentSessionResolver()
        )
    }

    @MainActor
    private func replaceRoot(for session: AuthSession) {
        guard let window, let composition else { return }

        switch session {
        case .loggedOut:
            window.rootViewController = composition.makeLoginNavigationController(context: .root)

        case .guest, .user:
            let previousTab = (window.rootViewController as? MainTabBarController)?.selectedTabKind
            window.rootViewController = composition.makeMainTabBarController(
                session: session,
                initialTab: previousTab
            )
        }

        window.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let window, let composition else { return }

        for context in URLContexts {
            guard let destination = AppIntentDestination(url: context.url) else {
                continue
            }

            Task(priority: .userInitiated) { @MainActor in
                _ = await AppIntentNavigator.open(
                    destination,
                    in: window,
                    sessionResolver: composition.makeAppIntentSessionResolver()
                )
            }
            return
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        launchSessionTask?.cancel()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
    }
    
    
}
