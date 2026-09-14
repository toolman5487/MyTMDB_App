//
//  AppComposition.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import UIKit

// MARK: - Scene Building

@MainActor
protocol LoginSceneBuilding: AnyObject {
    func makeLoginNavigationController() -> UIViewController
}

@MainActor
protocol DetailSceneBuilding: LoginSceneBuilding {
    func makeMovieDetailViewController(movieID: Int) -> UIViewController
    func makeTVDetailViewController(seriesID: Int) -> UIViewController
    func makeSeasonDetailViewController(seriesID: Int, seasonNumber: Int) -> UIViewController
    func makeEpisodeDetailViewController(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) -> UIViewController
    func makePersonDetailViewController(personID: Int) -> UIViewController
    func makeReviewListViewController(mediaKind: MediaKind, mediaID: Int) -> UIViewController
    func makeDetailContentListViewController(
        configuration: DetailContentListConfiguration
    ) -> UIViewController
}

@MainActor
protocol HomeSceneBuilding: DetailSceneBuilding {
    func makeHomeSectionListViewController(category: HomeCategory) -> UIViewController
}

@MainActor
protocol MediaListSceneBuilding: DetailSceneBuilding {
    func makeSearchResultsViewController(mediaKind: MediaKind) -> SearchResultsViewController
}

@MainActor
protocol MemberCenterSceneBuilding: DetailSceneBuilding {
    func makeMemberCenterViewController(session: AuthSession) -> UIViewController
    func makeMemberCenterListViewController(
        destination: MemberCenterDestination,
        accountID: Int,
        sessionID: String
    ) -> UIViewController
    func makeMainMemberSettingViewController() -> UIViewController
}

@MainActor
protocol MainTabSceneBuilding: HomeSceneBuilding, MediaListSceneBuilding, MemberCenterSceneBuilding {
    func makeMainHomeViewController() -> UIViewController
    func makeMainSearchViewController() -> UIViewController
    func makeMainMediaListViewController(
        mediaKind: MediaKind,
        initialGenreID: Int?
    ) -> UIViewController
}

@MainActor
protocol AppFlowRouting: AnyObject {
    func showLoggedOutRoot()
}

// MARK: - AppComposition

@MainActor
final class AppComposition: MainTabSceneBuilding, AppFlowRouting {

    // MARK: - Properties

