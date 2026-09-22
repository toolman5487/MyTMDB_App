//
//  MainMemberSettingPresentationBuilder.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/22.
//

import Foundation

// MARK: - MainMemberSettingPresentationBuilder

nonisolated enum MainMemberSettingPresentationBuilder {

    static func makeContent(
        session: AuthSession,
        profile: AccountProfile?,
        appVersion: String?,
        buildNumber: String?,
        apiLanguageParameter: String,
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingContent {
        MainMemberSettingContent(
            navigationTitle: localization.string(
                "main_member_setting.navigation.title",
                defaultValue: "Settings"
            ),
            sections: makeSections(
                session: session,
                profile: profile,
                appVersionText: appVersionText(
                    appVersion: appVersion,
                    buildNumber: buildNumber,
                    localization: localization
                ),
                apiLanguageParameter: apiLanguageParameter,
                localization: localization
            ),
            profileSummary: makeProfileSummary(profile: profile, localization: localization),
            guestPrompt: makeGuestPrompt(localization: localization)
        )
    }

    // MARK: - Private Methods

    private static func makeSections(
        session: AuthSession,
        profile: AccountProfile?,
        appVersionText: String,
        apiLanguageParameter: String,
        localization: AppInterfaceLocalization
    ) -> [MainMemberSettingSectionItem] {
        let aboutSection = makeAboutSection(
            session: session,
            appVersionText: appVersionText,
            apiLanguageParameter: apiLanguageParameter,
            localization: localization
        )

        guard case .user = session else {
            return [
                makeGuestSection(localization: localization),
                makeDataSection(localization: localization),
                makePreferencesSection(localization: localization),
                aboutSection
            ]
        }

        return [
            makeProfileSection(localization: localization),
            makeAccountSection(profile: profile, localization: localization),
            makeDataSection(localization: localization),
            makePreferencesSection(localization: localization),
            aboutSection,
            makeDangerSection(localization: localization)
        ]
    }

    private static func makeProfileSummary(
        profile: AccountProfile?,
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingProfileSummaryItem {
        guard let profile else {
            return MainMemberSettingProfileSummaryItem(
                displayName: localization.string(
                    "main_member_setting.profile.placeholder_name",
                    defaultValue: "TMDB Member"
                ),
                usernameText: localization.string(
                    "main_member_setting.profile.username_not_synced",
                    defaultValue: "Username not synced"
                ),
                avatarURL: nil,
                avatarImageData: nil
            )
        }

        return MainMemberSettingProfileSummaryItem(
            displayName: profile.displayName,
            usernameText: "@\(profile.username)",
            avatarURL: profile.avatarURL,
            avatarImageData: profile.avatarImageData
        )
    }

    private static func makeGuestPrompt(
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingGuestPromptItem {
        MainMemberSettingGuestPromptItem(
            title: localization.string(
                "main_member_setting.guest.title",
                defaultValue: "Browsing as a Guest"
            ),
            message: localization.string(
                "main_member_setting.guest.message",
                defaultValue: "Sign in to your TMDB account to sync favorites, lists, and ratings."
            ),
            systemImageName: "person.crop.circle.badge.plus",
            loginTitle: localization.string(
                "common.action.sign_in",
                defaultValue: "Sign In"
            ),
            registerTitle: localization.string(
                "common.action.register",
                defaultValue: "Register"
            )
        )
    }

    private static func makeProfileSection(
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .profile,
            rows: [
                MainMemberSettingRowItem(
                    kind: .profileSummary,
                    title: localization.string(
                        "main_member_setting.profile.row.title",
                        defaultValue: "Profile"
                    ),
                    systemImageName: "person.crop.circle",
                    action: .showMemberCenter
                )
            ]
        )
    }

    private static func makeGuestSection(
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .profile,
            rows: [
                MainMemberSettingRowItem(
                    kind: .guestPrompt,
                    title: localization.string(
                        "common.account.guest",
                        defaultValue: "Guest"
                    ),
                    systemImageName: "person.crop.circle.badge.plus"
                )
            ]
        )
    }

    private static func makeAccountSection(
        profile: AccountProfile?,
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .account,
            title: localization.string(
                "main_member_setting.account.section_title",
                defaultValue: "Account"
            ),
            rows: [
                MainMemberSettingRowItem(
                    kind: .accountID,
                    title: "Account ID",
                    systemImageName: "number",
                    accessory: .value(accountIDText(profile: profile, localization: localization))
                ),
                MainMemberSettingRowItem(
                    kind: .refreshProfile,
                    title: localization.string(
                        "main_member_setting.account.refresh_profile",
                        defaultValue: "Refresh Profile"
                    ),
                    systemImageName: "arrow.clockwise",
                    accessory: .disclosure,
                    action: .refreshProfile
                ),
                MainMemberSettingRowItem(
                    kind: .clearProfileCache,
                    title: localization.string(
                        "main_member_setting.account.clear_profile_cache",
                        defaultValue: "Clear Profile Cache"
                    ),
                    systemImageName: "person.crop.circle.badge.xmark",
                    accessory: .disclosure,
                    action: .clearProfileCache
                )
            ]
        )
    }

    private static func makeDataSection(
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .data,
            title: localization.string(
                "main_member_setting.data.section_title",
                defaultValue: "Cache and Data"
            ),
            rows: [
                MainMemberSettingRowItem(
                    kind: .clearImageCache,
                    title: localization.string(
                        "main_member_setting.data.clear_image_cache",
                        defaultValue: "Clear Image Cache"
                    ),
                    systemImageName: "photo.badge.arrow.down",
                    accessory: .disclosure,
                    action: .clearImageCache
                ),
                MainMemberSettingRowItem(
                    kind: .clearSearchHistory,
                    title: localization.string(
                        "main_member_setting.data.clear_search_history",
                        defaultValue: "Clear Search History"
                    ),
                    systemImageName: "magnifyingglass.circle",
                    accessory: .disclosure,
                    action: .clearSearchHistory
                ),
                MainMemberSettingRowItem(
                    kind: .clearAllLocalData,
                    title: localization.string(
                        "main_member_setting.data.clear_all_local_data",
                        defaultValue: "Clear All Local Data"
                    ),
                    systemImageName: "trash",
                    role: .destructive,
                    accessory: .disclosure,
                    action: .clearAllLocalData
                )
            ]
        )
    }

    private static func makePreferencesSection(
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .preferences,
            title: localization.string(
                "main_member_setting.preferences.section_title",
                defaultValue: "Preferences"
            ),
            rows: [
                MainMemberSettingRowItem(
                    kind: .appInterfaceLanguage,
                    title: localization.string(
                        "main_member_setting.language.title",
                        defaultValue: "Language Preference"
                    ),
                    systemImageName: "globe",
                    accessory: .menu(
                        selectedOptionID: localization.language.rawValue,
                        options: makeInterfaceLanguageMenuOptions(localization: localization)
                    )
                ),
                MainMemberSettingRowItem(
                    kind: .defaultSort,
                    title: localization.string(
                        "main_member_setting.preferences.default_sort",
                        defaultValue: "Default List Sort"
                    ),
                    systemImageName: "arrow.up.arrow.down",
                    accessory: .value(localization.string(
                        "common.sort.popularity",
                        defaultValue: "Popularity"
                    ))
                ),
                MainMemberSettingRowItem(
                    kind: .defaultContentType,
                    title: localization.string(
                        "main_member_setting.preferences.default_content_type",
                        defaultValue: "Default Content Type"
                    ),
                    systemImageName: "rectangle.stack",
                    accessory: .value(localization.string(
                        "common.media.movies_and_tv",
                        defaultValue: "Movies and TV Shows"
                    ))
                )
            ]
        )
    }

    private static func makeInterfaceLanguageMenuOptions(
        localization: AppInterfaceLocalization
    ) -> [MainMemberSettingMenuOption] {
        AppInterfaceLanguage.allCases.map { language in
            MainMemberSettingMenuOption(
                id: language.rawValue,
                title: interfaceLanguageTitle(for: language, localization: localization)
            )
        }
    }

    private static func interfaceLanguageTitle(
        for language: AppInterfaceLanguage,
        localization: AppInterfaceLocalization
    ) -> String {
        switch language {
        case .traditionalChinese:
            return localization.string(
                "main_member_setting.language.option.traditional_chinese",
                defaultValue: "Traditional Chinese"
            )

        case .english:
            return localization.string(
                "main_member_setting.language.option.english",
                defaultValue: "English"
            )

        case .japanese:
            return localization.string(
                "main_member_setting.language.option.japanese",
                defaultValue: "Japanese"
            )
        }
    }

    private static func makeAboutSection(
        session: AuthSession,
        appVersionText: String,
        apiLanguageParameter: String,
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .about,
            title: localization.string(
                "main_member_setting.about.section_title",
                defaultValue: "About"
            ),
            rows: [
                MainMemberSettingRowItem(
                    kind: .appVersion,
                    title: localization.string(
                        "main_member_setting.about.app_version",
                        defaultValue: "App Version"
                    ),
                    systemImageName: "info.circle",
                    accessory: .value(appVersionText)
                ),
                MainMemberSettingRowItem(
                    kind: .apiDataLanguage,
                    title: localization.string(
                        "main_member_setting.about.api_data_language",
                        defaultValue: "API Data Language"
                    ),
                    systemImageName: "textformat",
                    accessory: .value(apiLanguageParameter)
                ),
                MainMemberSettingRowItem(
                    kind: .loginStatus,
                    title: localization.string(
                        "main_member_setting.about.login_status",
                        defaultValue: "Current Sign-in Status"
                    ),
                    systemImageName: "person.crop.circle.badge.checkmark",
                    accessory: .value(loginStatusText(session: session, localization: localization))
                ),
                MainMemberSettingRowItem(
                    kind: .tmdbAttribution,
                    title: localization.string(
                        "main_member_setting.about.tmdb_attribution",
                        defaultValue: "TMDB Data Source"
                    ),
                    systemImageName: "film.stack",
                    accessory: .disclosure,
                    action: .tmdbAttribution
                )
            ]
        )
    }

    private static func makeDangerSection(
        localization: AppInterfaceLocalization
    ) -> MainMemberSettingSectionItem {
        MainMemberSettingSectionItem(
            kind: .danger,
            rows: [
                MainMemberSettingRowItem(
                    kind: .logout,
                    title: localization.string(
                        "common.action.sign_out",
                        defaultValue: "Sign Out"
                    ),
                    systemImageName: "rectangle.portrait.and.arrow.right",
                    role: .destructive,
                    action: .logout
                )
            ]
        )
    }

    private static func appVersionText(
        appVersion: String?,
        buildNumber: String?,
        localization: AppInterfaceLocalization
    ) -> String {
        switch (appVersion, buildNumber) {
        case (.some(let appVersion), .some(let buildNumber)):
            return "\(appVersion) (\(buildNumber))"

        case (.some(let appVersion), .none):
            return appVersion

        case (.none, .some(let buildNumber)):
            return buildNumber

        case (.none, .none):
            return localization.string(
                "common.value.unknown",
                defaultValue: "Unknown"
            )
        }
    }

    private static func accountIDText(
        profile: AccountProfile?,
        localization: AppInterfaceLocalization
    ) -> String {
        guard let accountID = profile?.id else {
            return localization.string(
                "common.value.not_synced",
                defaultValue: "Not Synced"
            )
        }

        return String(accountID)
    }

    private static func loginStatusText(
        session: AuthSession,
        localization: AppInterfaceLocalization
    ) -> String {
        switch session {
        case .loggedOut:
            return localization.string(
                "common.account.signed_out",
                defaultValue: "Signed Out"
            )

        case .guest:
            return localization.string(
                "common.account.guest",
                defaultValue: "Guest"
            )

        case .user:
            return localization.string(
                "common.account.member",
                defaultValue: "Member"
            )
        }
    }
}
