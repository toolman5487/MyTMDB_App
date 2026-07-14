//
//  LoginViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import UIKit
import SnapKit
import Lottie
import Observation

@MainActor
final class LoginViewController: BaseViewController {

    // MARK: - Properties

    private let loginVM: LoginViewModel
    private let authCoordinator: AuthFlowCoordinating
    private lazy var router: LoginRouting = LoginRouter(sourceViewController: self)

    private var currentPage: AuthPage = .login
    private var authFlowTask: Task<Void, Never>?

    private lazy var loginPageView = LoginPageView()
    private lazy var guestPageView = GuestPageView()
    private lazy var registerPageView = RegisterPageView()

    private lazy var pageViews: [AuthPageView] = [
        loginPageView,
        guestPageView,
        registerPageView,
    ]

    // MARK: - Initialization

    init(
        loginViewModel: LoginViewModel = LoginViewModel(),
        authCoordinator: AuthFlowCoordinating = AuthFlowCoordinator()
    ) {
        self.loginVM = loginViewModel
        self.authCoordinator = authCoordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.loginVM = LoginViewModel()
        self.authCoordinator = AuthFlowCoordinator()
        super.init(coder: coder)
    }

    deinit {
        authFlowTask?.cancel()
    }

    // MARK: - UI Components

    private let pageScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        return scrollView
    }()

    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "loadingAir")
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        return view
    }()

    private let loadingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.4)
        view.isHidden = true
        return view
    }()

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.numberOfPages = AuthPage.allCases.count
        control.currentPage = 0
        control.currentPageIndicatorTintColor = .label
        control.pageIndicatorTintColor = .tertiaryLabel
        return control
    }()

    private lazy var errorMessageView: ErrorMessageView = {
        let view = ErrorMessageView()
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    // MARK: - Lifecycle

    override func configureView() {
        setupNavigationBar()
        setupPageDelegates()
    }

    override func setupHierarchy() {
        pageScrollView.addSubview(loginPageView)
        pageScrollView.addSubview(guestPageView)
        pageScrollView.addSubview(registerPageView)

        view.addSubview(pageScrollView)
        view.addSubview(pageControl)
        view.addSubview(errorMessageView)
        view.addSubview(loadingOverlayView)
        view.addSubview(animationView)
    }

    override func setupConstraints() {
        pageScrollView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(AuthPageStyle.Layout.pageHeight)
        }

        loginPageView.snp.makeConstraints { make in
            make.top.equalTo(pageScrollView.contentLayoutGuide)
            make.bottom.equalTo(pageScrollView.contentLayoutGuide)
            make.leading.equalTo(pageScrollView.contentLayoutGuide)
            make.width.equalTo(pageScrollView.frameLayoutGuide)
            make.height.equalTo(AuthPageStyle.Layout.pageHeight)
        }

        guestPageView.snp.makeConstraints { make in
            make.top.bottom.width.equalTo(loginPageView)
            make.leading.equalTo(loginPageView.snp.trailing)
        }

        registerPageView.snp.makeConstraints { make in
            make.top.bottom.width.equalTo(loginPageView)
            make.leading.equalTo(guestPageView.snp.trailing)
            make.trailing.equalTo(pageScrollView.contentLayoutGuide)
        }

        pageControl.snp.makeConstraints { make in
            make.top.equalTo(pageScrollView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        errorMessageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualTo(pageScrollView.snp.top).offset(-8)
        }

        loadingOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(300)
        }
    }

    override func bindViewModel() {
        pageScrollView.delegate = self
        pageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)

        handleLoginState(loginVM.state)
        observeLoginState()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = AuthPage.login.title
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func setupPageDelegates() {
        loginPageView.delegate = self
        guestPageView.delegate = self
        registerPageView.delegate = self
    }

    // MARK: - Actions

    @objc private func pageControlChanged() {
        scrollToPage(AuthPage(rawValue: pageControl.currentPage) ?? .login, animated: true)
    }

    // MARK: - Observation

    private func observeLoginState() {
        withObservationTracking {
            _ = loginVM.state
        } onChange: { [weak self] in
            Task(priority: .userInitiated) { @MainActor in
                guard let self else { return }
                self.handleLoginState(self.loginVM.state)
                self.observeLoginState()
            }
        }
    }

    // MARK: - State Handling

    private func handleLoginState(_ state: LoginState) {
        switch state {
        case .idle:
            setLoadingOverlayVisible(false)
            setActionButtonsEnabled(true)

        case .loading:
            hideErrorMessage()
            setLoadingOverlayVisible(true)
            setActionButtonsEnabled(false)

        case .success(let sessionId):
            hideErrorMessage()
            setLoadingOverlayVisible(true)
            setActionButtonsEnabled(false)
            finishUserLogin(sessionId: sessionId)

        case .guestSuccess(let guestSessionId):
            hideErrorMessage()
            setLoadingOverlayVisible(true)
            setActionButtonsEnabled(false)
            finishGuestLogin(sessionId: guestSessionId)

        case .failed(let message):
            setLoadingOverlayVisible(false)
            setActionButtonsEnabled(true)
            showErrorMessage(message)
        }
    }

    // MARK: - Helpers

    private func finishUserLogin(sessionId: String) {
        authFlowTask?.cancel()
        authFlowTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            do {
                try await authCoordinator.finishUserLogin(sessionId: sessionId, from: self)
            } catch {
                guard !Task.isCancelled else { return }
                setLoadingOverlayVisible(false)
                setActionButtonsEnabled(true)
                showErrorMessage(error.errorMessage)
            }
        }
    }

    private func finishGuestLogin(sessionId: String) {
        authFlowTask?.cancel()
        authCoordinator.finishGuestLogin(sessionId: sessionId, from: self)
    }

    private func scrollToPage(_ page: AuthPage, animated: Bool) {
        let offsetX = CGFloat(page.rawValue) * pageScrollView.bounds.width
        pageScrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: animated)
        currentPage = page
        updateCurrentPage(page)
    }

    private func updateCurrentPage(_ page: AuthPage) {
        pageControl.currentPage = page.rawValue
        navigationItem.title = page.title
    }

    private func setActionButtonsEnabled(_ isEnabled: Bool) {
        pageViews.forEach { $0.setInteractionEnabled(isEnabled) }
        pageScrollView.isScrollEnabled = isEnabled
        pageControl.isEnabled = isEnabled
    }

    private func showErrorMessage(_ message: ErrorMessage) {
        errorMessageView.configure(with: message) { [weak self] in
            self?.retryCurrentPageAction()
        }
        errorMessageView.isHidden = false

        UIView.animate(withDuration: 0.2) {
            self.errorMessageView.alpha = 1
        }
    }

    private func hideErrorMessage() {
        guard !errorMessageView.isHidden else { return }

        UIView.animate(withDuration: 0.2) {
            self.errorMessageView.alpha = 0
        } completion: { [weak self] _ in
            self?.errorMessageView.isHidden = true
        }
    }

    private func retryCurrentPageAction() {
        switch currentPage {
        case .login:
            Task(priority: .userInitiated) {
                await loginVM.login()
            }

        case .guest:
            Task(priority: .userInitiated) {
                await loginVM.continueAsGuest()
            }

        case .register:
            break
        }
    }

    private func setLoadingOverlayVisible(_ visible: Bool) {
        loadingOverlayView.isHidden = !visible
        animationView.isHidden = !visible

        switch visible {
        case true:
            animationView.play()
        case false:
            animationView.stop()
        }
    }

}

