//
//  DetailUserActivityFactory.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents
import Foundation

// MARK: - DetailUserActivityFactory

@MainActor
enum DetailUserActivityFactory {
    static func movieActivity(hero: MovieDetailHeroItem) -> NSUserActivity {
        makeActivity(
            activityType: "co.willyhsu.CineBase.movie-detail",
            title: hero.title,
            destination: .movieDetail(id: hero.id),
            mediaType: "movie",
            mediaID: hero.id,
            appEntityIdentifier: EntityIdentifier(for: MovieEntity.self, identifier: hero.id)
        )
    }

    static func tvActivity(hero: TVDetailHeroItem) -> NSUserActivity {
        makeActivity(
            activityType: "co.willyhsu.CineBase.tv-detail",
            title: hero.title,
            destination: .tvDetail(id: hero.id),
            mediaType: "tv",
            mediaID: hero.id,
            appEntityIdentifier: EntityIdentifier(for: TVSeriesEntity.self, identifier: hero.id)
        )
    }

    private static func makeActivity(
        activityType: String,
        title: String,
        destination: AppIntentDestination,
        mediaType: String,
        mediaID: Int,
        appEntityIdentifier: EntityIdentifier
    ) -> NSUserActivity {
        let activity = NSUserActivity(activityType: activityType)
        activity.title = title
        activity.appEntityIdentifier = appEntityIdentifier
        var userInfo: [AnyHashable: Any] = [
            "media_type": mediaType,
            "media_id": mediaID
        ]
        if let url = destination.url {
            userInfo["intent_url"] = url.absoluteString
        }
        activity.userInfo = userInfo
        activity.targetContentIdentifier = "\(mediaType)-\(mediaID)"
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        return activity
    }
}
