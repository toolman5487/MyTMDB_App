//
//  PersonDetailView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/8.
//

import Foundation
import UIKit
import SnapKit
import SDWebImage
import Combine

class PersonDetailView: UIViewController {
    
    private let viewModel: PersonDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    init(viewModel: PersonDetailViewModel) {
        self.viewModel = viewModel
        super .init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let profileImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 60
        return image
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.numberOfLines = 0
        return label
    }()

    private let alsoKnownAsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var infoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            birthInfoLabel,
            placeInfoLabel,
            genderInfoLabel,
            departmentInfoLabel,
            popularityInfoLabel
        ])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private let birthInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        return label
    }()

    private let placeInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        return label
    }()

    private let genderInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        return label
    }()

    private let departmentInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        return label
    }()

    private let popularityInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        return label
    }()

    private let biographyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private lazy var linksStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            imdbButton,
            homepageButton
        ])
        stack.axis = .horizontal
        stack.spacing = 16
        return stack
    }()

    private let imdbButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("IMDb", for: .normal)
        button.isHidden = true      // initially hidden
        return button
    }()

    private let homepageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Homepage", for: .normal)
        button.isHidden = true     // initially hidden
        return button
    }()
    
    private var currentImdbId: String?
    private var currentHomepage: String?
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentView.addSubview(profileImageView)
        profileImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(120)
        }

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        contentView.addSubview(alsoKnownAsLabel)
        alsoKnownAsLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(nameLabel)
        }

        contentView.addSubview(infoStack)
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(alsoKnownAsLabel.snp.bottom).offset(16)
            make.leading.trailing.equalTo(nameLabel)
        }

        contentView.addSubview(biographyLabel)
        biographyLabel.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(16)
            make.leading.trailing.equalTo(nameLabel)
        }

        contentView.addSubview(linksStack)
        linksStack.snp.makeConstraints { make in
            make.top.equalTo(biographyLabel.snp.bottom).offset(16)
            make.leading.trailing.equalTo(nameLabel)
            make.bottom.equalToSuperview().offset(-16)
        }
        imdbButton.addTarget(self, action: #selector(openImdb), for: .touchUpInside)
        homepageButton.addTarget(self, action: #selector(openHomepage), for: .touchUpInside)
    }
    
    private func bindViewModel() {
            viewModel.$detail
                .compactMap { $0 }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] detail in
                    self?.title = detail.name
                    if let path = detail.profilePath,
                       let url = URL(string: "https://image.tmdb.org/t/p/w300\(path)") {
                        self?.profileImageView.sd_setImage(with: url)
                    }
                    self?.nameLabel.text = detail.name
                    if !detail.alsoKnownAs.isEmpty {
                        self?.alsoKnownAsLabel.text = detail.alsoKnownAs.joined(separator: ", ")
                    }

                    var birthText = detail.birthday ?? "未知生日"
                    if let death = detail.deathday {
                        birthText += " - \(death)"
                    }
                    self?.birthInfoLabel.text = "生日: \(birthText)"
                    self?.placeInfoLabel.text = "出生地: \(detail.placeOfBirth ?? "未知")"
                    self?.genderInfoLabel.text = "性別: \(detail.gender == 2 ? "男性" : "女性")"
                    self?.departmentInfoLabel.text = "部門: \(detail.knownForDepartment)"
                    self?.popularityInfoLabel.text = String(format: "人氣: %.1f", detail.popularity)
                    self?.biographyLabel.text = detail.biography

                    if let imdbId = detail.imdbId {
                        self?.imdbButton.isHidden = false
                        self?.currentImdbId = imdbId
                    }
                    if let homepage = detail.homepage {
                        self?.homepageButton.isHidden = false
                        self?.currentHomepage = homepage
                    }
                }
                .store(in: &cancellables)
        }

    @objc private func openImdb() {
        guard let id = currentImdbId,
              let url = URL(string: "https://www.imdb.com/name/\(id)") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func openHomepage() {
        guard let link = currentHomepage,
              let url = URL(string: link) else { return }
        UIApplication.shared.open(url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bindViewModel()
        viewModel.fetchPersonDetail()
    }
}
