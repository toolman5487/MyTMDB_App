//
//  MovieDetailView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/6.
//

import UIKit
import SnapKit
import Combine
import SDWebImage


class MovieDetailView: UITableViewController {
    private let viewModel: MovieDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    private var movie: MovieDetailModel?
    private var creditsViewModel: MovieCreditsViewModel!
    private var castMembers: [CastMember] = []
    private var favoriteViewModel: FavoriteViewModel!
    private let accountId: Int
    private let sessionId: String
    
    private let posterImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.frame = CGRect(x: 0,y: 0,width: UIScreen.main.bounds.width,height: 250)
        return image
    }()
    
    init(viewModel: MovieDetailViewModel, accountId: Int, sessionId: String) {
        self.viewModel = viewModel
        self.creditsViewModel = MovieCreditsViewModel(movieId: viewModel.movieId)
        self.accountId = accountId
        self.sessionId = sessionId
        super.init(style: .insetGrouped)
        navigationItem.largeTitleDisplayMode = .always
        title = "電影詳情"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func configureTableView() {
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }
    
    private func bindViewModel() {
        viewModel.$movie
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] model in
                self?.movie = model
                self?.title = model.title
                if let path = model.backdropPath ?? model.posterPath,
                   let url = URL(string: "https://image.tmdb.org/t/p/w500\(path)"),
                   let strongSelf = self {
                    strongSelf.posterImageView.sd_setImage(with: url)
                    strongSelf.tableView.tableHeaderView = strongSelf.posterImageView
                }
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        creditsViewModel.$cast
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cast in
                self?.castMembers = cast
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        favoriteViewModel.$isFavorite
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFav in
                print("MovieDetailView: isFavorite =", isFav)
                self?.configureNavigationBarItems()
            }
            .store(in: &cancellables)
    }
    
    enum Section: Int, CaseIterable {
        case info, review, overview, cast, production
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return movie == nil ? 0 : Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let m = movie else { return 0 }
        switch Section(rawValue: section)! {
        case .info:
            return 3
        case .overview:
            return m.overview.isEmpty ? 0 : 1
        case .review:
            return 4
        case .cast:
            return castMembers.count
        case .production:
            return m.productionCompanies.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .info:
            return "基本資訊"
        case .overview:
            return "劇情簡介"
        case .review:
            return "電影評價"
        case .cast:
            return "演員"
        case .production:
            return "製作公司"
        }
    }
    
    override func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryType = .none
        guard let movie = movie,
              let section = Section(rawValue: indexPath.section) else { return cell }
        var config = cell.defaultContentConfiguration()
        
        switch section {
        case .info:
            let titles = ["上映日期", "片長 (分)", "電影預算"]
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            let budgetString = formatter.string(from: NSNumber(value: movie.budget)) ?? "\(movie.budget)"
            let values = [
                movie.releaseDate,
                "\(movie.runtime)",
                budgetString
            ]
            config.text = titles[indexPath.row]
            config.secondaryText = values[indexPath.row]
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            
        case .overview:
            let overviewCell = UITableViewCell()
            let label = UILabel()
            label.numberOfLines = 0
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.text = movie.overview
            overviewCell.contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalTo(overviewCell.contentView.layoutMarginsGuide)
            }
            overviewCell.selectionStyle = .none
            return overviewCell
            
        case .review:
            let titles = ["人氣", "評分", "評分人數", "票房"]
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            let revenueString = formatter.string(from: NSNumber(value: movie.revenue)) ?? "\(movie.revenue)"
            let values = [
                String(format: "%.1f", movie.popularity),
                String(format: "%.1f", movie.voteAverage),
                "\(movie.voteCount)",
                revenueString
            ]
            config.text = titles[indexPath.row]
            config.secondaryText = values[indexPath.row]
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            
        case .cast:
            var config = UIListContentConfiguration.subtitleCell()
            let member = castMembers[indexPath.row]
            config.text = member.name
            config.secondaryText = member.character ?? "未提供角色"
            config.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = config
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .production:
            let company = movie.productionCompanies[indexPath.row].name
            config.text = company
            cell.contentConfiguration = config
            cell.selectionStyle = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let section = Section(rawValue: indexPath.section), section == .cast {
            let member = castMembers[indexPath.row]
            let viewModel = PersonDetailViewModel(personId: member.id)
            let vc = PersonDetailView(viewModel: viewModel)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc private func toggleFavorite() {
        favoriteViewModel.toggleFavorite()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarItems()
    }
    
    private func configureNavigationBarItems() {
        let imageName = favoriteViewModel.isFavorite ? "heart.fill" : "heart"
        let heartItem = UIBarButtonItem(
            image: UIImage(systemName: imageName),
            style: .plain,
            target: self,
            action: #selector(toggleFavorite)
        )
        heartItem.tintColor = .systemPink
        navigationItem.rightBarButtonItem = heartItem
    }
    
    private func configureReviewButton() {
        let reviewButton = UIButton(type: .system)
        reviewButton.setTitle("查看評論", for: .normal)
        reviewButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        reviewButton.backgroundColor = .systemBlue
        reviewButton.setTitleColor(.white, for: .normal)
        reviewButton.layer.cornerRadius = 20
        reviewButton.addTarget(self, action: #selector(showReview), for: .touchUpInside)
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80))
        
        footerView.addSubview(reviewButton)
        reviewButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(60)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        tableView.tableFooterView = footerView
    }

    @objc private func showReview() {
        let reviewVC = MovieReviewTableView(movieId: viewModel.movieId)
        reviewVC.title = "電影評論"
        let nav = UINavigationController(rootViewController: reviewVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [
                .medium(),
                .large()
            ]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.largestUndimmedDetentIdentifier = .medium
        }
        reviewVC.navigationItem.largeTitleDisplayMode = .always
        present(nav, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        favoriteViewModel = FavoriteViewModel(
            mediaType: "movie",
            mediaId: viewModel.movieId,
            accountId: accountId,
            sessionId: sessionId
        )
        configureNavigationBarItems()
        bindViewModel()
        configureTableView()
        creditsViewModel.loadCredits()
        viewModel.fetchMovieDetail()
        configureReviewButton()
    }
}
