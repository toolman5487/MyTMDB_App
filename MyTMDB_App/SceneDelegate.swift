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
    private var sessionValidationTask: Task<Void, Never>?
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

        validateStoredSession()
    }

    private func validateStoredSession() {
        guard let composition else { return }
        let sessionValidator = composition.makeSessionValidator()

        sessionValidationTask?.cancel()
        sessionValidationTask = Task(priority: .userInitiated) { [weak self] in
            do {
                let validatedSession = try await sessionValidator.validatedStoredSession()
                guard !Task.isCancelled, let self else { return }
                replaceRoot(for: validatedSession)
                await routePendingIntentDestinationIfNeeded()
            } catch {
                guard !Task.isCancelled, let self else { return }
                AppLogger.security.error("Secure authentication session validation failed")
                showSessionValidationFailure()
            }
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
        ) { [weak self] _ in
            self?.validateStoredSession()
        })
        rootViewController.present(alert, animated: true)
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
        sessionValidationTask?.cancel()
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
