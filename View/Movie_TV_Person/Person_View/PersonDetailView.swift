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
    required init?(coder: NSCoder) { fatalError() }
    
    private let headerImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        return image
    }()
    
    private func setupTableHeaderView() {
        headerImageView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 200)
        tableView.tableHeaderView = headerImageView
    }
    
    private func bindViewModel() {
        viewModel.$detail
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] model in
                if let path = model.profilePath,
                   let url = URL(string: "https://image.tmdb.org/t/p/w300\(path)") {
                    self?.headerImageView.sd_setImage(with: url)
                }
                self?.detail = model
                self?.title = model.name
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    enum Section: Int, CaseIterable {
        case name, info, biography, links
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let detail = detail else { return 0 }
        switch Section(rawValue: section)! {
        case .name:
            return detail.alsoKnownAs.count
        case .info:
            let infoItems: [(String, String)] = [
                ("生日", detail.birthday ?? ""),
                ("出生地", detail.placeOfBirth ?? ""),
                ("性別", detail.gender == 2 ? "男性" : "女性"),
                ("現況", detail.knownForDepartment),
                ("人氣", String(format: "%.1f", detail.popularity))
            ]
            let validItems = infoItems.filter { !$0.1.isEmpty }
            return validItems.isEmpty ? 1 : validItems.count
        case .biography:
            return detail.biography.isEmpty ? 0 : 1
        case .links:
            return (detail.imdbId != nil ? 1 : 0) + (detail.homepage != nil ? 1 : 0)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let detail = detail, let sec = Section(rawValue: section) else { return nil }
        if sec == .name {
            return "人物稱呼"
        }
        
        let rowCount = tableView.numberOfRows(inSection: section)
        guard rowCount > 0 else { return nil }
        switch sec {
        case .info:
            return "基本資料"
        case .biography:
            return "人物簡介"
        case .links:
            return "外部連結"
        default:
            return nil
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
        guard rowCount > 0 else { return 0 }
        return 20
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }

    override func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = UIListContentConfiguration.cell()
        guard let detail = detail, let section = Section(rawValue: indexPath.section) else {
            return cell
        }

        switch section {
        case .name:
            let aliases = detail.alsoKnownAs
            let alias = aliases[indexPath.row]
            config.text = alias
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell
        case .info:
            let infoItems: [(title: String, value: String)] = [
                ("生日", detail.birthday ?? ""),
                ("出生地", detail.placeOfBirth ?? ""),
                ("性別", detail.gender == 2 ? "男性" : "女性"),
                ("現況", detail.knownForDepartment),
                ("人氣", String(format: "%.1f", detail.popularity))
            ]
            let validItems = infoItems.filter { !$0.value.isEmpty }
            if validItems.isEmpty {
                config.text = "無資料"
            } else {
                let item = validItems[indexPath.row]
                config.text = item.title
                config.secondaryText = item.value
            }
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell
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
            let text: String
            let imdbCount = detail.imdbId != nil ? 1 : 0
            if detail.imdbId != nil && indexPath.row == 0 {
                text = "IMDb 頁面"
            } else {
                text = "官方網站"
            }
            var linkConfig = UIListContentConfiguration.cell()
            linkConfig.text = text
            linkConfig.textProperties.color = .systemBlue

            let linkCell = UITableViewCell()
            linkCell.contentConfiguration = linkConfig
            linkCell.accessoryType = .disclosureIndicator
            linkCell.selectionStyle = .none
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
        setupTableHeaderView()
        bindViewModel()
        viewModel.fetchPersonDetail()
    }

}
