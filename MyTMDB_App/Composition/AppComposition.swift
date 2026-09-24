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
    func makeCompanyDetailViewController(companyID: Int) -> UIViewController
    func makeReviewListViewController(mediaKind: MediaKind, mediaID: Int) -> UIViewController
    func makeDetailContentListViewController(
        configuration: DetailContentListConfiguration,
        pageProvider: (any DetailContentListPageProviding)?
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
    func applyInterfaceLanguage(
        _ language: AppInterfaceLanguage,
        session: AuthSession
    )
}

// MARK: - AppComposition

@MainActor
final class AppComposition: MainTabSceneBuilding, AppFlowRouting {

    // MARK: - Properties

    private let network: NetworkServicing
    private let sessionStore: SessionStoring
    private let userProfileStore: UserProfileStoring
    private let searchHistoryStore: SearchHistoryProviding
    private let interfaceLanguageStore: AppInterfaceLanguageStoring
    private let localization: AppLocalization
    private var interfaceLocalization: AppInterfaceLocalization
    private let urlSession: URLSession
    private let bundle: Bundle
    private let onSessionChanged: @MainActor (AuthSession) -> Void
    private let onInterfaceLanguageChanged: @MainActor (AuthSession) -> Void

    var currentInterfaceLocalization: AppInterfaceLocalization {
        interfaceLocalization
    }

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        sessionStore: SessionStoring = SessionStore(),
        userProfileStore: UserProfileStoring = UserProfileStore(),
        searchHistoryStore: SearchHistoryProviding = SearchHistoryStore(),
        interfaceLanguageStore: AppInterfaceLanguageStoring = AppInterfaceLanguageStore(),
        localization: AppLocalization = .current,
        urlSession: URLSession = .shared,
        bundle: Bundle = .main,
        onSessionChanged: @escaping @MainActor (AuthSession) -> Void = { _ in },
        onInterfaceLanguageChanged: @escaping @MainActor (AuthSession) -> Void = { _ in }
    ) {
        self.network = network
        self.sessionStore = sessionStore
        self.userProfileStore = userProfileStore
        self.searchHistoryStore = searchHistoryStore
        self.interfaceLanguageStore = interfaceLanguageStore
        self.localization = localization
        self.interfaceLocalization = AppInterfaceLocalization(
            language: interfaceLanguageStore.load()
        )
        self.urlSession = urlSession
        self.bundle = bundle
        self.onSessionChanged = onSessionChanged
        self.onInterfaceLanguageChanged = onInterfaceLanguageChanged
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
        RootLoadingViewController(localization: interfaceLocalization)
    }

    func makeLoginNavigationController(context: LoginEntryContext) -> UIViewController {
        let viewController = LoginViewController(
            loginViewModel: LoginViewModel(
                authentication: AuthenticationRepository(network: network),
                localization: interfaceLocalization
            ),
            authFlowHandler: makeAuthFlowHandler(),
            entryContext: context,
            localization: interfaceLocalization
        )
        return UINavigationController(rootViewController: viewController)
    }

    func makeMainTabBarController(
        session: AuthSession,
        initialTab: MainTabKind?
    ) -> MainTabBarController {
        MainTabBarController(
            session: session,
            viewModel: MainTabBarViewModel(localization: interfaceLocalization),
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

    func applyInterfaceLanguage(
        _ language: AppInterfaceLanguage,
        session: AuthSession
    ) {
        guard interfaceLocalization.language != language else { return }
        interfaceLanguageStore.save(language)
        interfaceLocalization = AppInterfaceLocalization(language: language)
        onInterfaceLanguageChanged(session)
    }

    // MARK: - Main Tabs

    func makeMainHomeViewController() -> UIViewController {
        let repository = HomeContentRepository(network: network, localization: localization)
        let viewModel = MainHomeViewModel(
            loadHomeSections: DefaultLoadHomeSectionsUseCase(repository: repository),
            localization: interfaceLocalization
        )
        return MainHomeViewController(
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
        )
    }

    func makeMainSearchViewController() -> UIViewController {
        let repository = MainSearchRepository(network: network, localization: localization)
        let viewModel = MainSearchViewModel(
            loadDiscovery: DefaultLoadMainSearchDiscoveryUseCase(repository: repository),
            repository: repository,
            searchHistory: searchHistoryStore,
            localization: interfaceLocalization
        )
        return MainSearchViewController(
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
        )
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
            initialGenreID: initialGenreID,
            localization: interfaceLocalization
        )
        return MainMediaListViewController(
            mediaKind: mediaKind,
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
        )
    }

    func makeMainMemberSettingViewController() -> UIViewController {
        let profileProvider = makeAccountContentRepository()
        let authentication = AuthenticationRepository(network: network)
        let logout = DefaultLogoutUseCase(
            sessionProvider: sessionStore,
            profileProvider: profileProvider,
            authentication: authentication
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
            interfaceLocalization: interfaceLocalization,
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
            contentRepository: contentRepository,
            localization: interfaceLocalization
        )
        return HomeSectionListViewController(
            category: category,
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
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
            sortMedia: DefaultSortMediaUseCase(),
            localization: interfaceLocalization
        )
        return SearchResultsViewController(
            mediaKind: mediaKind,
            viewModel: viewModel,
            onItemSelected: onItemSelected,
            onSortBarButtonVisibilityChanged: onSortBarButtonVisibilityChanged,
            interfaceLocalization: interfaceLocalization
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
            accountMediaController: makeDetailAccountMediaStateController(),
            localization: interfaceLocalization
        )
        return MovieDetailViewController(
            movieID: movieID,
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
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
            accountMediaController: makeDetailAccountMediaStateController(),
            localization: interfaceLocalization
        )
        return TVDetailViewController(
            seriesID: seriesID,
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
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
            ),
            localization: interfaceLocalization
        )
        return SeasonDetailViewController(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
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
            accountMediaController: makeDetailAccountMediaStateController(),
            localization: interfaceLocalization
        )
        return EpisodeDetailViewController(
            input: input,
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
        )
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
            loadPersonCreditsUseCase: DefaultLoadPersonCreditsUseCase(repository: repository),
            localization: interfaceLocalization
        )
        return PersonDetailViewController(
            personID: personID,
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
        )
    }

    func makeCompanyDetailViewController(
        companyID: Int
    ) -> UIViewController {
        let repository = CompanyDetailRepository(network: network, localization: localization)
        let viewModel = CompanyDetailViewModel(
            loadCompanyDetailUseCase: DefaultLoadCompanyDetailUseCase(
                repository: repository,
                failureReporter: AppLoggerAuxiliaryFailureReporter()
            ),
            repository: repository,
            localization: interfaceLocalization
        )
        return CompanyDetailViewController(
            companyID: companyID,
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
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
            filterReviewsUseCase: DefaultFilterReviewsUseCase(),
            localization: interfaceLocalization
        )
        return ReviewListViewController(
            mediaID: mediaID,
            viewModel: viewModel,
            interfaceLocalization: interfaceLocalization
        )
    }

    func makeDetailContentListViewController(
        configuration: DetailContentListConfiguration,
        pageProvider: (any DetailContentListPageProviding)?
    ) -> UIViewController {
        DetailContentListViewController(
            configuration: configuration,
            pageProvider: pageProvider,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
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
            contentRepository: repository,
            localization: interfaceLocalization
        )
        return MemberCenterViewController(
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
        )
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
            contentRepository: makeAccountContentRepository(),
            localization: interfaceLocalization
        )
        return MemberCenterListViewController(
            viewModel: viewModel,
            sceneBuilder: self,
            interfaceLocalization: interfaceLocalization
        )
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
            ),
            localization: interfaceLocalization
        )
    }

}

// MARK: - RootLoadingViewController

@MainActor
private final class RootLoadingViewController: BaseViewController {

    private let localization: AppInterfaceLocalization

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
        label.text = localization.string(
            "root_loading.session_validation.title",
            defaultValue: "Checking Sign-in Status"
        )
        return label
    }()

    // MARK: - Initialization

    init(localization: AppInterfaceLocalization) {
        self.localization = localization
        super.init(nibName: nil, bundle: nil)
        setInterfaceLocalization(localization)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
