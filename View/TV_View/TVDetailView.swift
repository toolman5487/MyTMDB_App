import UIKit
import Combine
import SDWebImage

class TVDetailView: UITableViewController{
    private let viewModel: TVDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    private var tvSeries: TVDetailModel?
    
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .tertiarySystemFill
        iv.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        return iv
    }()

    init(viewModel: TVDetailViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        navigationItem.largeTitleDisplayMode = .always
        title = "影集詳情"
    }

    @available(*, unavailable)
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
    }
    

    enum Section: Int, CaseIterable {
        case info, overview, production
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tvSeries == nil ? 0 : Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = tvSeries else { return 0 }
        switch Section(rawValue: section)! {
        case .info:       return 3
        case .overview:   return s.overview.isEmpty ? 0 : 1
        case .production: return s.productionCompanies.count ?? 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .info:     return "基本資訊"
        case .overview: return "劇情簡介"
        case .production: return "製作公司"
        }
    }

    override func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let tvseries = tvSeries,
              let section = Section(rawValue: indexPath.section) else { return cell }
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

        case .production:
            let prod = tvseries.productionCompanies[indexPath.row].name ?? ""
            config.text = prod
            cell.selectionStyle = .none
        }

        cell.contentConfiguration = config
        return cell
    }
    
    private func configureTVTableView(){
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTVTableView()
        tableView.tableHeaderView = posterImageView
        bindViewModel()
        viewModel.fetchTVDetail()
    }
}
