//
//  AppComposition.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import SnapKit
import UIKit

// MARK: - Scene Building

@MainActor
protocol LoginSceneBuilding: AnyObject {
    func makeLoginNavigationController(context: LoginEntryContext) -> UIViewController
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
    func makeSearchResultsViewController(
        mediaKind: MediaKind,
        onItemSelected: @escaping @MainActor (Int) -> Void,
        onSortBarButtonVisibilityChanged: @escaping @MainActor (Bool, MediaSortOrder?) -> Void
    ) -> UIViewController
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
    private let searchHistoryStore: SearchHistoryProviding
    private let localization: AppLocalization
    private let urlSession: URLSession
    private let bundle: Bundle
    private let onSessionChanged: @MainActor (AuthSession) -> Void

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        sessionStore: SessionStoring = SessionStore(),
        userProfileStore: UserProfileStoring = UserProfileStore(),
        searchHistoryStore: SearchHistoryProviding = SearchHistoryStore(),
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

    func makeLoginNavigationController(context: LoginEntryContext) -> UIViewController {
        let viewController = LoginViewController(
            loginViewModel: LoginViewModel(authentication: AuthenticationRepository(network: network)),
            authFlowHandler: makeAuthFlowHandler(),
            entryContext: context
        )
        return UINavigationController(rootViewController: viewController)
    }

    func makeMainTabBarController(
        session: AuthSession,
        initialTab: MainTabKind?
    ) -> MainTabBarController {
        MainTabBarController(
            session: session,
            viewModel: MainTabBarViewModel(),
            avatarProvider: MainTabBarAvatarImageProvider(
                avatarProvider: AccountAvatarRepository(
                    profileProvider: makeAccountContentRepository(),
                    userProfileStore: userProfileStore,
                    urlSession: urlSession
                )
            ),
            sceneBuilder: self,
            initialTab: initialTab
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
        let repository = MainSearchRepository(network: network, localization: localization)
        let viewModel = MainSearchViewModel(
            loadDiscovery: DefaultLoadMainSearchDiscoveryUseCase(repository: repository),
            repository: repository,
            searchHistory: searchHistoryStore
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
        let profileProvider = makeAccountContentRepository()
        let logout = DefaultLogoutUseCase(
            sessionProvider: sessionStore,
            profileProvider: profileProvider
        )
        let imageCache = SDWebImageCacheStore()
        let viewModel = MainMemberSettingViewModel(
            sessionProvider: sessionStore,
            profileProvider: profileProvider,
            searchHistory: searchHistoryStore,
            imageCache: imageCache,
            refreshAccountProfile: DefaultRefreshAccountProfileUseCase(
                sessionProvider: sessionStore,
                profileProvider: profileProvider
            ),
            logout: logout,
            clearLocalData: DefaultClearLocalDataUseCase(
                logout: logout,
                searchHistory: searchHistoryStore,
                imageCache: imageCache
            ),
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

    func makeSearchResultsViewController(
        mediaKind: MediaKind,
        onItemSelected: @escaping @MainActor (Int) -> Void,
        onSortBarButtonVisibilityChanged: @escaping @MainActor (Bool, MediaSortOrder?) -> Void
    ) -> UIViewController {
        let repository = MediaSearchRepository(network: network, localization: localization)
        let viewModel = SearchResultsViewModel(
            mediaKind: mediaKind,
            searchMedia: DefaultSearchMediaUseCase(repository: repository),
            sortMedia: DefaultSortMediaUseCase()
        )
        return SearchResultsViewController(
            mediaKind: mediaKind,
            viewModel: viewModel,
            onItemSelected: onItemSelected,
            onSortBarButtonVisibilityChanged: onSortBarButtonVisibilityChanged
        )
    }

    // MARK: - Details

    func makeMovieDetailViewController(
        movieID: Int
    ) -> UIViewController {
        let repository = MovieDetailRepository(network: network, localization: localization)
        let viewModel = MovieDetailViewModel(
            loadMovieDetailUseCase: DefaultLoadMovieDetailUseCase(
                repository: repository,
                failureReporter: AppLoggerAuxiliaryFailureReporter()
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
                failureReporter: AppLoggerAuxiliaryFailureReporter()
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
                sessionProvider: sessionStore,
                failureReporter: AppLoggerAuxiliaryFailureReporter()
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
                sessionProvider: sessionStore,
                failureReporter: AppLoggerAuxiliaryFailureReporter()
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
                failureReporter: AppLoggerAuxiliaryFailureReporter()
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
        let viewModel = MemberCenterListViewModel(
            destination: destination,
            accountID: accountID,
            sessionID: sessionID,
            contentRepository: makeAccountContentRepository()
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
            movieDetail: MovieDetailRepository(network: network, localization: localization)
        )
    }

    func makeTVSeriesEntityQuery() -> TVSeriesEntityQuery {
        let repository = MediaSearchRepository(network: network, localization: localization)
        return TVSeriesEntityQuery(
            searchMedia: DefaultSearchMediaUseCase(repository: repository),
            seriesDetail: TVDetailRepository(network: network, localization: localization)
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
            sessionProvider: sessionStore,
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

}

// MARK: - RootLoadingViewController

@MainActor
private final class RootLoadingViewController: BaseViewController {

    // MARK: - Metrics

    private enum Metrics {
        static let animationCenterYOffset: CGFloat = -24
        static let titleTopSpacing: CGFloat = 16
        static let titleHorizontalInset: CGFloat = 24
    }

    // MARK: - UI Components

    private lazy var animationView = AppFactory.Animation.loadingAir(
        size: AppAnimationView.Metrics.rootSize
    )

    private lazy var titleLabel: UILabel = {
        let label = AppFactory.Label.body(alignment: .center)
        label.text = "正在檢查登入狀態"
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        animationView.setAnimating(true)
    }

    // MARK: - BaseViewController

    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(animationView)
        view.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        animationView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(Metrics.animationCenterYOffset)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(animationView.snp.bottom).offset(Metrics.titleTopSpacing)
            make.leading.trailing.equalToSuperview().inset(Metrics.titleHorizontalInset)
        }
    }
}