// MARK: - LoginPageViewDelegate

@MainActor
extension LoginViewController: LoginPageViewDelegate {
    func loginPageView(_ view: LoginPageView, didUpdateUsername username: String) {
        hideErrorMessage()
        loginVM.username = username
    }

    func loginPageView(_ view: LoginPageView, didUpdatePassword password: String) {
        hideErrorMessage()
        loginVM.password = password
    }

    func loginPageViewDidTapLogin(_ view: LoginPageView) {
        view.endEditing(true)
        Task(priority: .userInitiated) {
            await loginVM.login()
        }
    }
}

// MARK: - GuestPageViewDelegate

@MainActor
extension LoginViewController: GuestPageViewDelegate {
    func guestPageViewDidTapContinue(_ view: GuestPageView) {
        Task(priority: .userInitiated) {
            await loginVM.continueAsGuest()
        }
    }
}

// MARK: - RegisterPageViewDelegate

@MainActor
extension LoginViewController: RegisterPageViewDelegate {
    func registerPageViewDidTapRegister(_ view: RegisterPageView) {
        guard let url = APIConfig.tmdbSignupURL else { return }
        router.openSignup(url: url)
    }
}

// MARK: - UIScrollViewDelegate

@MainActor
extension LoginViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        guard let page = AuthPage(rawValue: pageIndex) else { return }
        currentPage = page
        pageControl.currentPage = page.rawValue
        navigationItem.title = page.title
        hideErrorMessage()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}
