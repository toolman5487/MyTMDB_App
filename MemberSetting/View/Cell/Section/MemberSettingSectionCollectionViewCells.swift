//
//  MemberSettingSectionCollectionViewCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import UIKit

// MARK: - MemberSettingRefreshProfileCollectionViewCell

@MainActor
final class MemberSettingRefreshProfileCollectionViewCell: MemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberSettingRefreshProfileCollectionViewCell.self)
}

// MARK: - MemberSettingClearProfileCacheCollectionViewCell

@MainActor
final class MemberSettingClearProfileCacheCollectionViewCell: MemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberSettingClearProfileCacheCollectionViewCell.self)
}

// MARK: - MemberSettingAppearanceModeCollectionViewCell

@MainActor
final class MemberSettingAppearanceModeCollectionViewCell: MemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberSettingAppearanceModeCollectionViewCell.self)
}

// MARK: - MemberSettingAppVersionCollectionViewCell

@MainActor
final class MemberSettingAppVersionCollectionViewCell: MemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberSettingAppVersionCollectionViewCell.self)
}

// MARK: - MemberSettingTMDBAttributionCollectionViewCell

@MainActor
final class MemberSettingTMDBAttributionCollectionViewCell: MemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberSettingTMDBAttributionCollectionViewCell.self)
}

// MARK: - MemberSettingLogoutButtonCollectionViewCell

@MainActor
final class MemberSettingLogoutButtonCollectionViewCell: MemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberSettingLogoutButtonCollectionViewCell.self)
}
