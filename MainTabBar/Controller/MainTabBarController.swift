//
//  MainTabBarController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import UIKit

// MARK: - MainTabBarController

@MainActor
final class MainTabBarController: UITabBarController {

    // MARK: - Properties

    private let session: AuthSession
    private let viewModel: MainTabBarViewModel

    // MARK: - Initialization

    init(session: AuthSession) {
        self.session = session
        self.viewModel = MainTabBarViewModel(session: session)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.session = .loggedOut
        self.viewModel = MainTabBarViewModel(session: .loggedOut)
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBarAppearance()
        setupViewControllers()
    }

    // MARK: - Setup

    private func setupViewControllers() {
        viewControllers = viewModel.items.map { item in
            makeNavigationController(for: item)
        }
    }

    private func makeNavigationController(for item: MainTabItem) -> UINavigationController {
        let viewController = ViewController(
            displayTitle: item.title,
            tabKind: item.kind,
            session: session
        )
        viewController.tabBarItem = makeTabBarItem(for: item)

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem = makeTabBarItem(for: item)
        return navigationController
    }

    private func makeTabBarItem(for item: MainTabItem) -> UITabBarItem {
        UITabBarItem(
            title: nil,
            image: UIImage(systemName: item.imageName),
            selectedImage: UIImage(systemName: item.selectedImageName)
        )
    }

    private func configureTabBarAppearance() {
        tabBar.tintColor = ThemeColor.primary
        tabBar.unselectedItemTintColor = ThemeColor.textSecondary

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ThemeColor.backgroundSecondary
        appearance.shadowColor = ThemeColor.separator

        tabBar.standardAppearance = appearance

        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}
