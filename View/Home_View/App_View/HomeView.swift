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
import CoreData

class HomeView: UIViewController{
    
    private let accountVM = AccountViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let favoriteMoviesCarousel = FavoriteMoviesCarouselView()
    private let favoriteTVCarousel = FavoriteTVCarouselView()
    private let localFavoritesService = FavoritesLocalService()
    
    private let searchResultsView = MultiSearchResultsView()
    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: searchResultsView)
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "搜尋電影、電視劇、人物等"
        search.searchResultsUpdater = searchResultsView
        return search
    }()
    
    private lazy var settingButton: UIButton = {
        let button = UIButton(type: .system)
        let boldConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setPreferredSymbolConfiguration(boldConfig, forImageIn: .normal)
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(didSettingAddButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var settingBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(customView: settingButton)
    }()
    
    @objc private func didSettingAddButton() {
        let settingsVC = SettingsViewController()
        settingsVC.title = "設定"
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    private func homeNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.title = "首頁"
        navigationItem.rightBarButtonItem = settingBarButtonItem
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = true
        return scroll
    }()
    
    private let contentView = UIView()
    
    private let avatarImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = 30
        image.layer.masksToBounds = true
        image.tintColor = .label
        image.image = UIImage(systemName: "person.circle")
        return image
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.bold(ofSize: 24)
        label.textColor = .label
        label.text = "Username"
        return label
    }()
    
    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            avatarImageView,
            usernameLabel
        ])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.distribution = .fill
        stack.backgroundColor = .secondarySystemBackground
        stack.layer.cornerRadius = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return stack
    }()
    
    private func bindAccountVM() {
        guard let sessionId = UserDefaults.standard.string(forKey: "TMDBSessionID") else { return }
        accountVM.loadAccount(sessionId: sessionId)
        accountVM.$account
            .compactMap { $0 }
            .sink { [weak self] account in
                self?.usernameLabel.text = account.username
                UserDefaults.standard.set(account.id, forKey: "TMDBAccountID")
                print(UserDefaults.standard.string(forKey: "TMDBSessionID"))
                print(UserDefaults.standard.integer(forKey: "TMDBAccountID"))
                if let path = account.avatar.tmdb.avatar_path {
                    let url = URL(string: "https://image.tmdb.org/t/p/w200\(path)")
                    self?.avatarImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.circle"))
                } else {
                    let hash = account.avatar.gravatar.hash
                    let gravatarURL = URL(string: "https://www.gravatar.com/avatar/\(hash)?s=200&d=identicon")
                    self?.avatarImageView.sd_setImage(with: gravatarURL, placeholderImage: UIImage(systemName: "person.circle"))
                }
                self?.accountVM.loadFavorites(accountId: account.id, sessionId: sessionId)
            }
            .store(in: &cancellables)
    }
    
    private func bindFavorites() {
        accountVM.$favoriteMovies
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                guard let self = self else { return }
                self.favoriteMoviesCarousel.update(with: movies)
                movies.forEach { movie in
                    self.localFavoritesService.addFavorite(
                        id: movie.id,
                        title: movie.title,
                        posterPath: movie.posterPath,
                        mediaType: "movie"
                    )
                }
            }
            .store(in: &cancellables)
        
        accountVM.$favoriteTV
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tv in
                self?.favoriteTVCarousel.update(with: tv)
            }
            .store(in: &cancellables)
    }
    
    private func configureSearchSelection() {
        searchResultsView.didSelectMovie = { [weak self] movieId in
            guard let sessionId = UserDefaults.standard.string(forKey: "TMDBSessionID"),
                  let accountId = UserDefaults.standard.value(forKey: "TMDBAccountID") as? Int else { return }
            let detailVM = MovieDetailViewModel(movieId: movieId)
            let detailVC = MovieDetailView(viewModel: detailVM, accountId: accountId, sessionId: sessionId)
            self?.navigationController?.pushViewController(detailVC, animated: true)
        }
        searchResultsView.didSelectTV = { [weak self] tvId in
            guard let sessionId = UserDefaults.standard.string(forKey: "TMDBSessionID"),
                  let accountId = UserDefaults.standard.value(forKey: "TMDBAccountID") as? Int else { return }
            let tvVM = TVDetailViewModel(tvId: tvId)
            let tvVC = TVDetailView(viewModel: tvVM, accountId: accountId, sessionId: sessionId)
            self?.navigationController?.pushViewController(tvVC, animated: true)
        }
        
        searchResultsView.didSelectPerson = { [weak self] personId in
            let personVM = PersonDetailViewModel(personId: personId)
            let personVC = PersonDetailView(viewModel: personVM)
            self?.navigationController?.pushViewController(personVC, animated: true)
        }
    }
    
    private func configureFavoritesSelection() {
        favoriteMoviesCarousel.didSelectMovie = { [weak self] movie in
            guard let sessionId = UserDefaults.standard.string(forKey: "TMDBSessionID"),
                  let accountId = UserDefaults.standard.value(forKey: "TMDBAccountID") as? Int else { return }
            let movieVM = MovieDetailViewModel(movieId: movie.id)
            let vc = MovieDetailView(viewModel: movieVM, accountId: accountId, sessionId: sessionId)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        favoriteTVCarousel.didSelectTV = { [weak self] tv in
            guard let sessionId = UserDefaults.standard.string(forKey: "TMDBSessionID"),
                  let accountId = UserDefaults.standard.value(forKey: "TMDBAccountID") as? Int else { return }
            let tvVM = TVDetailViewModel(tvId: tv.id)
            let vc  = TVDetailView(viewModel: tvVM, accountId: accountId, sessionId: sessionId)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func layout() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        contentView.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
        }
        avatarImageView.snp.makeConstraints { make in
            make.height.width.equalTo(60)
        }
        
        contentView.addSubview(favoriteMoviesCarousel)
        favoriteMoviesCarousel.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
        
        contentView.addSubview(favoriteTVCarousel)
        favoriteTVCarousel.snp.makeConstraints { make in
            make.top.equalTo(favoriteMoviesCarousel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let sessionId = UserDefaults.standard.string(forKey: "TMDBSessionID"),
           let accountId = UserDefaults.standard.value(forKey: "TMDBAccountID") as? Int {
            accountVM.loadFavorites(accountId: accountId, sessionId: sessionId)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAccountVM()
        bindFavorites()
        homeNavigationBar()
        configureSearchSelection()
        configureFavoritesSelection()
        layout()
    }
}