    private let network: NetworkServicing
    private let sessionStore: SessionStoring
    private let userProfileStore: UserProfileStoring
    private let searchHistoryStore: SearchHistoryStoring
    private let localization: AppLocalization
    private let urlSession: URLSession
    private let bundle: Bundle
    private let authService: TMDBAuthServicing
    private let onSessionChanged: @MainActor (AuthSession) -> Void

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        sessionStore: SessionStoring = SessionStore(),
        userProfileStore: UserProfileStoring = UserProfileStore(),
        searchHistoryStore: SearchHistoryStoring = SearchHistoryStore(),
        localization: AppLocalization = .current,
        urlSession: URLSession = .shared,
        bundle: Bundle = .main,
        onSessionChanged: @escaping @MainActor (AuthSession) -> Void = { _ in }
    ) {
        self.network = network
        self.sessionStore = sessionStore
        self.userProfileStore = userProfileStore
        self.searchHistoryStore = searchHistoryStore
        self.localization = localization
        self.urlSession = urlSession
        self.bundle = bundle
        self.authService = TMDBAuthService(network: network)
        self.onSessionChanged = onSessionChanged
    }

    // MARK: - App Flow

    func makeSessionValidator() -> AuthSessionValidator {
        AuthSessionValidator(
            sessionStore: sessionStore,
            profileProvider: makeAccountContentRepository(),
            userProfileStore: userProfileStore
        )
    }

    func makeAuthFlowHandler() -> AuthFlowHandler {
        AuthFlowHandler(
            sessionStore: sessionStore,
            profileProvider: makeAccountContentRepository(),
            userProfileStore: userProfileStore,
            onFinish: onSessionChanged
        )
    }

    func makeRootLoadingViewController() -> UIViewController {
        RootLoadingViewController()
    }

    func makeLoginNavigationController() -> UIViewController {
        let viewController = LoginViewController(
            loginViewModel: LoginViewModel(authService: authService),
            authFlowHandler: makeAuthFlowHandler()
        )
        return UINavigationController(rootViewController: viewController)
    }

    func makeLoginViewController() -> LoginViewController {
        LoginViewController(
            loginViewModel: LoginViewModel(authService: authService),
            authFlowHandler: makeAuthFlowHandler()
        )
    }

    func makeMainTabBarController(
        session: AuthSession
    ) -> MainTabBarController {
        MainTabBarController(
            session: session,
            viewModel: MainTabBarViewModel(),
            avatarProvider: MainTabBarAvatarService(
                profileProvider: makeAccountContentRepository(),
                userProfileStore: userProfileStore,
                urlSession: urlSession
            ),
            sceneBuilder: self
        )
    }

    func showLoggedOutRoot() {
        onSessionChanged(.loggedOut)
    }

    // MARK: - Main Tabs

    func makeMainHomeViewController() -> UIViewController {
        let repository = HomeContentRepository(network: network, localization: localization)
        let viewModel = MainHomeViewModel(
            loadHomeSections: DefaultLoadHomeSectionsUseCase(repository: repository)
        )
        return MainHomeViewController(viewModel: viewModel, sceneBuilder: self)
    }

    func makeMainSearchViewController() -> UIViewController {
        let service = MainSearchService(network: network, localization: localization)
        let viewModel = MainSearchViewModel(
            service: service,
            searchHistoryStore: searchHistoryStore
        )
        return MainSearchViewController(viewModel: viewModel, sceneBuilder: self)
    }

    func makeMainMediaListViewController(
        mediaKind: MediaKind,
        initialGenreID: Int?
    ) -> UIViewController {
        let genreRepository = MediaGenreRepository(network: network, localization: localization)
        let repository = MediaListRepository(
            network: network,
            localization: localization,
            genreRepository: genreRepository
        )
        let viewModel = MainMediaListViewModel(
            mediaKind: mediaKind,
            loadMediaList: DefaultLoadMediaListUseCase(repository: repository),
            repository: repository,
            initialGenreID: initialGenreID
        )
        return MainMediaListViewController(
            mediaKind: mediaKind,
            viewModel: viewModel,
            sceneBuilder: self
        )
    }

    func makeMainMemberSettingViewController() -> UIViewController {
        let viewModel = MainMemberSettingViewModel(
            sessionStore: sessionStore,
            userProfileStore: userProfileStore,
            searchHistoryStore: searchHistoryStore,
            profileProvider: makeAccountContentRepository(),
            localization: localization,
            bundle: bundle
        )
        return MainMemberSettingViewController(
            viewModel: viewModel,
            sceneBuilder: self,
            appFlowRouter: self
        )
    }

    // MARK: - Home

    func makeHomeSectionListViewController(
        category: HomeCategory
    ) -> UIViewController {
        let contentRepository = HomeContentRepository(network: network, localization: localization)
        let genreRepository = MediaGenreRepository(network: network, localization: localization)
        let viewModel = HomeSectionListViewModel(
            category: category,
            loadSectionList: DefaultLoadHomeSectionListUseCase(
                contentRepository: contentRepository,
                genreRepository: genreRepository
            ),
            filterByGenre: DefaultFilterMediaByGenreUseCase(),
            contentRepository: contentRepository
        )
        return HomeSectionListViewController(
            category: category,
            viewModel: viewModel,
            sceneBuilder: self
        )
    }

    // MARK: - Search

    func makeSearchResultsViewController(mediaKind: MediaKind) -> SearchResultsViewController {
        let repository = MediaSearchRepository(network: network, localization: localization)
        let viewModel = SearchResultsViewModel(
            mediaKind: mediaKind,
            searchMedia: DefaultSearchMediaUseCase(repository: repository),
            sortMedia: DefaultSortMediaUseCase()
        )
        return SearchResultsViewController(mediaKind: mediaKind, viewModel: viewModel)
    }

    // MARK: - Details

    func makeMovieDetailViewController(
        movieID: Int
    ) -> UIViewController {
        let repository = MovieDetailRepository(network: network, localization: localization)
        let viewModel = MovieDetailViewModel(
            loadMovieDetailUseCase: DefaultLoadMovieDetailUseCase(
                repository: repository,
                auxiliaryFailureHandler: { name, movieID, error in
                    AppLogger.network.warning(
                        "Failed to load \(name, privacy: .public) for movie \(movieID, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                }
            ),
            accountMediaController: makeDetailAccountMediaStateController()
        )
        return MovieDetailViewController(
            movieID: movieID,
            viewModel: viewModel,
            sceneBuilder: self
        )
    }

    func makeTVDetailViewController(
        seriesID: Int
    ) -> UIViewController {
        let repository = TVDetailRepository(network: network, localization: localization)
        let viewModel = TVDetailViewModel(
            loadTVDetailUseCase: DefaultLoadTVDetailUseCase(
                repository: repository,
                auxiliaryFailureHandler: { name, seriesID, error in
                    AppLogger.network.warning(
                        "Failed to load \(name, privacy: .public) for TV \(seriesID, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                }
            ),
            accountMediaController: makeDetailAccountMediaStateController()
        )
        return TVDetailViewController(
            seriesID: seriesID,
            viewModel: viewModel,
            sceneBuilder: self
        )
    }

    func makeSeasonDetailViewController(
        seriesID: Int,
        seasonNumber: Int
    ) -> UIViewController {
        let repository = SeasonDetailRepository(network: network, localization: localization)
        let viewModel = SeasonDetailViewModel(
            loadSeasonDetailUseCase: DefaultLoadSeasonDetailUseCase(
                repository: repository,
                accountCredential: seasonAccountCredential,
                auxiliaryFailureHandler: { name, seriesID, seasonNumber, error in
                    AppLogger.network.warning(
                        "Failed to load \(name, privacy: .public) for TV series \(seriesID, privacy: .public) season \(seasonNumber, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                }
            )
        )
        return SeasonDetailViewController(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            viewModel: viewModel,
            sceneBuilder: self
        )
    }

    func makeEpisodeDetailViewController(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) -> UIViewController {
        let input = EpisodeDetailInput(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber
        )
        let repository = EpisodeDetailRepository(network: network, localization: localization)
        let viewModel = EpisodeDetailViewModel(
            input: input,
            loadEpisodeDetailUseCase: DefaultLoadEpisodeDetailUseCase(
                repository: repository,
                accountCredential: episodeAccountCredential,
                auxiliaryFailureHandler: { name, input, error in
                    AppLogger.network.warning(
                        "Failed to load \(name, privacy: .public) for TV series \(input.seriesID, privacy: .public) season \(input.seasonNumber, privacy: .public) episode \(input.episodeNumber, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                }
            ),
            accountMediaController: makeDetailAccountMediaStateController()
        )
        return EpisodeDetailViewController(viewModel: viewModel, sceneBuilder: self)
    }

    func makePersonDetailViewController(
        personID: Int
    ) -> UIViewController {
        let repository = PersonDetailRepository(network: network, localization: localization)
        let viewModel = PersonDetailViewModel(
            loadPersonDetailUseCase: DefaultLoadPersonDetailUseCase(
                repository: repository,
                auxiliaryFailureHandler: { name, personID, error in
                    AppLogger.network.warning(
                        "Failed to load \(name, privacy: .public) for person \(personID, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                }
            ),
            loadPersonCreditsUseCase: DefaultLoadPersonCreditsUseCase(repository: repository)
        )
        return PersonDetailViewController(
            personID: personID,
            viewModel: viewModel,
            sceneBuilder: self
        )
    }

    func makeReviewListViewController(
        mediaKind: MediaKind,
        mediaID: Int
    ) -> UIViewController {
        let repository = ReviewRepository(network: network)
        let viewModel = ReviewListViewModel(
            mediaKind: mediaKind,
            loadReviewsUseCase: DefaultLoadReviewsUseCase(repository: repository),
            filterReviewsUseCase: DefaultFilterReviewsUseCase()
        )
        return ReviewListViewController(mediaID: mediaID, viewModel: viewModel)
    }

    func makeDetailContentListViewController(
        configuration: DetailContentListConfiguration
    ) -> UIViewController {
        DetailContentListViewController(
            configuration: configuration,
            sceneBuilder: self
        )
    }

    // MARK: - Member Center

    func makeMemberCenterViewController(
        session: AuthSession
    ) -> UIViewController {
        let repository = makeAccountContentRepository()
        let viewModel = MemberCenterViewModel(
            session: session,
            loadOverview: DefaultLoadMemberCenterOverviewUseCase(repository: repository),
            contentRepository: repository
        )
        return MemberCenterViewController(viewModel: viewModel, sceneBuilder: self)
    }

    func makeMemberCenterListViewController(
        destination: MemberCenterDestination,
        accountID: Int,
        sessionID: String
    ) -> UIViewController {
        let repository = makeAccountContentRepository()
        let viewModel = MemberCenterListViewModel(
            destination: destination,
            accountId: accountID,
            sessionId: sessionID,
            loadCollectionPage: DefaultLoadAccountCollectionPageUseCase(repository: repository)
        )
        return MemberCenterListViewController(viewModel: viewModel, sceneBuilder: self)
    }

    // MARK: - App Intents

    func makeAppIntentSessionResolver() -> AppIntentSessionResolving {
        AppIntentSessionResolver(
            sessionStore: sessionStore,
            profileProvider: makeAccountContentRepository()
        )
    }

    func makeAppIntentFavoriteActionHandler() -> AppIntentFavoriteActionHandler {
        let sessionRepository = AccountSessionRepository(
            sessionStore: sessionStore,
            profileProvider: makeAccountContentRepository()
        )
        let mediaRepository = AccountMediaStateRepository(network: network)
        return AppIntentFavoriteActionHandler(
            toggleFavorite: DefaultToggleFavoriteUseCase(
                sessionRepository: sessionRepository,
                mediaRepository: mediaRepository
            )
        )
    }

    func makeMovieEntityQuery() -> MovieEntityQuery {
        let repository = MediaSearchRepository(network: network, localization: localization)
        return MovieEntityQuery(
            searchMedia: DefaultSearchMediaUseCase(repository: repository),
            lookupService: AppIntentEntityLookupService(
                network: network,
                localization: localization
            )
        )
    }

    func makeTVSeriesEntityQuery() -> TVSeriesEntityQuery {
        let repository = MediaSearchRepository(network: network, localization: localization)
        return TVSeriesEntityQuery(
            searchMedia: DefaultSearchMediaUseCase(repository: repository),
            lookupService: AppIntentEntityLookupService(
                network: network,
                localization: localization
            )
        )
    }

    // MARK: - Private Helpers

    private func makeAccountContentRepository() -> AccountContentRepository {
        AccountContentRepository(
            network: network,
            localization: localization,
            userProfileStore: userProfileStore,
            listPosterEnricher: AccountListPosterEnricher(
                network: network,
                localization: localization
            )
        )
    }

    private func makeDetailAccountMediaStateController() -> DetailAccountMediaStateController {
        let sessionRepository = AccountSessionRepository(
            sessionStore: sessionStore,
            profileProvider: makeAccountContentRepository()
        )
        let mediaRepository = AccountMediaStateRepository(network: network)

        return DetailAccountMediaStateController(
            isUserAuthenticated: isUserAuthenticated,
            loadAccountMediaStateUseCase: DefaultLoadAccountMediaStateUseCase(
                sessionRepository: sessionRepository,
                mediaRepository: mediaRepository
            ),
            toggleFavoriteUseCase: DefaultToggleFavoriteUseCase(
                sessionRepository: sessionRepository,
                mediaRepository: mediaRepository
            ),
            submitRatingUseCase: DefaultSubmitRatingUseCase(
                sessionRepository: sessionRepository,
                mediaRepository: mediaRepository
            ),
            deleteRatingUseCase: DefaultDeleteRatingUseCase(
                sessionRepository: sessionRepository,
                mediaRepository: mediaRepository
            )
        )
    }

    private var isUserAuthenticated: Bool {
        if case .user = sessionStore.load() {
            return true
        }
        return false
    }

    private var seasonAccountCredential: SeasonAccountCredential? {
        switch sessionStore.load() {
        case .guest(let sessionID):
            return .guest(sessionID: sessionID)

        case .user(let sessionID):
            return .user(sessionID: sessionID)

        case .loggedOut:
            return nil
        }
    }

    private var episodeAccountCredential: EpisodeAccountCredential? {
        switch sessionStore.load() {
        case .guest(let sessionID):
            return .guest(sessionID: sessionID)

        case .user(let sessionID):
            return .user(sessionID: sessionID)

        case .loggedOut:
            return nil
        }
    }
}

// MARK: - RootLoadingViewController

@MainActor
private final class RootLoadingViewController: UIViewController {
    private lazy var animationView = AppFactory.Animation.loadingAir(
        size: AppAnimationView.Metrics.rootSize
    )

    private lazy var titleLabel: UILabel = {
        let label = AppFactory.Label.body(alignment: .center)
        label.text = "正在檢查登入狀態"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.background
        view.addSubview(animationView)
        view.addSubview(titleLabel)

        animationView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -24),
            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        animationView.setAnimating(true)
    }
}
