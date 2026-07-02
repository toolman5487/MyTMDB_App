//
//  BaseRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import SafariServices
import UIKit

// MARK: - RouterPresentation

enum RouterPresentation {
    case push
    case present
    case fullScreen
    case formSheet
    case pageSheet(RouterPageSheetConfiguration)
    case popover(RouterPopoverConfiguration)
    case safari(URL)
}

// MARK: - RouterPageSheetConfiguration

struct RouterPageSheetConfiguration {
    let detents: [UISheetPresentationController.Detent]
    let prefersGrabber: Bool
    let embedInNavigationController: Bool

    init(
        detents: [UISheetPresentationController.Detent] = [.large()],
        prefersGrabber: Bool = true,
        embedInNavigationController: Bool = true
    ) {
        self.detents = detents
        self.prefersGrabber = prefersGrabber
        self.embedInNavigationController = embedInNavigationController
    }

    static let medium = RouterPageSheetConfiguration(detents: [.medium()])
    static let large = RouterPageSheetConfiguration(detents: [.large()])
    static let mediumAndLarge = RouterPageSheetConfiguration(detents: [.medium(), .large()])
}

// MARK: - RouterPopoverConfiguration

struct RouterPopoverConfiguration {
    let sourceView: UIView
    let sourceRect: CGRect
    let permittedArrowDirections: UIPopoverArrowDirection

    init(
        sourceView: UIView,
        sourceRect: CGRect? = nil,
        permittedArrowDirections: UIPopoverArrowDirection = .any
    ) {
        self.sourceView = sourceView
        self.sourceRect = sourceRect ?? sourceView.bounds
        self.permittedArrowDirections = permittedArrowDirections
    }
}

// MARK: - BaseRouter

@MainActor
class BaseRouter {

    // MARK: - Properties

    private(set) weak var sourceViewController: UIViewController?

    // MARK: - Initialization

    init(sourceViewController: UIViewController) {
        self.sourceViewController = sourceViewController
    }

    // MARK: - Presentation

    func show(_ viewController: UIViewController, using presentation: RouterPresentation) {
        guard let sourceViewController else { return }

        switch presentation {
        case .push:
            sourceViewController.navigationController?.pushViewController(
                viewController,
                animated: true
            )

        case .present:
            sourceViewController.present(viewController, animated: true)

        case .fullScreen:
            viewController.modalPresentationStyle = .fullScreen
            sourceViewController.present(viewController, animated: true)

        case .formSheet:
            viewController.modalPresentationStyle = .formSheet
            sourceViewController.present(viewController, animated: true)

        case .pageSheet(let configuration):
            let presentedViewController = makePageSheetViewController(
                from: viewController,
                configuration: configuration
            )
            sourceViewController.present(presentedViewController, animated: true)

        case .popover(let configuration):
            viewController.modalPresentationStyle = .popover

            if let popover = viewController.popoverPresentationController {
                popover.sourceView = configuration.sourceView
                popover.sourceRect = configuration.sourceRect
                popover.permittedArrowDirections = configuration.permittedArrowDirections
            }

            sourceViewController.present(viewController, animated: true)

        case .safari(let url):
            let safariViewController = SFSafariViewController(url: url)
            sourceViewController.present(safariViewController, animated: true)
        }
    }

    // MARK: - Private Methods

    private func makePageSheetViewController(
        from viewController: UIViewController,
        configuration: RouterPageSheetConfiguration
    ) -> UIViewController {
        let presentedViewController: UIViewController

        if configuration.embedInNavigationController {
            presentedViewController = UINavigationController(rootViewController: viewController)
        } else {
            presentedViewController = viewController
        }

        presentedViewController.modalPresentationStyle = .pageSheet

        if let sheet = presentedViewController.sheetPresentationController {
            sheet.detents = configuration.detents
            sheet.prefersGrabberVisible = configuration.prefersGrabber
        }

        return presentedViewController
    }
}
