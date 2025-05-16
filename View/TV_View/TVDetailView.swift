import UIKit
import Combine
import SDWebImage

class TVDetailView: UITableViewController{
    private let viewModel: TVDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    private var favoriteViewModel: FavoriteViewModel!
    private var tvSeries: TVDetailModel?
    private let accountId: Int
    private let sessionId: String
    
    private let posterImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250)
        return image
    }()
    
    init(viewModel: TVDetailViewModel, accountId: Int, sessionId: String) {
        self.viewModel = viewModel
        self.accountId = accountId
        self.sessionId = sessionId
        super.init(style: .insetGrouped)
        navigationItem.largeTitleDisplayMode = .always
        title = "影集詳情"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func bindViewModel() {
        viewModel.$tvSeries
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] model in
                self?.tvSeries = model
                self?.title = model.name
                if let path = model.backdropPath,
                   let url = URL(string: "https://image.tmdb.org/t/p/w500\(path)") {
                    SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { image, _, _, _, _, _ in
                        DispatchQueue.main.async {
                            self?.posterImageView.image = image
                        }
                    }
                }
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        favoriteViewModel.$isFavorite
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.configureNavigationBarItems()
            }
            .store(in: &cancellables)
    }
    
    @objc private func toggleFavorite() {
        favoriteViewModel.toggleFavorite()
    }
    
    enum Section: Int, CaseIterable {
        case info, overview, seasons, production
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tvSeries == nil ? 0 : Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let series = tvSeries else { return 0 }
        switch Section(rawValue: section)! {
        case .info:       return 3
        case .overview:   return series.overview.isEmpty ? 0 : 1
        case .seasons:    return series.seasons.count
        case .production: return series.productionCompanies.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .info:     return "基本資訊"
        case .overview: return "劇情簡介"
        case .seasons:  return "季別"
        case .production: return "製作公司"
        }
    }
    
    override func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let tvseries = tvSeries, let section = Section(rawValue: indexPath.section) else { return cell }
        var config = UIListContentConfiguration.cell()
        
        switch section {
        case .info:
            let titles = ["首播日期", "季數", "總集數"]
            let values = [
                tvseries.firstAirDate ?? "未知",
                "\(tvseries.numberOfSeasons)",
                "\(tvseries.numberOfEpisodes)"
            ]
            config.text = titles[indexPath.row]
            config.secondaryText = values[indexPath.row]
            cell.selectionStyle = .none
            
        case .overview:
            let overviewCell = UITableViewCell()
            let label = UILabel()
            label.numberOfLines = 0
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.text = tvseries.overview
            overviewCell.contentView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: overviewCell.contentView.layoutMarginsGuide.topAnchor),
                label.bottomAnchor.constraint(equalTo: overviewCell.contentView.layoutMarginsGuide.bottomAnchor),
                label.leadingAnchor.constraint(equalTo: overviewCell.contentView.layoutMarginsGuide.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: overviewCell.contentView.layoutMarginsGuide.trailingAnchor)
            ])
            overviewCell.selectionStyle = .none
            return overviewCell
            
        case .seasons:
            let season = tvseries.seasons[indexPath.row]
            config.text = season.name
            config.secondaryText = "\(season.episodeCount) 集"
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            
        case .production:
            let company = tvseries.productionCompanies[indexPath.row]
            config.text = company.name ?? "未知公司"
            cell.selectionStyle = .none
        }
        
        cell.contentConfiguration = config
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section),section == .seasons,
              let series = tvSeries else { return }
        let season = series.seasons[indexPath.row]
        let seasonVC = SeasonDetailView(tvId: series.id, seasonNumber: season.seasonNumber)
        navigationController?.pushViewController(seasonVC, animated: true)
    }
    
    private func configureTVTableView(){
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableHeaderView = posterImageView
    }
    
    
    private func configureNavigationBarItems() {
        guard let favVM = favoriteViewModel else { return }
        let imageName = favVM.isFavorite ? "heart.fill" : "heart"
        let heartItem = UIBarButtonItem(
            image: UIImage(systemName: imageName),
            style: .plain,
            target: self,
            action: #selector(toggleFavorite)
        )
        heartItem.tintColor = .systemPink
        navigationItem.rightBarButtonItem = heartItem
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        favoriteViewModel = FavoriteViewModel(
            mediaType: "tv",
            mediaId: viewModel.tvId,
            accountId: accountId,
            sessionId: sessionId
        )
        configureNavigationBarItems()
        bindViewModel()
        favoriteViewModel.fetchFavoriteState()
        configureTVTableView()
        viewModel.fetchTVDetail()
    }
}
