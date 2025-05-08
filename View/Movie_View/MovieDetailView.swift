//
//  MovieDetailView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/6.
//

import Foundation
import UIKit
import SnapKit
import Combine
import SDWebImage

class MovieDetailView:UIViewController{
    
    private let viewModel: MovieDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: MovieDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset.bottom = 36
        scrollView.alwaysBounceVertical = false
        scrollView.bounces = false
        return scrollView
    }()
    
    // MARK: backdropImage
    private let backdropImageView: UIImageView = {
        let imageview = UIImageView()
        imageview.contentMode = .scaleAspectFit
        imageview.clipsToBounds = true
        imageview.image = UIImage(named: "tmdb")
        return imageview
    }()
    // MARK: - titleStack -
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.bold(ofSize: 32)
        label.numberOfLines = 1
        return label
    }()
    private let releaseRuntimeLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.regular(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, releaseRuntimeLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        return stack
    }()
    // MARK: - voteStack -
    private lazy var popularityLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.bold(ofSize: 20),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let regularAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.regular(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
        let stats = NSMutableAttributedString()
        stats.append(NSAttributedString(string: "人氣\n", attributes: boldAttrs))
        stats.append(NSAttributedString(string: "0.0", attributes: regularAttrs))
        label.attributedText = stats
        return label
    }()
    private lazy var voteAverageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.bold(ofSize: 20),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let regularAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.regular(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(string: "評分\n", attributes: boldAttrs))
        attributedString.append(NSAttributedString(string: "0.0", attributes: regularAttrs))
        label.attributedText = attributedString
        return label
    }()
    private lazy var voteCountLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.bold(ofSize: 20),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let regularAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.regular(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
        let stats = NSMutableAttributedString()
        stats.append(NSAttributedString(string: "投票數\n", attributes: boldAttrs))
        stats.append(NSAttributedString(string: "0", attributes: regularAttrs))
        label.attributedText = stats
        return label
    }()
    private lazy var voteStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [popularityLabel,voteAverageLabel,voteCountLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.backgroundColor = .secondarySystemBackground
        stack.layer.cornerRadius = 10
        stack.layer.masksToBounds = true
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return stack
    }()
    // MARK: - overviewStack -
    private let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.image = UIImage(systemName: "film.stack.fill")
        imageView.tintColor = .white
        return imageView
    }()
    private let overviewLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.regular(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 16
        label.text = "電影簡介"
        return label
    }()
    private lazy var overviewStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [posterImageView,overviewLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .top
        stack.distribution = .fillEqually
        stack.backgroundColor = .secondarySystemBackground
        stack.layer.cornerRadius = 10
        stack.layer.masksToBounds = true
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8)
        return stack
    }()
    // MARK: - productionStack -
    private let budgetRevenueLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.regular(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.bold(ofSize: 20),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let regularAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.regular(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(string: "票房\n", attributes: boldAttrs))
        attributedString.append(NSAttributedString(string: "$0", attributes: regularAttrs))
        label.attributedText = attributedString
        return label
    }()
    private let productionLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.regular(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 2
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.bold(ofSize: 20),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let regularAttrs: [NSAttributedString.Key: Any] = [
            .font: ThemeFont.regular(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
        let stats = NSMutableAttributedString()
        stats.append(NSAttributedString(string: "電影公司\n", attributes: boldAttrs))
        stats.append(NSAttributedString(string: "TMDB", attributes: regularAttrs))
        label.attributedText = stats
        return label
        
    }()
    
    private lazy var productionStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [budgetRevenueLabel,productionLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.backgroundColor = .secondarySystemBackground
        stack.layer.cornerRadius = 10
        stack.layer.masksToBounds = true
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return stack
    }()
    
    private lazy var wholeStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            titleStack,
            voteStack,
            overviewStack,
            productionStack
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 4, left: 0, bottom: 32, right: 0)
        return stack
    }()
    
    private func layoutUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(backdropImageView)
        backdropImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
        
        scrollView.addSubview(wholeStack)
        wholeStack.snp.makeConstraints { make in
            make.top.equalTo(backdropImageView.snp.bottom).offset(-16)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        titleStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        voteStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(titleStack.snp.bottom).offset(32)
        }

        overviewStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(voteStack.snp.bottom).offset(32)
        }
        posterImageView.snp.makeConstraints { make in
            make.height.equalTo(300)
            make.width.equalTo(200)
        }
        
        productionStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(overviewStack.snp.bottom).offset(32)
        }
    }
    
    
    private func bindViewModel() {
        viewModel.$movie
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movie in
                if let path = movie.backdropPath,
                   let url = URL(string: "https://image.tmdb.org/t/p/w500\(path)") {
                    self?.backdropImageView.sd_setImage(with: url)
                }
                if let poster = movie.posterPath,
                   let url = URL(string: "https://image.tmdb.org/t/p/w500\(poster)") {
                    self?.posterImageView.sd_setImage(with: url)
                }
                self?.titleLabel.text = movie.title
                self?.releaseRuntimeLabel.text = "\(movie.releaseDate) • \(movie.runtime) min"
                self?.popularityLabel.attributedText = {
                    let bold = [NSAttributedString.Key.font: ThemeFont.bold(ofSize: 20),
                                .foregroundColor: UIColor.secondaryLabel]
                    let regular = [NSAttributedString.Key.font: ThemeFont.regular(ofSize: 16),
                                   .foregroundColor: UIColor.label]
                    let attributedString = NSMutableAttributedString(string: "人氣\n", attributes: bold)
                    attributedString.append(NSAttributedString(string: String(format: "%.1f", movie.popularity), attributes: regular))
                    return attributedString
                }()
                self?.voteAverageLabel.attributedText = {
                    let bold = [NSAttributedString.Key.font: ThemeFont.bold(ofSize: 20),
                                .foregroundColor: UIColor.secondaryLabel]
                    let regular = [NSAttributedString.Key.font: ThemeFont.regular(ofSize: 16),
                                   .foregroundColor: UIColor.label]
                    let attributedString = NSMutableAttributedString(string: "評分\n", attributes: bold)
                    attributedString.append(NSAttributedString(string: String(format: "%.1f", movie.voteAverage), attributes: regular))
                    return attributedString
                }()
                self?.voteCountLabel.attributedText = {
                    let bold = [NSAttributedString.Key.font: ThemeFont.bold(ofSize: 20),
                                .foregroundColor: UIColor.secondaryLabel]
                    let regular = [NSAttributedString.Key.font: ThemeFont.regular(ofSize: 16),
                                   .foregroundColor: UIColor.label]
                    let attributedString = NSMutableAttributedString(string: "投票數\n", attributes: bold)
                    attributedString.append(NSAttributedString(string: "\(movie.voteCount)", attributes: regular))
                    return attributedString
                }()
                self?.overviewLabel.text = movie.overview
                self?.budgetRevenueLabel.attributedText = {
                    let bold = [NSAttributedString.Key.font: ThemeFont.bold(ofSize: 20),
                                .foregroundColor: UIColor.secondaryLabel]
                    let regular = [NSAttributedString.Key.font: ThemeFont.regular(ofSize: 16),
                                   .foregroundColor: UIColor.label]
                    let attributedString = NSMutableAttributedString(string: "票房\n", attributes: bold)
                    attributedString.append(NSAttributedString(string: "$\(movie.revenue)", attributes: regular))
                    return attributedString
                }()
                self?.productionLabel.attributedText = {
                    let bold = [NSAttributedString.Key.font: ThemeFont.bold(ofSize: 20),
                                .foregroundColor: UIColor.secondaryLabel]
                    let regular = [NSAttributedString.Key.font: ThemeFont.regular(ofSize: 16),
                                   .foregroundColor: UIColor.label]
                    let names = movie.productionCompanies.map { $0.name }.joined(separator: ", ")
                    let attributedString = NSMutableAttributedString(string: "電影公司\n", attributes: bold)
                    attributedString.append(NSAttributedString(string: names, attributes: regular))
                    return attributedString
                }()
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                let alert = UIAlertController(title: "錯誤", message: msg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutUI()
        bindViewModel()
        viewModel.fetchMovieDetail()
    }
}
