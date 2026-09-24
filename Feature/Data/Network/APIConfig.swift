//
//  APIConfig.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import Foundation

// MARK: - APIConfig

nonisolated enum APIConfig {

    static let tmdbBaseURL = "https://api.themoviedb.org/3"

    static let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String,
              !key.isEmpty else {
            fatalError("TMDBAPIKey is missing from Info.plist")
        }
        return key
    }()

    // MARK: - Media Kind Paths

    static func reviews(kind: MediaKind, id: Int) -> String {
        switch kind {
        case .movie:
            return Movie.reviews(id: id)

        case .tv:
            return TV.reviews(seriesID: id)
        }
    }

    static func accountStates(kind: MediaKind, id: Int) -> String {
        switch kind {
        case .movie:
            return Movie.accountStates(id: id)

        case .tv:
            return TV.accountStates(seriesID: id)
        }
    }

    static func search(kind: MediaKind) -> String {
        switch kind {
        case .movie:
            return Search.movie

        case .tv:
            return Search.tv
        }
    }

    static func genreList(kind: MediaKind) -> String {
        switch kind {
        case .movie:
            return Genre.movieList

        case .tv:
            return Genre.tvList
        }
    }

    static func discover(kind: MediaKind) -> String {
        switch kind {
        case .movie:
            return Discover.movie

        case .tv:
            return Discover.tv
        }
    }

    // MARK: - Account

    enum Account {
        static let me = "/account"
        static func detail(accountID: Int) -> String { "/account/\(accountID)" }
        static func favorite(accountID: Int) -> String { "/account/\(accountID)/favorite" }
        static func favoriteMovies(accountID: Int) -> String { "/account/\(accountID)/favorite/movies" }
        static func favoriteTV(accountID: Int) -> String { "/account/\(accountID)/favorite/tv" }
        static func lists(accountID: Int) -> String { "/account/\(accountID)/lists" }
        static func ratedMovies(accountID: Int) -> String { "/account/\(accountID)/rated/movies" }
        static func ratedTV(accountID: Int) -> String { "/account/\(accountID)/rated/tv" }
        static func ratedTVEpisodes(accountID: Int) -> String { "/account/\(accountID)/rated/tv/episodes" }
        static func watchlist(accountID: Int) -> String { "/account/\(accountID)/watchlist" }
        static func watchlistMovies(accountID: Int) -> String { "/account/\(accountID)/watchlist/movies" }
        static func watchlistTV(accountID: Int) -> String { "/account/\(accountID)/watchlist/tv" }
    }

    // MARK: - Authentication

    enum Authentication {
        static let validateKey = "/authentication"
        static let guestSessionNew = "/authentication/guest_session/new"
        static let session = "/authentication/session"
        static let sessionConvertV4 = "/authentication/session/convert/4"
        static let sessionNew = "/authentication/session/new"
        static let tokenNew = "/authentication/token/new"
        static let tokenValidateWithLogin = "/authentication/token/validate_with_login"
    }

    // MARK: - Certification

    enum Certification {
        static let movieList = "/certification/movie/list"
        static let tvList = "/certification/tv/list"
    }

    // MARK: - Collection

    enum Collection {
        static func detail(id: Int) -> String { "/collection/\(id)" }
        static func images(id: Int) -> String { "/collection/\(id)/images" }
        static func translations(id: Int) -> String { "/collection/\(id)/translations" }
    }

    // MARK: - Company

    enum Company {
        static func detail(id: Int) -> String { "/company/\(id)" }
        static func alternativeNames(id: Int) -> String { "/company/\(id)/alternative_names" }
        static func images(id: Int) -> String { "/company/\(id)/images" }
    }

    // MARK: - Configuration

    enum Configuration {
        static let details = "/configuration"
        static let countries = "/configuration/countries"
        static let jobs = "/configuration/jobs"
        static let languages = "/configuration/languages"
        static let primaryTranslations = "/configuration/primary_translations"
        static let timezones = "/configuration/timezones"
    }

    // MARK: - Credit

    enum Credit {
        static func detail(id: Int) -> String { "/credit/\(id)" }
    }

    // MARK: - Discover

    enum Discover {
        static let movie = "/discover/movie"
        static let tv = "/discover/tv"
    }

    // MARK: - Find

    enum Find {
        static func byExternalID(externalID: String) -> String { "/find/\(externalID)" }
    }

    // MARK: - Genre

    enum Genre {
        static let movieList = "/genre/movie/list"
        static let tvList = "/genre/tv/list"
    }

    // MARK: - GuestSession

    enum GuestSession {
        static func ratedMovies(guestSessionID: String) -> String { "/guest_session/\(guestSessionID)/rated/movies" }
        static func ratedTV(guestSessionID: String) -> String { "/guest_session/\(guestSessionID)/rated/tv" }
        static func ratedTVEpisodes(guestSessionID: String) -> String { "/guest_session/\(guestSessionID)/rated/tv/episodes" }
    }

    // MARK: - Keyword

    enum Keyword {
        static func detail(id: Int) -> String { "/keyword/\(id)" }
        static func movies(id: Int) -> String { "/keyword/\(id)/movies" }
    }

    // MARK: - List

    enum List {
        static let create = "/list"
        static func detail(listID: Int) -> String { "/list/\(listID)" }
        static func addItem(listID: Int) -> String { "/list/\(listID)/add_item" }
        static func clear(listID: Int) -> String { "/list/\(listID)/clear" }
        static func itemStatus(listID: Int) -> String { "/list/\(listID)/item_status" }
        static func removeItem(listID: Int) -> String { "/list/\(listID)/remove_item" }
    }

    // MARK: - Movie

    enum Movie {
        static let changes = "/movie/changes"
        static let latest = "/movie/latest"
        static let nowPlaying = "/movie/now_playing"
        static let popular = "/movie/popular"
        static let topRated = "/movie/top_rated"
        static let upcoming = "/movie/upcoming"
        static func detail(id: Int) -> String { "/movie/\(id)" }
        static func accountStates(id: Int) -> String { "/movie/\(id)/account_states" }
        static func alternativeTitles(id: Int) -> String { "/movie/\(id)/alternative_titles" }
        static func changes(id: Int) -> String { "/movie/\(id)/changes" }
        static func credits(id: Int) -> String { "/movie/\(id)/credits" }
        static func externalIDs(id: Int) -> String { "/movie/\(id)/external_ids" }
        static func images(id: Int) -> String { "/movie/\(id)/images" }
        static func keywords(id: Int) -> String { "/movie/\(id)/keywords" }
        static func lists(id: Int) -> String { "/movie/\(id)/lists" }
        static func rating(id: Int) -> String { "/movie/\(id)/rating" }
        static func recommendations(id: Int) -> String { "/movie/\(id)/recommendations" }
        static func releaseDates(id: Int) -> String { "/movie/\(id)/release_dates" }
        static func reviews(id: Int) -> String { "/movie/\(id)/reviews" }
        static func similar(id: Int) -> String { "/movie/\(id)/similar" }
        static func translations(id: Int) -> String { "/movie/\(id)/translations" }
        static func videos(id: Int) -> String { "/movie/\(id)/videos" }
        static func watchProviders(id: Int) -> String { "/movie/\(id)/watch/providers" }
    }

    // MARK: - Person

    enum Person {
        static let changes = "/person/changes"
        static let latest = "/person/latest"
        static let popular = "/person/popular"
        static func detail(id: Int) -> String { "/person/\(id)" }
        static func changes(id: Int) -> String { "/person/\(id)/changes" }
        static func combinedCredits(id: Int) -> String { "/person/\(id)/combined_credits" }
        static func externalIDs(id: Int) -> String { "/person/\(id)/external_ids" }
        static func images(id: Int) -> String { "/person/\(id)/images" }
        static func movieCredits(id: Int) -> String { "/person/\(id)/movie_credits" }
        static func taggedImages(id: Int) -> String { "/person/\(id)/tagged_images" }
        static func translations(id: Int) -> String { "/person/\(id)/translations" }
        static func tvCredits(id: Int) -> String { "/person/\(id)/tv_credits" }
    }

    // MARK: - Review

    enum Review {
        static func detail(reviewID: String) -> String { "/review/\(reviewID)" }
    }

    // MARK: - Search

    enum Search {
        static let collection = "/search/collection"
        static let company = "/search/company"
        static let keyword = "/search/keyword"
        static let movie = "/search/movie"
        static let multi = "/search/multi"
        static let person = "/search/person"
        static let tv = "/search/tv"
    }

    // MARK: - Trending

    enum Trending {
        static func all(timeWindow: String) -> String { "/trending/all/\(timeWindow)" }
        static func movie(timeWindow: String) -> String { "/trending/movie/\(timeWindow)" }
        static func person(timeWindow: String) -> String { "/trending/person/\(timeWindow)" }
        static func tv(timeWindow: String) -> String { "/trending/tv/\(timeWindow)" }
    }

    // MARK: - TV

    enum TV {
        static let airingToday = "/tv/airing_today"
        static let changes = "/tv/changes"
        static func episodeChanges(episodeID: Int) -> String { "/tv/episode/\(episodeID)/changes" }
        static func episodeGroupDetail(episodeGroupID: String) -> String { "/tv/episode_group/\(episodeGroupID)" }
        static let latest = "/tv/latest"
        static let onTheAir = "/tv/on_the_air"
        static let popular = "/tv/popular"
        static func seasonChanges(seasonID: Int) -> String { "/tv/season/\(seasonID)/changes" }
        static let topRated = "/tv/top_rated"
        static func detail(seriesID: Int) -> String { "/tv/\(seriesID)" }
        static func accountStates(seriesID: Int) -> String { "/tv/\(seriesID)/account_states" }
        static func aggregateCredits(seriesID: Int) -> String { "/tv/\(seriesID)/aggregate_credits" }
        static func alternativeTitles(seriesID: Int) -> String { "/tv/\(seriesID)/alternative_titles" }
        static func changes(seriesID: Int) -> String { "/tv/\(seriesID)/changes" }
        static func contentRatings(seriesID: Int) -> String { "/tv/\(seriesID)/content_ratings" }
        static func credits(seriesID: Int) -> String { "/tv/\(seriesID)/credits" }
        static func episodeGroups(seriesID: Int) -> String { "/tv/\(seriesID)/episode_groups" }
        static func externalIDs(seriesID: Int) -> String { "/tv/\(seriesID)/external_ids" }
        static func images(seriesID: Int) -> String { "/tv/\(seriesID)/images" }
        static func keywords(seriesID: Int) -> String { "/tv/\(seriesID)/keywords" }
        static func lists(seriesID: Int) -> String { "/tv/\(seriesID)/lists" }
        static func rating(seriesID: Int) -> String { "/tv/\(seriesID)/rating" }
        static func recommendations(seriesID: Int) -> String { "/tv/\(seriesID)/recommendations" }
        static func reviews(seriesID: Int) -> String { "/tv/\(seriesID)/reviews" }
        static func screenedTheatrically(seriesID: Int) -> String { "/tv/\(seriesID)/screened_theatrically" }
        static func seasonDetail(seriesID: Int, seasonNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)" }
        static func seasonAccountStates(seriesID: Int, seasonNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/account_states" }
        static func seasonAggregateCredits(seriesID: Int, seasonNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/aggregate_credits" }
        static func seasonCredits(seriesID: Int, seasonNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/credits" }
        static func episodeDetail(seriesID: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/episode/\(episodeNumber)" }
        static func episodeAccountStates(seriesID: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/episode/\(episodeNumber)/account_states" }
        static func episodeCredits(seriesID: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/episode/\(episodeNumber)/credits" }
        static func episodeExternalIDs(seriesID: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/episode/\(episodeNumber)/external_ids" }
        static func episodeImages(seriesID: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/episode/\(episodeNumber)/images" }
        static func episodeRating(seriesID: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/episode/\(episodeNumber)/rating" }
        static func episodeTranslations(seriesID: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/episode/\(episodeNumber)/translations" }
        static func episodeVideos(seriesID: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/episode/\(episodeNumber)/videos" }
        static func seasonExternalIDs(seriesID: Int, seasonNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/external_ids" }
        static func seasonImages(seriesID: Int, seasonNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/images" }
        static func seasonTranslations(seriesID: Int, seasonNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/translations" }
        static func seasonVideos(seriesID: Int, seasonNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/videos" }
        static func seasonWatchProviders(seriesID: Int, seasonNumber: Int) -> String { "/tv/\(seriesID)/season/\(seasonNumber)/watch/providers" }
        static func similar(seriesID: Int) -> String { "/tv/\(seriesID)/similar" }
        static func translations(seriesID: Int) -> String { "/tv/\(seriesID)/translations" }
        static func videos(seriesID: Int) -> String { "/tv/\(seriesID)/videos" }
        static func watchProviders(seriesID: Int) -> String { "/tv/\(seriesID)/watch/providers" }
    }

    // MARK: - WatchProviders

    enum WatchProviders {
        static let movie = "/watch/providers/movie"
        static let regions = "/watch/providers/regions"
        static let tv = "/watch/providers/tv"
    }

}
