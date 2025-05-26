//
//  SettingsViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/26.
//

import Foundation
import UIKit
import SnapKit
import Combine

class SettingsViewController: UITableViewController {
    
    private let accountVM = AccountViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private enum Section: Int, CaseIterable {
        case account
        case appearance
    }
    
    private lazy var themeSwitch: UISwitch = {
        let switchButton = UISwitch()
        switchButton.isOn = UserDefaults.standard.bool(forKey: "isDarkMode")
        switchButton.addTarget(self, action: #selector(themeSwitchChanged(_:)), for: .valueChanged)
        return switchButton
    }()
    
    private func settingNavigationBar(){
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.title = "設定"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .account:     return 3
        case .appearance:  return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .account:
            return "帳戶"
        case .appearance:
            return "外觀"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let usernameText = accountVM.account?.username ?? "未登入"
        let userIdText: String
        if let id = accountVM.account?.id {
            userIdText = String(id)
        } else {
            userIdText = "無 ID"
        }
        guard let sec = Section(rawValue: indexPath.section) else { return cell }
        switch sec {
        case .account:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = usernameText
                cell.selectionStyle = .none
            case 1:
                cell.textLabel?.text = userIdText
                cell.selectionStyle = .none
            case 2:
                cell.textLabel?.text = "登出"
                cell.textLabel?.textColor = .systemRed
            default:
                break
            }
        case .appearance:
            cell.textLabel?.text = "深色模式"
            cell.accessoryView = themeSwitch
        }
        return cell
    }
    
    @objc private func themeSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "isDarkMode")
        applyTheme(isDark: sender.isOn)
    }
    
    private func applyTheme(isDark: Bool) {
        let style: UIUserInterfaceStyle = isDark ? .dark : .light
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = style
        }
    }
    
    private func bindAccount() {
        if let sessionId = UserDefaults.standard.string(forKey: "TMDBSessionID") {
            accountVM.loadAccount(sessionId: sessionId)
            accountVM.$account
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.tableView.reloadSections([Section.account.rawValue], with: .automatic)
                }
                .store(in: &cancellables)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemGroupedBackground
        bindAccount()
        settingNavigationBar()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sec = Section(rawValue: indexPath.section), sec == .account else { return }
        if indexPath.row == 2 {
            UserDefaults.standard.removeObject(forKey: "TMDBSessionID")
            UserDefaults.standard.removeObject(forKey: "TMDBAccountID")
            
            guard let windowScene = view.window?.windowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else { return }
            let loginVC = LoginViewController()
            let navigation = UINavigationController(rootViewController: loginVC)
            window.rootViewController = navigation
            window.makeKeyAndVisible()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
