//
//  MainMovieSearchResultsViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainMovieSearchResultsViewController

@MainActor
final class MainMovieSearchResultsViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: MainMovieSearchResultsViewModel

    var onMovieSelected: ((Int) -> Void)?
    var onSortBarButtonItemChanged: ((UIBarButtonItem?) -> Void)?

    private var movies: [MainMovieListMovieItem] = []
    private var canLoadNextPage = false
    private var isLoadingNextPage = false
    private var searchTask: Task<Void, Never>?
    private var loadNextPageTask: Task<Void, Never>?
    private var loadNextPageGeneration = 0

    var selectedSortOption: MainMovieListSortOption? {
        viewModel.selectedSortOption
    }

    // MARK: - UI Components

    private lazy var collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .zero
        layout.minimumLineSpacing = MovieGridLayoutMetrics.itemSpacing
        layout.minimumInteritemSpacing = MovieGridLayoutMetrics.itemSpacing
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MainMovieSearchResultCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMovieSearchResultCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    private lazy var sortBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            menu: makeSortMenu(selectedSortOption: nil)
        )
        barButtonItem.tintColor = ThemeColor.textPrimary
        return barButtonItem
    }()

    // MARK: - Initialization

    init(viewModel: MainMovieSearchResultsViewModel = MainMovieSearchResultsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MainMovieSearchResultsViewModel()
        super.init(coder: coder)
    }

    deinit {
        searchTask?.cancel()
        loadNextPageTask?.cancel()
    }

    // MARK: - Template Methods

    override func configureView() {
        super.configureView()
        view.backgroundColor = ThemeColor.background
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(collectionView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Rendering

    func showTypingLoading() {
        searchTask?.cancel()
        viewModel.showTypingLoading()
        renderCurrentState()
    }

    func submitSearch(keyword: String) {
        searchTask?.cancel()
        cancelLoadNextPageTask()

        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else {
            reset()
            return
        }

        viewModel.showSearchLoading(keyword: trimmedKeyword)
        renderCurrentState()

        searchTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            await viewModel.searchMovies(keyword: trimmedKeyword)

            guard !Task.isCancelled else { return }
            renderCurrentState()
        }
    }

    func selectSortOption(_ option: MainMovieListSortOption) {
        viewModel.selectSortOption(option)
        renderCurrentState()
    }

    func reset() {
        searchTask?.cancel()
        cancelLoadNextPageTask()
        viewModel.reset()
        renderCurrentState()
    }

    private func renderCurrentState() {
        render(state: viewModel.state)
        updateSortBarButtonItem(for: viewModel.state)
    }

    private func render(state: MainMovieSearchResultsViewState) {
        switch state {
        case .idle:
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = nil

        case .typing:
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchTypingLoadingView()

        case .searching(let keyword):
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchSubmittedLoadingView(keyword: keyword)

        case .results(let content):
            movies = content.movies
            canLoadNextPage = content.canLoadNextPage
            isLoadingNextPage = content.isLoadingNextPage
            collectionView.backgroundView = nil

        case .empty(let keyword):
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchMessageView(
                title: "找不到電影",
                message: "沒有符合「\(keyword)」的搜尋結果"
            )

        case .failed(let errorMessage):
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchMessageView(
                title: "搜尋失敗",
                message: errorMessage.message
            )
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension MainMovieSearchResultsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        movies.isEmpty ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainMovieSearchResultCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainMovieSearchResultCollectionViewCell,
           movies.indices.contains(indexPath.item) {
            cell.configure(
                with: movies[indexPath.item],
                imageHeight: MovieGridLayoutMetrics.posterHeight(for: collectionView.bounds.width)
            )
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainMovieSearchResultsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard movies.indices.contains(indexPath.item) else { return }
        let movieID = movies[indexPath.item].id

        collectionView.deselectItem(at: indexPath, animated: true)
        onMovieSelected?(movieID)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        loadNextPageIfNeeded(for: indexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        MovieGridLayoutMetrics.itemSize(for: collectionView.bounds.width)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: 16,
            left: MovieGridLayoutMetrics.horizontalInset,
            bottom: 24,
            right: MovieGridLayoutMetrics.horizontalInset
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        MovieGridLayoutMetrics.itemSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        MovieGridLayoutMetrics.itemSpacing
    }
}

// MARK: - Private Methods

private extension MainMovieSearchResultsViewController {

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard movies.indices.contains(indexPath.item) else { return }
        guard canLoadNextPage, !isLoadingNextPage else { return }
        guard loadNextPageTask == nil else { return }

        guard MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: movies.count
        ) else { return }

        let currentMovieID = movies[indexPath.item].id
        loadNextPageGeneration += 1
        let generation = loadNextPageGeneration

        loadNextPageTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            defer {
                if loadNextPageGeneration == generation {
                    loadNextPageTask = nil
                }
            }

            await viewModel.loadNextPageIfNeeded(currentMovieID: currentMovieID)

            guard !Task.isCancelled, loadNextPageGeneration == generation else { return }
            renderCurrentState()
        }
    }

    func cancelLoadNextPageTask() {
        loadNextPageGeneration += 1
        loadNextPageTask?.cancel()
        loadNextPageTask = nil
    }

    func updateSortBarButtonItem(for state: MainMovieSearchResultsViewState) {
        switch state {
        case .results(let content):
            sortBarButtonItem.menu = makeSortMenu(selectedSortOption: content.selectedSortOption)
            onSortBarButtonItemChanged?(sortBarButtonItem)

        case .idle, .typing, .searching, .empty, .failed:
            onSortBarButtonItemChanged?(nil)
        }
    }

    func makeSortMenu(selectedSortOption: MainMovieListSortOption?) -> UIMenu {
        let actions = MainMovieListSortOption.allCases.map { option in
            UIAction(
                title: option.title,
                state: selectedSortOption == option ? .on : .off
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.selectSortOption(option)
                }
            }
        }

        return UIMenu(
            title: "篩選排序",
            options: .singleSelection,
            children: actions
        )
    }
}

// MARK: - MainMovieSearchResultCollectionViewCell

@MainActor
private final class MainMovieSearchResultCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMovieSearchResultCollectionViewCell.self)

    private enum Layout {
        static let imageCornerRadius: CGFloat = 8
    }

    func configure(
        with item: MainMovieListMovieItem,
        imageHeight: CGFloat
    ) {
        configureLayout(
            imageHeight: imageHeight,
            imageCornerRadius: Layout.imageCornerRadius
        )
        configure(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: "評分 \(item.scoreText)"
        )
    }
}

// MARK: - MainMovieSearchSubmittedLoadingView

@MainActor
private final class MainMovieSearchSubmittedLoadingView: UIView {

    private let indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.color = ThemeColor.primary
        indicatorView.startAnimating()
        return indicatorView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "正在搜尋"
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            indicatorView,
            titleLabel,
            messageLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    init(keyword: String) {
        super.init(frame: .zero)
        messageLabel.text = "正在搜尋「\(keyword)」"
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    private func setupHierarchy() {
        addSubview(stackView)
    }

    private func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])
    }
}

// MARK: - MainMovieSearchMessageView

@MainActor
private final class MainMovieSearchMessageView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            messageLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    init(
        title: String,
        message: String
    ) {
        super.init(frame: .zero)
        titleLabel.text = title
        messageLabel.text = message
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    private func setupHierarchy() {
        addSubview(stackView)
    }

    private func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])
    }
}
