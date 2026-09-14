//
//  AggregateCreditsDTO.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AggregateCreditsDTO

nonisolated struct AggregateCreditsDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [AggregateCastMemberDTO]
    let crew: [AggregateCrewMemberDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
    }

    init(
        id: Int,
        cast: [AggregateCastMemberDTO] = [],
        crew: [AggregateCrewMemberDTO] = []
    ) {
        self.id = id
        self.cast = cast
        self.crew = crew
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([AggregateCastMemberDTO].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([AggregateCrewMemberDTO].self, forKey: .crew) ?? []
    }
}

nonisolated struct AggregateCastMemberDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let gender: Int?
    let knownForDepartment: String
    let name: String
    let originalName: String
    let popularity: Double
    let profilePath: String?
    let roles: [AggregateRoleDTO]
    let totalEpisodeCount: Int
    let order: Int

    enum CodingKeys: String, CodingKey {
        case id
        case gender
        case knownForDepartment = "known_for_department"
        case name
        case originalName = "original_name"
        case popularity
        case profilePath = "profile_path"
        case roles
        case totalEpisodeCount = "total_episode_count"
        case order
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.gender = try container.decodeIfPresent(Int.self, forKey: .gender)
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        self.roles = try container.decodeIfPresent([AggregateRoleDTO].self, forKey: .roles) ?? []
        self.totalEpisodeCount = try container.decodeIfPresent(Int.self, forKey: .totalEpisodeCount) ?? 0
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}

nonisolated struct AggregateRoleDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: String
    let character: String
    let episodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "credit_id"
        case character
        case episodeCount = "episode_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.character = try container.decodeIfPresent(String.self, forKey: .character) ?? ""
        self.episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount) ?? 0
    }
}

nonisolated struct AggregateCrewMemberDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let department: String
    let gender: Int?
    let jobs: [AggregateJobDTO]
    let knownForDepartment: String
    let name: String
    let originalName: String
    let popularity: Double
    let profilePath: String?
    let totalEpisodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case department
        case gender
        case jobs
        case knownForDepartment = "known_for_department"
        case name
        case originalName = "original_name"
        case popularity
        case profilePath = "profile_path"
        case totalEpisodeCount = "total_episode_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.department = try container.decodeIfPresent(String.self, forKey: .department) ?? ""
        self.gender = try container.decodeIfPresent(Int.self, forKey: .gender)
        self.jobs = try container.decodeIfPresent([AggregateJobDTO].self, forKey: .jobs) ?? []
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        self.totalEpisodeCount = try container.decodeIfPresent(Int.self, forKey: .totalEpisodeCount) ?? 0
    }
}

nonisolated struct AggregateJobDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: String
    let job: String
    let episodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "credit_id"
        case job
        case episodeCount = "episode_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.job = try container.decodeIfPresent(String.self, forKey: .job) ?? ""
        self.episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount) ?? 0
    }
}
