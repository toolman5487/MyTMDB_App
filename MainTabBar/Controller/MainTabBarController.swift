//
//  MainTabBarController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import UIKit

// MARK: - MainTabBarVisibilityState

enum MainTabBarVisibilityState: Equatable {
    case visible
    case hiddenByScroll
}

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
    private let avatarProvider: MainTabBarAvatarProviding
    private var tabBarVisibilityState: MainTabBarVisibilityState = .visible
    private var pendingTransitionDirection: MainTabNavigationDirection?
    private var avatarTask: Task<Void, Never>?

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

    init(
        session: AuthSession,
        avatarProvider: MainTabBarAvatarProviding = MainTabBarAvatarService()
    ) {
        self.session = session
        self.viewModel = MainTabBarViewModel()
        self.avatarProvider = avatarProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.session = .loggedOut
        self.viewModel = MainTabBarViewModel()
        self.avatarProvider = MainTabBarAvatarService()
        super.init(coder: coder)
    }

    deinit {
        avatarTask?.cancel()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureTabBarAppearance()
        setupViewControllers()
        configureTabSwipeGesture()
        loadMemberCenterAvatarIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyTabBarVisibility(tabBarVisibilityState)
    }

    // MARK: - Tab Bar Visibility

    func setTabBarVisibility(_ visibilityState: MainTabBarVisibilityState, animated: Bool) {
        guard tabBarVisibilityState != visibilityState else {
            applyTabBarVisibility(visibilityState)
            return
        }

        tabBarVisibilityState = visibilityState

        let updates = {
            self.applyTabBarVisibility(visibilityState)
        }

        guard animated else {
            updates()
            return
        }

        UIView.animate(
            withDuration: TabBarVisibilityAnimation.duration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: updates
        ) { _ in
            self.applyTabBarVisibility(visibilityState)
        }
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

        case .series:
            let viewController = MainTVListViewController()
            viewController.title = item.title
            return viewController

        case .memberCenter:
            let viewController = MainMemberCenterViewController(session: session)
            viewController.title = item.title
            return viewController
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

    private func loadMemberCenterAvatarIfNeeded() {
        guard case .user(let sessionId) = session else { return }

        avatarTask?.cancel()
        avatarTask = Task { [weak self] in
            guard let self else { return }
            guard let image = await avatarProvider.fetchAvatarImage(sessionId: sessionId) else { return }
            guard !Task.isCancelled else { return }
            updateMemberCenterTabBarItemImage(image)
        }
    }

    private func updateMemberCenterTabBarItemImage(_ image: UIImage) {
        let items = viewModel.items
        guard let index = items.firstIndex(where: { $0.kind == .memberCenter }),
              let viewControllers,
              viewControllers.indices.contains(index) else {
            return
        }

        let viewController = viewControllers[index]
        let tabBarItem = viewController.tabBarItem
        tabBarItem?.image = image
        tabBarItem?.selectedImage = image
        tabBarItem?.title = nil
        viewController.tabBarItem = tabBarItem ?? makeTabBarItem(for: items[index])
    }

    private func refreshMemberCenterContentIfNeeded(for viewController: UIViewController) {
        guard case .user = session,
              let navigationController = viewController as? UINavigationController,
              let memberCenterViewController = navigationController.viewControllers.first as? MainMemberCenterViewController else {
            return
        }

        memberCenterViewController.refreshContentFromTabSelection()
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

        setTabBarVisibility(.visible, animated: false)
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
            y: tabBar.bounds.height
        )
    }

    private func applyTabBarVisibility(_ visibilityState: MainTabBarVisibilityState) {
        let isHidden = visibilityState == .hiddenByScroll

        tabBar.transform = .identity
        tabBar.frame = visibleTabBarFrame()
        tabBar.transform = isHidden ? hiddenTabBarTransform() : .identity
        tabBar.alpha = isHidden ? 0 : 1
        tabBar.isUserInteractionEnabled = !isHidden
    }

    private func visibleTabBarFrame() -> CGRect {
        let height = tabBar.bounds.height > 0 ? tabBar.bounds.height : tabBar.frame.height

        return CGRect(
            x: 0,
            y: view.bounds.height - height,
            width: view.bounds.width,
            height: height
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

        if targetIndex != selectedIndex {
            setTabBarVisibility(.visible, animated: false)
        }

        pendingTransitionDirection = viewModel.transitionDirection(
            from: selectedIndex,
            to: targetIndex
        )
        return true
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        refreshMemberCenterContentIfNeeded(for: viewController)
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
