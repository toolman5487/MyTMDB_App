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

    // MARK: - Account

    enum Account {
        static let me = "/account"
        static func detail(accountId: Int) -> String { "/account/\(accountId)" }
        static func favorite(accountId: Int) -> String { "/account/\(accountId)/favorite" }
        static func favoriteMovies(accountId: Int) -> String { "/account/\(accountId)/favorite/movies" }
        static func favoriteTv(accountId: Int) -> String { "/account/\(accountId)/favorite/tv" }
        static func lists(accountId: Int) -> String { "/account/\(accountId)/lists" }
        static func ratedMovies(accountId: Int) -> String { "/account/\(accountId)/rated/movies" }
        static func ratedTv(accountId: Int) -> String { "/account/\(accountId)/rated/tv" }
        static func ratedTvEpisodes(accountId: Int) -> String { "/account/\(accountId)/rated/tv/episodes" }
        static func watchlist(accountId: Int) -> String { "/account/\(accountId)/watchlist" }
        static func watchlistMovies(accountId: Int) -> String { "/account/\(accountId)/watchlist/movies" }
        static func watchlistTv(accountId: Int) -> String { "/account/\(accountId)/watchlist/tv" }
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
        static func byExternalId(externalId: String) -> String { "/find/\(externalId)" }
    }

    // MARK: - Genre

    enum Genre {
        static let movieList = "/genre/movie/list"
        static let tvList = "/genre/tv/list"
    }

    // MARK: - GuestSession

    enum GuestSession {
        static func ratedMovies(guestSessionId: String) -> String { "/guest_session/\(guestSessionId)/rated/movies" }
        static func ratedTv(guestSessionId: String) -> String { "/guest_session/\(guestSessionId)/rated/tv" }
        static func ratedTvEpisodes(guestSessionId: String) -> String { "/guest_session/\(guestSessionId)/rated/tv/episodes" }
    }

    // MARK: - Keyword

    enum Keyword {
        static func detail(id: Int) -> String { "/keyword/\(id)" }
        static func movies(id: Int) -> String { "/keyword/\(id)/movies" }
    }

    // MARK: - List

    enum List {
        static let create = "/list"
        static func detail(listId: Int) -> String { "/list/\(listId)" }
        static func addItem(listId: Int) -> String { "/list/\(listId)/add_item" }
        static func clear(listId: Int) -> String { "/list/\(listId)/clear" }
        static func itemStatus(listId: Int) -> String { "/list/\(listId)/item_status" }
        static func removeItem(listId: Int) -> String { "/list/\(listId)/remove_item" }
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
        static func externalIds(id: Int) -> String { "/movie/\(id)/external_ids" }
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

    // MARK: - Network

    enum Network {
        static func detail(id: Int) -> String { "/network/\(id)" }
        static func alternativeNames(id: Int) -> String { "/network/\(id)/alternative_names" }
        static func images(id: Int) -> String { "/network/\(id)/images" }
    }

    // MARK: - Person

    enum Person {
        static let changes = "/person/changes"
        static let latest = "/person/latest"
        static let popular = "/person/popular"
        static func detail(id: Int) -> String { "/person/\(id)" }
        static func changes(id: Int) -> String { "/person/\(id)/changes" }
        static func combinedCredits(id: Int) -> String { "/person/\(id)/combined_credits" }
        static func externalIds(id: Int) -> String { "/person/\(id)/external_ids" }
        static func images(id: Int) -> String { "/person/\(id)/images" }
        static func movieCredits(id: Int) -> String { "/person/\(id)/movie_credits" }
        static func taggedImages(id: Int) -> String { "/person/\(id)/tagged_images" }
        static func translations(id: Int) -> String { "/person/\(id)/translations" }
        static func tvCredits(id: Int) -> String { "/person/\(id)/tv_credits" }
    }

    // MARK: - Review

    enum Review {
        static func detail(reviewId: String) -> String { "/review/\(reviewId)" }
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
        static func episodeChanges(episodeId: Int) -> String { "/tv/episode/\(episodeId)/changes" }
        static func episodeGroupDetail(episodeGroupId: String) -> String { "/tv/episode_group/\(episodeGroupId)" }
        static let latest = "/tv/latest"
        static let onTheAir = "/tv/on_the_air"
        static let popular = "/tv/popular"
        static func seasonChanges(seasonId: Int) -> String { "/tv/season/\(seasonId)/changes" }
        static let topRated = "/tv/top_rated"
        static func detail(seriesId: Int) -> String { "/tv/\(seriesId)" }
        static func accountStates(seriesId: Int) -> String { "/tv/\(seriesId)/account_states" }
        static func aggregateCredits(seriesId: Int) -> String { "/tv/\(seriesId)/aggregate_credits" }
        static func alternativeTitles(seriesId: Int) -> String { "/tv/\(seriesId)/alternative_titles" }
        static func changes(seriesId: Int) -> String { "/tv/\(seriesId)/changes" }
        static func contentRatings(seriesId: Int) -> String { "/tv/\(seriesId)/content_ratings" }
        static func credits(seriesId: Int) -> String { "/tv/\(seriesId)/credits" }
        static func episodeGroups(seriesId: Int) -> String { "/tv/\(seriesId)/episode_groups" }
        static func externalIds(seriesId: Int) -> String { "/tv/\(seriesId)/external_ids" }
        static func images(seriesId: Int) -> String { "/tv/\(seriesId)/images" }
        static func keywords(seriesId: Int) -> String { "/tv/\(seriesId)/keywords" }
        static func lists(seriesId: Int) -> String { "/tv/\(seriesId)/lists" }
        static func rating(seriesId: Int) -> String { "/tv/\(seriesId)/rating" }
        static func recommendations(seriesId: Int) -> String { "/tv/\(seriesId)/recommendations" }
        static func reviews(seriesId: Int) -> String { "/tv/\(seriesId)/reviews" }
        static func screenedTheatrically(seriesId: Int) -> String { "/tv/\(seriesId)/screened_theatrically" }
        static func seasonDetail(seriesId: Int, seasonNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)" }
        static func seasonAccountStates(seriesId: Int, seasonNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/account_states" }
        static func seasonAggregateCredits(seriesId: Int, seasonNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/aggregate_credits" }
        static func seasonCredits(seriesId: Int, seasonNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/credits" }
        static func episodeDetail(seriesId: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/episode/\(episodeNumber)" }
        static func episodeAccountStates(seriesId: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/episode/\(episodeNumber)/account_states" }
        static func episodeCredits(seriesId: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/episode/\(episodeNumber)/credits" }
        static func episodeExternalIds(seriesId: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/episode/\(episodeNumber)/external_ids" }
        static func episodeImages(seriesId: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/episode/\(episodeNumber)/images" }
        static func episodeRating(seriesId: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/episode/\(episodeNumber)/rating" }
        static func episodeTranslations(seriesId: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/episode/\(episodeNumber)/translations" }
        static func episodeVideos(seriesId: Int, seasonNumber: Int, episodeNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/episode/\(episodeNumber)/videos" }
        static func seasonExternalIds(seriesId: Int, seasonNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/external_ids" }
        static func seasonImages(seriesId: Int, seasonNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/images" }
        static func seasonTranslations(seriesId: Int, seasonNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/translations" }
        static func seasonVideos(seriesId: Int, seasonNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/videos" }
        static func seasonWatchProviders(seriesId: Int, seasonNumber: Int) -> String { "/tv/\(seriesId)/season/\(seasonNumber)/watch/providers" }
        static func similar(seriesId: Int) -> String { "/tv/\(seriesId)/similar" }
        static func translations(seriesId: Int) -> String { "/tv/\(seriesId)/translations" }
        static func videos(seriesId: Int) -> String { "/tv/\(seriesId)/videos" }
        static func watchProviders(seriesId: Int) -> String { "/tv/\(seriesId)/watch/providers" }
    }

    // MARK: - WatchProviders

    enum WatchProviders {
        static let movie = "/watch/providers/movie"
        static let regions = "/watch/providers/regions"
        static let tv = "/watch/providers/tv"
    }

}
