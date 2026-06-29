//
//  MainTabBarController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import SnapKit
import UIKit

// MARK: - MainTabBarController

@MainActor
final class MainTabBarController: BaseViewController {

    // MARK: - Properties

    private let session: AuthSession
    private let items: [MainTabBarItem]
    private var selectedIndex = 0
    private lazy var pages: [UIViewController] = makePages()

    // MARK: - UI Components

    private lazy var pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    private let tabBarView = MainTabBarView()

    // MARK: - Initializer

    init(session: AuthSession) {
        self.session = session
        self.items = MainTabBarItem.items(for: session)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.session = .loggedOut
        self.items = []
        super.init(coder: coder)
    }

    // MARK: - Template Methods

    override func configureView() {
        title = items.first?.title
        navigationItem.largeTitleDisplayMode = .never
        pageViewController.dataSource = self
        pageViewController.delegate = self
        tabBarView.delegate = self
        tabBarView.configure(items: items, selectedIndex: selectedIndex)
    }

    override func setupHierarchy() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        view.addSubview(tabBarView)
        pageViewController.didMove(toParent: self)
    }

    override func setupConstraints() {
        pageViewController.view.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(tabBarView.snp.top)
        }

        tabBarView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-56)
        }
    }

    override func bindViewModel() {
        guard let firstPage = pages.first else { return }
        pageViewController.setViewControllers([firstPage], direction: .forward, animated: false)
        updateSelectedIndex(0)
    }

    // MARK: - Private Methods

    private func makePages() -> [UIViewController] {
        items.map { item in
            ViewController(displayTitle: item.placeholderTitle)
        }
    }

    private func moveToPage(at index: Int) {
        guard pages.indices.contains(index), index != selectedIndex else { return }
        let direction: UIPageViewController.NavigationDirection = index > selectedIndex ? .forward : .reverse
        updateSelectedIndex(index)
        pageViewController.setViewControllers([pages[index]], direction: direction, animated: false)
    }

    private func updateSelectedIndex(_ index: Int) {
        guard items.indices.contains(index) else { return }
        selectedIndex = index
        title = items[index].title
        tabBarView.updateSelection(index)
    }
}

// MARK: - MainTabBarViewDelegate

extension MainTabBarController: MainTabBarViewDelegate {
    func mainTabBarView(_ view: MainTabBarView, didSelect item: MainTabBarItem, at index: Int) {
        moveToPage(at: index)
    }
}

// MARK: - UIPageViewControllerDataSource

extension MainTabBarController: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), pages.indices.contains(index - 1) else {
            return nil
        }
        return pages[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), pages.indices.contains(index + 1) else {
            return nil
        }
        return pages[index + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension MainTabBarController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentPage = pageViewController.viewControllers?.first,
              let index = pages.firstIndex(of: currentPage) else {
            return
        }
        updateSelectedIndex(index)
    }
}
