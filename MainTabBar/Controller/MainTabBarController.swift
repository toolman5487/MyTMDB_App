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

    private enum TabSwipe {
        static let horizontalDominanceRatio: CGFloat = 1.4
        static let minimumHorizontalTranslation: CGFloat = 80
        static let minimumHorizontalVelocity: CGFloat = 320
        static let scrollableWidthTolerance: CGFloat = 1
    }

    // MARK: - Properties

    private let session: AuthSession
    private let viewModel: MainTabBarViewModel
    private var isTabBarHiddenByScroll = false
    private var pendingTransitionDirection: MainTabNavigationDirection?

    // MARK: - UI Components

    private lazy var tabSwipeGestureRecognizer: UIPanGestureRecognizer = {
        let gestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleTabSwipe)
        )
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        return gestureRecognizer
    }()

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
        delegate = self
        configureTabBarAppearance()
        setupViewControllers()
        configureTabSwipeGesture()
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
            return MainHomeViewController()

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

    private func configureTabSwipeGesture() {
        view.addGestureRecognizer(tabSwipeGestureRecognizer)
    }

    // MARK: - Tab Selection

    @objc private func handleTabSwipe(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.state == .ended else { return }
        guard !isSelectedSearchInteractionActive else { return }
        guard let direction = tabNavigationDirection(for: gestureRecognizer) else { return }
        guard let transition = viewModel.selectionTransition(
            from: selectedIndex,
            direction: direction
        ) else {
            return
        }

        selectTab(at: transition.targetIndex, direction: transition.direction)
    }

    private func selectTab(at index: Int, direction: MainTabNavigationDirection) {
        guard index != selectedIndex else { return }

        pendingTransitionDirection = direction
        selectedIndex = index
    }

    private func tabNavigationDirection(
        for gestureRecognizer: UIPanGestureRecognizer
    ) -> MainTabNavigationDirection? {
        let velocity = gestureRecognizer.velocity(in: view)
        let translation = gestureRecognizer.translation(in: view)

        if abs(velocity.x) >= TabSwipe.minimumHorizontalVelocity {
            return velocity.x < 0 ? .next : .previous
        }

        guard abs(translation.x) >= TabSwipe.minimumHorizontalTranslation else {
            return nil
        }

        return translation.x < 0 ? .next : .previous
    }

    private func isTouchInsideHorizontalScrollView(_ view: UIView?) -> Bool {
        var currentView = view

        while let inspectedView = currentView {
            if let scrollView = inspectedView as? UIScrollView,
               scrollView.contentSize.width > scrollView.bounds.width + TabSwipe.scrollableWidthTolerance {
                return true
            }

            currentView = inspectedView.superview
        }

        return false
    }

    private var isSelectedNavigationControllerAtRoot: Bool {
        guard let navigationController = selectedViewController as? UINavigationController else {
            return true
        }

        return navigationController.viewControllers.count == 1
    }

    private var isSelectedSearchInteractionActive: Bool {
        guard let navigationController = selectedViewController as? UINavigationController,
              let searchController = navigationController.topViewController?.navigationItem.searchController else {
            return false
        }

        return searchController.isActive || searchController.searchBar.searchTextField.isFirstResponder
    }

    private func hiddenTabBarTransform() -> CGAffineTransform {
        CGAffineTransform(
            translationX: 0,
            y: tabBar.bounds.height + view.safeAreaInsets.bottom
        )
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MainTabBarController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === tabSwipeGestureRecognizer,
              let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        guard isSelectedNavigationControllerAtRoot else { return false }
        guard !isSelectedSearchInteractionActive else { return false }

        let velocity = gestureRecognizer.velocity(in: view)
        guard abs(velocity.x) > abs(velocity.y) * TabSwipe.horizontalDominanceRatio else {
            return false
        }

        let direction: MainTabNavigationDirection = velocity.x < 0 ? .next : .previous
        return viewModel.selectionTransition(from: selectedIndex, direction: direction) != nil
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard gestureRecognizer === tabSwipeGestureRecognizer else { return true }
        return !isTouchInsideHorizontalScrollView(touch.view)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer === tabSwipeGestureRecognizer
    }
}

// MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {

    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard let targetIndex = viewControllers?.firstIndex(of: viewController) else {
            pendingTransitionDirection = nil
            return true
        }

        pendingTransitionDirection = viewModel.transitionDirection(
            from: selectedIndex,
            to: targetIndex
        )
        return true
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        animationControllerForTransitionFrom fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let direction = pendingTransitionDirection else { return nil }
        pendingTransitionDirection = nil
        return MainTabTransitionAnimator(direction: direction)
    }
}

// MARK: - MainTabTransitionAnimator

private final class MainTabTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    // MARK: - Properties

    private let direction: MainTabNavigationDirection

    // MARK: - Initialization

    init(direction: MainTabNavigationDirection) {
        self.direction = direction
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.24
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to),
              let toViewController = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toViewController)
        let horizontalOffset = direction == .next ? containerView.bounds.width : -containerView.bounds.width

        toView.frame = finalFrame.offsetBy(dx: horizontalOffset, dy: 0)
        containerView.addSubview(toView)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: {
                fromView.frame = fromView.frame.offsetBy(dx: -horizontalOffset, dy: 0)
                toView.frame = finalFrame
            },
            completion: { finished in
                let wasCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(finished && !wasCancelled)
            }
        )
    }
}
