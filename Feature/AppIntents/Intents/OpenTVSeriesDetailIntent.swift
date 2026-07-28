//
//  OpenTVSeriesDetailIntent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents

// MARK: - OpenTVSeriesDetailIntent

struct OpenTVSeriesDetailIntent: AppIntent {
    static let title: LocalizedStringResource = "開啟影集詳情"
    static let description = IntentDescription("在 CineBase 開啟指定影集詳情。")
    static let openAppWhenRun = true

    @Parameter(title: "影集")
    var series: TVSeriesEntity

    init() {}

    init(series: TVSeriesEntity) {
        self.series = series
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let isOpened = await AppIntentNavigator.open(.tvDetail(id: series.id))
        let message = isOpened ? "已開啟影集「\(series.name)」。" : "目前無法開啟影集詳情。"
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
