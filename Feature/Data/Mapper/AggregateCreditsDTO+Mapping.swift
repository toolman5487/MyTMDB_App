//
//  AggregateCreditsDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AggregateCreditsDTO Mapping

extension AggregateCreditsDTO {

    func mapped() -> AggregateCredits {
        AggregateCredits(
            cast: cast.map { $0.mapped() },
            crew: crew.map { $0.mapped() }
        )
    }
}

// MARK: - AggregateCastMemberDTO Mapping

extension AggregateCastMemberDTO {

    func mapped() -> AggregateCastMember {
        AggregateCastMember(
            id: id,
            name: name,
            characters: roles
                .map(\.character)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            episodeCount: totalEpisodeCount,
            profilePath: profilePath,
            order: order
        )
    }
}

// MARK: - AggregateCrewMemberDTO Mapping

extension AggregateCrewMemberDTO {

    func mapped() -> AggregateCrewMember {
        AggregateCrewMember(
            id: id,
            name: name,
            department: department,
            jobs: jobs
                .map(\.job)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            episodeCount: totalEpisodeCount,
            profilePath: profilePath
        )
    }
}
