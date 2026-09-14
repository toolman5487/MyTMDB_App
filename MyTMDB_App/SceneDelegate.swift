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
        let composition = AppComposition { [weak self] session in
            self?.replaceRoot(for: session)
        }

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
            let validatedSession = await sessionValidator.validatedStoredSession()
            guard !Task.isCancelled, let self else { return }
            replaceRoot(for: validatedSession)
            await routePendingIntentDestinationIfNeeded()
        }
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
            window.rootViewController = composition.makeLoginNavigationController()

        case .guest, .user:
            window.rootViewController = composition.makeMainTabBarController(session: session)
        }

        window.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let window, let composition else { return }

        for context in URLContexts {
            guard let destination = AppIntentDestination(url: context.url) else {
                continue
            }

            Task { @MainActor in
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
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}
