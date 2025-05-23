import UIKit
import Combine
import SDWebImage
import SnapKit

class PersonDetailView: UITableViewController {
    private let viewModel: PersonDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    private var detail: PersonDetailModel?

    init(viewModel: PersonDetailViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
        navigationItem.largeTitleDisplayMode = .always
        title = "人物資訊"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    private func bindViewModel() {
        viewModel.$detail
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] model in
                self?.detail = model
                self?.title = model.name
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    enum Section: Int, CaseIterable {
        case header, info, biography, links
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let detail = detail else { return 0 }
        switch Section(rawValue: section)! {
        case .header:      return 1
        case .info:        return 5
        case .biography:   return detail.biography.isEmpty ? 0 : 1
        case .links:       return (detail.imdbId != nil ? 1 : 0) + (detail.homepage != nil ? 1 : 0)
        }
    }

    override func tableView(_ tableView: UITableView,titleForHeaderInSection section: Int) -> String? {
        let rowCount = tableView.numberOfRows(inSection: section)
        guard rowCount > 0 else { return nil }
        switch Section(rawValue: section)! {
        case .header:
            return nil
        case .info:
            return "基本資料"
        case .biography:
            return "人物簡介"
        case .links:
            return "外部連結"
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = self.tableView(tableView, titleForHeaderInSection: section) else {
            return nil
        }
        let header = UITableViewHeaderFooterView()
        header.textLabel?.text = title
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        header.textLabel?.textColor = .secondaryLabel
        return header
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let rowCount = tableView.numberOfRows(inSection: section)
        guard rowCount > 0 && section != Section.header.rawValue else { return 0 }
        return 30
    }

    override func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = UIListContentConfiguration.cell()
        guard let detail = detail,
              let section = Section(rawValue: indexPath.section) else {
            return cell
        }

        switch section {
        case .header:
            config.imageProperties.maximumSize = CGSize(width: 200, height: 200)
            config.imageProperties.cornerRadius = 20
            if let path = detail.profilePath,
               let url = URL(string: "https://image.tmdb.org/t/p/w300\(path)") {
                SDWebImageManager.shared.loadImage(with: url,options: [],progress: nil) { image, _, _, _, _, _ in
                    DispatchQueue.main.async {
                        config.image = image
                        cell.contentConfiguration = config
                    }
                }
            }
            config.text = detail.name
            if !detail.alsoKnownAs.isEmpty {
                config.secondaryText = detail.alsoKnownAs.joined(separator: "\n")
                config.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
                config.secondaryTextProperties.color = .secondaryLabel
            }
            config.textProperties.font = UIFont.preferredFont(forTextStyle: .title1)
            cell.contentConfiguration = config

        case .info:
            let titles = ["生日", "出生地", "性別", "現況", "人氣"]
            let values = [
                detail.birthday ?? "未知",
                detail.placeOfBirth ?? "未知",
                detail.gender == 2 ? "男性" : "女性",
                detail.knownForDepartment,
                String(format: "%.1f", detail.popularity)
            ]
            config.text = titles[indexPath.row]
            config.secondaryText = values[indexPath.row]
            cell.contentConfiguration = config
            cell.selectionStyle = .none

        case .biography:
            let bioCell = UITableViewCell()
            let label = UILabel()
            label.numberOfLines = 0
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.text = detail.biography
            bioCell.contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalTo(bioCell.contentView.layoutMarginsGuide)
            }
            bioCell.selectionStyle = .none
            return bioCell

        case .links:
            let linkCell = UITableViewCell()
            linkCell.accessoryType = .disclosureIndicator
            if detail.imdbId != nil && indexPath.row == 0 {
                config.text = "IMDb 頁面"
            } else {
                config.text = "官方網站"
            }
            cell.contentConfiguration = config
            return linkCell
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detail = detail,
              let section = Section(rawValue: indexPath.section) else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        switch section {
        case .links:
            if detail.imdbId != nil && indexPath.row == 0,
               let id = detail.imdbId,
               let url = URL(string: "https://www.imdb.com/name/\(id)") {
                UIApplication.shared.open(url)
            }
            let imdbCount = detail.imdbId != nil ? 1 : 0
            if detail.homepage != nil && indexPath.row == imdbCount,
               let link = detail.homepage,
               let url = URL(string: link) {
                UIApplication.shared.open(url)
            }
        default: break
        }
    }
    
    private func configureTableView() {
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
      configureTableView()
        bindViewModel()
        viewModel.fetchPersonDetail()
    }

}
