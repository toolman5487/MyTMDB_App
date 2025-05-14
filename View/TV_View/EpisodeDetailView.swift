//
//  EpisodeDetailView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/12.
//

import UIKit
import SDWebImage
import Combine
import SnapKit

typealias DetailItem = (title: String, value: String)
struct DetailSection {
    let title: String
    let items: [DetailItem]
}

class EpisodeDetailView: UITableViewController {
    
    private let episode: EpisodeModel
    private let seasonNumber: Int
    private var sections: [DetailSection] = []

    init(seasonNumber: Int, episode: EpisodeModel) {
        self.seasonNumber = seasonNumber
        self.episode = episode
        super.init(style: .insetGrouped)
        configureSections()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum SectionType: Int, CaseIterable {
        case basicInfo = 0
        case playbackInfo
        case ratingInfo
        case cast
        case overview
    }
    
    private func configureSections() {
        let basicInfoItems = [
            ("劇集 ID", String(episode.id)),
            ("集數類型", episode.episodeType ?? "未提供"),
            ("季數/集數", "第 \(seasonNumber) 季 第 \(episode.episodeNumber) 集"),
            ("首播日期", episode.airDate ?? "未提供")
        ]
        let playbackInfoItems = [
            ("時長", episode.runtime != nil ? "\(episode.runtime!) 分鐘" : "未提供")
        ]
        var ratingInfoItems: [DetailItem] = []
        if let average = episode.voteAverage {
            ratingInfoItems.append(("評分", String(format: "%.1f", average)))
        } else {
            ratingInfoItems.append(("評分", "未提供"))
        }
        if let count = episode.voteCount {
            ratingInfoItems.append(("投票數", String(count)))
        } else {
            ratingInfoItems.append(("投票數", "未提供"))
        }
        let castItems: [DetailItem] = (episode.guestStars ?? []).map { guest in
            (guest.name, guest.character ?? "未提供角色")
        }
        let overviewItems = [
            ("", episode.overview ?? "")
        ]
        sections = [
            DetailSection(title: "基本資訊", items: basicInfoItems),
            DetailSection(title: "播放資訊", items: playbackInfoItems),
            DetailSection(title: "評分資訊", items: ratingInfoItems),
            DetailSection(title: "演員", items: castItems),
            DetailSection(title: "劇情概要", items: overviewItems)
        ]
    }
    
    private func setupTableView() {
        title = episode.name
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "detailCell")
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        if let stillPath = episode.stillPath,
           let url = URL(string: "https://image.tmdb.org/t/p/w500\(stillPath)") {
            let headerImageView = UIImageView()
            headerImageView.contentMode = .scaleAspectFill
            headerImageView.clipsToBounds = true
            headerImageView.sd_setImage(with: url)
            headerImageView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 250)
            tableView.tableHeaderView = headerImageView
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return SectionType.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let type = SectionType(rawValue: section) else { return 0 }
        switch type {
        case .basicInfo:
            return sections[type.rawValue].items.count
        case .playbackInfo:
            return sections[type.rawValue].items.count
        case .ratingInfo:
            return sections[type.rawValue].items.count
        case .cast:
            return sections[type.rawValue].items.count
        case .overview:
            let text = sections[type.rawValue].items.first?.value ?? "無"
            return text.isEmpty ? 0 : 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let type = SectionType(rawValue: section) else { return nil }
        switch type {
        case .basicInfo:
            return "基本資訊"
        case .playbackInfo:
            return "播放資訊"
        case .ratingInfo:
            return "評分資訊"
        case .cast:
            return "演員"
        case .overview:
            return "劇情概要"
        }
    }

    override func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (title, value) = sections[indexPath.section].items[indexPath.row]
        let sectionType = SectionType(rawValue: indexPath.section)!
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = title
        config.secondaryText = value
        if sectionType == .overview {
            config.secondaryTextProperties.numberOfLines = 0
        }
        if sectionType == .cast {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .none
        }
        cell.contentConfiguration = config
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let type = SectionType(rawValue: indexPath.section) else { return }
        switch type {
        case .cast:
            let guest = (episode.guestStars ?? [])[indexPath.row]
            let viewModel = PersonDetailViewModel(personId: guest.id)
            let vc = PersonDetailView(viewModel: viewModel)
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
}
