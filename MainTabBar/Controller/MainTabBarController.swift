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

    // MARK: - Constants

    private enum TabBarVisibilityAnimation {
        static let duration: TimeInterval = 0.24
    }

    // MARK: - Properties

    private let session: AuthSession
    private let viewModel: MainTabBarViewModel
    private var isTabBarHiddenByScroll = false

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard isTabBarHiddenByScroll else { return }
        tabBar.transform = hiddenTabBarTransform()
    }

    // MARK: - Tab Bar Visibility

    func setTabBarHiddenByScroll(_ isHidden: Bool, animated: Bool) {
        guard isTabBarHiddenByScroll != isHidden else { return }

        isTabBarHiddenByScroll = isHidden

        let updates = {
            self.tabBar.transform = isHidden ? self.hiddenTabBarTransform() : .identity
            self.tabBar.alpha = isHidden ? 0 : 1
        }

        let completion: (Bool) -> Void = { _ in
            self.tabBar.isUserInteractionEnabled = !isHidden
        }

        if isHidden {
            tabBar.isUserInteractionEnabled = false
        }

        guard animated else {
            updates()
            completion(true)
            return
        }

        UIView.animate(
            withDuration: TabBarVisibilityAnimation.duration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: updates,
            completion: completion
        )
    }

    // MARK: - Setup

    private func setupViewControllers() {
        viewControllers = viewModel.items.map { item in
            makeNavigationController(for: item)
        }
    }

    private func makeNavigationController(for item: MainTabItem) -> UINavigationController {
        let viewController = makeContentViewController(for: item)
        viewController.tabBarItem = makeTabBarItem(for: item)

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem = makeTabBarItem(for: item)
        return navigationController
    }

    private func makeContentViewController(for item: MainTabItem) -> UIViewController {
        switch item.kind {
        case .home:
            let viewController = MainHomeViewController()
            viewController.title = item.title
            return viewController

        case .movie:
            let viewController = MainMovieListViewController()
            viewController.title = item.title
            return viewController

        case .series, .memberCenter:
            return ViewController(
                displayTitle: item.title,
                tabKind: item.kind,
                session: session
            )
        }
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

    private func hiddenTabBarTransform() -> CGAffineTransform {
        CGAffineTransform(
            translationX: 0,
            y: tabBar.bounds.height + view.safeAreaInsets.bottom
        )
    }
}
