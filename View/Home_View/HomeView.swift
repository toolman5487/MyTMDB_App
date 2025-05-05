//
//  HomeView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import UIKit
import SnapKit
import Combine
import SDWebImage

class HomeView: UIViewController{
    
    private let accountVM = AccountViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let searchResultsView = SearchResultsView()
    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: searchResultsView)
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search Movies, TV, People"
        search.searchResultsUpdater = searchResultsView
        return search
    }()
    
    private let avatarImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = 50
        image.layer.masksToBounds = true
        image.tintColor = .label
        image.image = UIImage(systemName: "person.circle")
        return image
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.demiBold(ofSize: 20)
        label.textColor = .label
        label.text = "Username"
        return label
    }()
    
    
    private func bindAccountVM() {
        guard let sessionId = UserDefaults.standard.string(forKey: "TMDBSessionID") else { return }
        accountVM.loadAccount(sessionId: sessionId)
        accountVM.$account
            .compactMap { $0 }
            .sink { [weak self] account in
                self?.usernameLabel.text = account.username
                if let path = account.avatar.tmdb.avatar_path {
                    let url = URL(string: "https://image.tmdb.org/t/p/w200\(path)")
                    self?.avatarImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.circle"))
                } else {
                    let hash = account.avatar.gravatar.hash
                    let gravatarURL = URL(string: "https://www.gravatar.com/avatar/\(hash)?s=200&d=identicon")
                    self?.avatarImageView.sd_setImage(with: gravatarURL, placeholderImage: UIImage(systemName: "person.circle"))
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "首頁"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func layout() {
        view.addSubview(avatarImageView)
        view.addSubview(usernameLabel)

        avatarImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }

        usernameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAccountVM()
        setupNavigationBar()
        layout()
    }
}
