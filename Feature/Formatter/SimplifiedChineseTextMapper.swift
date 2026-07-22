//
//  SimplifiedChineseTextMapper.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - SimplifiedChineseTextMapper

nonisolated enum SimplifiedChineseTextMapper {

    static func traditionalChinese(from text: String) -> String {
        text.applyingTransform(
            StringTransform(rawValue: "Hans-Hant"),
            reverse: false
        ) ?? text
    }
}
