//
//  GlassBaseViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import SnapKit
import UIKit

@MainActor
enum GlassBackgroundEffect {

    static func make(
        tintColor: UIColor? = ThemeColor.background.withAlphaComponent(0.2),
        fallbackStyle: UIBlurEffect.Style = .systemUltraThinMaterial
    ) -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            effect.tintColor = tintColor
            effect.isInteractive = false
            return effect
        }

        return UIBlurEffect(style: fallbackStyle)
    }
}

@MainActor
class GlassBaseViewController: BaseViewController {

    // MARK: - Properties

    private let glassBackgroundView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: nil)
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - Override Points

    var glassTintColor: UIColor? {
        ThemeColor.background.withAlphaComponent(0.18)
    }

    var fallbackBlurEffectStyle: UIBlurEffect.Style {
        .systemUltraThinMaterial
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        view.backgroundColor = .clear
        glassBackgroundView.effect = makeGlassBackgroundEffect()
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        view.insertSubview(glassBackgroundView, at: 0)
    }

    override func setupConstraints() {
        super.setupConstraints()

        glassBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Private Methods

    private func makeGlassBackgroundEffect() -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            effect.tintColor = glassTintColor
            effect.isInteractive = false
            return effect
        }

        return UIBlurEffect(style: fallbackBlurEffectStyle)
    }
}
