# SDD: CineBase App 內繁體中文／英文／日文介面切換

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| 文件 ID | `SDD-INTERFACE-LANGUAGE-IN-APP-SWITCH` |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | Swift 6.0，`SWIFT_STRICT_CONCURRENCY = complete` |
| 既有架構 | UIKit + MVVM + Clean Architecture + Router + `AppComposition` |
| 功能入口 | 個人／設定頁 `MainMemberSetting` 的「偏好設定」區段 |
| 功能範圍 | App 內本地寫死的使用者可見文案；繁體中文／英文／日文 |
| 驗收責任 | 開發者自行執行 Build、Simulator／實機與英文／日文文案驗收 |
| 規格狀態 | `Accepted` |
| 實作狀態 | `Done`（v1.4 繁體中文／英文／日文） |
| 驗證狀態 | Build `Passed`（2026-09-26，iOS Simulator Debug）；Runtime `Partial`（繁體中文非正式走查正常；英文、日文切換與 Copy Review NotRun，由開發者驗收） |
| 最後更新 | 2026-09-26 |

---

## 1. 目的

本文件定義 CineBase 在個人／設定頁新增介面語言選單，讓使用者可在 App 內切換本地介面文案：

- Menu 選擇「繁體中文」：使用繁體中文介面。
- Menu 選擇「English」：使用英文介面。
- Menu 選擇「日本語」：使用日文介面。
- 選擇會保存在本機，重新啟動 App 後維持不變。
- 切換後立即重建 App 主畫面並停留在設定分頁。
- 僅切換 App 本地定義的標題、按鈕、提示、錯誤、空狀態、格式化標籤與無障礙文案。
- 不改變 TMDB API 的語言、地區、時區、圖片／影片語言參數或後端回傳內容。

本 SDD 遵循：

- `SDD-CleanArchitecture-Migration.md` 的現行分層與依賴方向。
- `SDD-Architecture-Unified-Interface-Naming.md` 的 Storage、ViewModel、Router 與 Scene Builder 命名規則。
- `SceneDelegate` 管理 root，`AppComposition` 建立並注入場景，不新增 `AppCoordinator`。

v1.4 將日文視為既有介面語言模型的第三個 case，一次完成日文字串與 Menu cutover，不新增暫時 feature flag。本文件更新只代表日文規格已鎖定；各項實作與驗證狀態仍以第 16 節為準。

---

## 2. 決策摘要

| 決策 | 結論 |
|------|------|
| 語言數量 | 繁體中文、英文與日文 |
| 選擇模型 | `AppInterfaceLanguage` raw value；目前語言在 Menu 內顯示勾選，不使用二元 Bool |
| 初始值 | 沒有已儲存設定時使用繁體中文，維持既有 App 行為 |
| 儲存位置 | `UserDefaults`，透過既有 `AppPreferencesStorage` 同步存取 |
| 生效方式 | 儲存後重建 Main root，不要求關閉 App |
| 切換後位置 | 保留登入狀態並回到 `.memberSetting` 分頁 |
| UI 資源 | `Localizable.xcstrings`，來源語言為英文，提供完整 `zh-Hant` 與 `ja` 翻譯 |
| 執行期查字串 | 明確傳入介面 `Locale`，不依賴 `Locale.current` 自動切換 |
| API 語言 | 完全沿用現有 `AppLocalization`，不受介面語言選擇影響 |
| 自動化測試 | 本次不新增 test target；以靜態檢查與開發者手動驗收為主 |
| 最終驗收 | 由開發者自行操作、確認文案後回填結果 |

---

## 3. 目標與非目標

### 3.1 目標

- 在 `MainMemberSetting` 的「偏好設定」區段第一列新增語言 Menu 按鈕。
- 訪客與已登入會員都能看到並使用 Menu。
- Menu 顯示值與實際介面語言一致，且目前選項有勾選狀態。
- App 內所有本地使用者可見文案提供繁體中文、英文與日文。
- 本地組合的日期、數量、季／集、評分、空狀態與 fallback 文案依介面語言呈現。
- 本地 Accessibility label、value、hint 依介面語言呈現。
- 切換後不登出、不清除會員資料、搜尋紀錄或圖片快取。
- 語言設定在登出與「清除所有本機資料」後仍保留；它是 App 偏好，不是帳號資料。
- ViewModel 不 import UIKit，不直接依賴 `UserDefaults` 或 Data concrete Store。
- Swift 6 下跨隔離傳遞的語言值符合 `Sendable`。

### 3.2 非目標

- 不修改 `Feature/Config/AppLocalization.swift` 的 API localization 行為。
- 不修改 `languageParameter`、`imageLanguageParameter`、`regionCode` 或 `timeZoneIdentifier`。
- 不修改任何 Repository 的 `language`、`region`、`timezone`、`include_image_language` 或 `include_video_language` query。
- 不要求 TMDB 電影名稱、影集名稱、人物名稱、簡介、評論或其他後端欄位跟隨介面語言選擇。
- 不翻譯或改寫後端實際回傳的文字。
- 不增加翻譯 API、AI 翻譯、第三方 localization 套件或遠端設定。
- 不設定或竄改非公開的 `AppleLanguages` UserDefaults。
- 不使用 method swizzling、替換 `Bundle.main` 或全域可變 singleton 切換語言。
- 不修改登入、Session、收藏、評分、搜尋、分頁或導航業務規則。
- 不要求 Siri、App Intents、App Shortcuts 等 App 外系統介面跟隨 App 內語言選擇；它們維持系統語言規則，另案處理。
- 不翻譯 developer log、API path、JSON key、UserDefaults key、URL、SF Symbol 名稱、程式 symbol 或 TMDB／CineBase 品牌名。
- 不新增 Coordinator、Service Locator、BaseViewModel、無業務價值的 UseCase、SPM package 或測試 target。

---

## 4. 現況盤點

### 4.1 設定頁語言選擇元件

v1.2 使用 `UISwitch` 將語言綁定為 Bool，不利於新增第三種以上語言。v1.3 改為：

- `MainMemberSettingRowAccessory.menu(selectedOptionID:options:)` 表達任意數量選項。
- `MainMemberSettingButtonCollectionViewCell` 以 `UIButton` 顯示 `UIMenu`。
- `AppInterfaceLanguage` 採 `CaseIterable`，ViewModel 將所有 case 建立為 Menu option。
- Menu 使用 `.singleSelection`，目前語言以 `UIAction.State.on` 顯示勾選。
- callback 回傳語言 raw value，不再傳遞 `Bool`。
- Menu 仍位於所有登入狀態都會顯示的 `preferencesSection`。

這個模型允許 v1.4 直接加入 `.japanese` 與對應 String Catalog 文案，不必增加新的 Switch 或修改 Bool mapping；未來新增其他語言也沿用相同擴充點。

### 4.2 目前的 `AppLocalization` 是 API 設定

現行 `AppLocalization`：

- 從 `Locale.autoupdatingCurrent`、`Locale.preferredLanguages` 與 `TimeZone.autoupdatingCurrent` 建立。
- 被各 Repository 用於 TMDB API query。
- 被 `AppComposition` 保存後注入 Repository 與部分 Presentation Builder。
- 在設定頁「API 資料語言」列顯示 `languageParameter`。

本次新增的介面語言不得覆寫、重用或改變這條資料流。實作後必須同時存在：

```text
AppInterfaceLanguage  -> 本地 UI 文案與本地格式化
AppLocalization       -> TMDB API language / region / timezone
```

兩者數值不同是合法且預期的。例如英文介面仍可能顯示 TMDB 以 `zh-TW` 回傳的片名與簡介。

### 4.3 本地文案基線

v1.4 開始前的 String Catalog 基線（2026-09-19）：

- `MyTMDB_App/Localizable.xcstrings` 共 475 個 key。
- 其中 448 個 key 已有 `en` 與 `zh-Hant`，且由 App 內 `string`／`formatted` 呼叫使用；這 448 個 key 是既有日文翻譯目標。
- 另有 27 個沒有 localization 的 Xcode 自動擷取／App Intents 相關 key；它們不在本 SDD 的 App 內介面範圍，不納入日文完成率。
- v1.4 會新增 `main_member_setting.language.option.japanese`，完成後預期共 476 個 key：449 個 App 內範圍 key 具備 `en`／`zh-Hant`／`ja`，27 個排除 key 維持沒有 localization。
- 既有 4 個 English plural key 必須保留 plural variation；日文可依語法使用單一 string unit，但格式參數集合不得改變。
- Xcode project 既有 `en`、`zh-Hant` 與 `Base` region；v1.4 新增 `ja`。

v1.1 雙語實作完成後的中文 literal 掃描結果只剩 13 個檔案，全部已分類為不遷移；v1.4 仍沿用相同邊界：

| 檔案 | 數量 | 分類 |
|------|------|------|
| `Feature/AppIntents/**`（12 檔） | 54 | App 外系統介面，依 3.2 另案處理 |
| `Feature/Formatter/BaseFormatter.swift` | 574 | TMDB 英文職稱／部門的繁中對照表；English／日本語模式顯示 TMDB 原值，見 13.1 |

`MovieDetail`、`TVDetail`、`SeasonDetail`、`EpisodeDetail` 內 `"\(video.type) · \(video.site)"` 與 `metadata(_:)` 的 `" · "` 會被 `\p{Han}` 命中，原因是 U+00B7 的 Script_Extensions 含 Han，屬誤判。

---

## 5. 使用者體驗規格

### 5.1 Menu 位置與內容

Menu 按鈕放在 `MainMemberSetting` 的「偏好設定」區段第一列，既有「預設列表排序」與「預設內容類型」順序往後移。

| 介面語言 | Row 標題 | 按鈕顯示值 |
|----------|----------|--------------|
| 繁體中文 | 語言偏好 | 繁體中文 |
| English | Language Preference | English |
| 日本語 | 表示言語 | 日本語 |

其他規格：

- SF Symbol：`globe`。
- 不顯示副標題。
- Menu 按鈕使用 `ThemeColor.highlight`，並顯示 `chevron.down`。
- Row 高度沿用一般設定列，不新增特殊高度。
- Menu 在繁中介面顯示「繁體中文」／「英文」／「日本語」。
- Menu 在英文介面顯示 `Traditional Chinese`／`English`／`Japanese`。
- Menu 在日文介面顯示「繁体字中国語」／「英語」／「日本語」。
- 選單採單選，當前語言顯示勾選。
- 點擊 Menu 選項才觸發切換；row 不執行 disclosure navigation。
- 重複選擇目前語言不得重建 root。

### 5.2 切換行為

1. 使用者從 Menu 選擇語言。
2. 將新語言寫入本機偏好。
3. 更新 `AppComposition` 持有的介面 localization value。
4. 以目前 `AuthSession` 重新建立 Main root。
5. 沿用 `MainTabBarController.selectedTabKind`，回到 `.memberSetting`。
6. 新 root 的所有 ViewModel、Presentation Builder、Router 與 View 使用新介面語言。

切換會重置目前 Navigation Stack。因入口位於設定 root，此限制可接受，不另做畫面樹原地刷新。

重新建立畫面可能重新觸發既有 API request，但 request 的語言、地區、時區 query 必須與切換前完全相同。

### 5.3 啟動、登出與清除資料

- App 啟動時先讀取已儲存的介面語言，再建立 root。
- 沒有已儲存值或 raw value 無效時，回退為繁體中文。
- 登出後，登入頁仍使用使用者選擇的介面語言。
- 再次登入或進入訪客模式後，語言維持不變。
- 「清除所有本機資料」不清除介面語言設定。
- 刪除並重新安裝 App 後回到繁體中文預設值。

### 5.4 「API 資料語言」列

既有 About 區段的「API 資料語言」列保留：

- Row 標題需本地化為 `API Data Language`／`API 資料語言`。
- Accessory value 繼續顯示現行 `AppLocalization.languageParameter`。
- 介面語言選成英文時，不得把 value 強制改為 `en-US`。

這一列可讓開發者與使用者辨認「App 介面語言」與「TMDB API 資料語言」是兩個獨立設定來源。

### 5.5 Accessibility

本次只補足新語言 Menu 必要的無障礙行為，不擴張其他既有 Accessibility 範圍：

- Menu 按鈕可單獨聚焦。
- Label 使用當前語言的 row title。
- Value 使用目前選取的語言名稱。
- 不另外加入自訂 Hint；按鈕與 Menu 使用 UIKit 系統語意。
- Menu action 的勾選狀態由 `UIAction.State.on` 表達。

---

## 6. 本地化範圍判定

### 6.1 必須本地化

凡是由 App source 決定、在 App 內顯示給使用者的文案，均在本次範圍：

- Navigation title、Tab title 與 section header。
- Button、menu、filter、sort、placeholder 與 segmented control title。
- Alert title、message、action title。
- Loading、empty、error、retry、fallback 與狀態文案。
- 本地產生的電影／影集／季／集／人物 metadata label。
- 本地組合的日期、數量、頁數、評分與描述句。
- 本地針對後端 enum／代碼產生的顯示名稱。
- Accessibility label、value、hint。
- WebView、Player、Image Preview、PageSheet 與共用元件文案。
- Login、MainTab、Home、Search、Media List、Detail、Review、Member Center、Settings 全部 App 內流程。

### 6.2 不得翻譯

以下內容即使顯示在畫面上，也保持原值：

- TMDB 回傳的 `title`、`name`、`overview`、`biography`、review content 等自由文字。
- TMDB 帳號的 username、display name、list name。
- 人名、公司名、網站名與外部連結標題，除非目前本來就是本地固定 UI label。
- API 錯誤的 developer diagnostic；使用者看到的 ErrorMessage 仍需本地化。
- 版本號、ID、URL、日期原始值與數值本身；只有周邊格式與 label 可本地化。

### 6.3 判定範例

| 畫面內容 | 是否本地化 | 原因 |
|----------|------------|------|
| `電影` Tab title | 是 | App 固定 UI title |
| `熱門電影` Section title | 是 | App 固定 presentation 文案 |
| `上映日期：2026-09-19` | `上映日期` 與格式是 | App 本地組合 |
| TMDB 回傳電影名稱 | 否 | 後端內容 |
| TMDB 回傳 overview | 否 | 後端內容 |
| `尚無簡介` | 是 | App fallback |
| `第 2 季` | 是 | App 本地格式化 |
| `API 資料語言` | 是 | App 固定 UI title |
| `zh-TW` accessory value | 否 | 現行 API 設定值 |

---

## 7. 架構設計

### 7.1 型別責任

#### `AppInterfaceLanguage`

位置：`Feature/Config/AppInterfaceLanguage.swift`

```swift
nonisolated enum AppInterfaceLanguage: String, CaseIterable, Sendable, Equatable {
    case traditionalChinese = "zh-Hant"
    case english = "en"
    case japanese = "ja"
}
```

責任：

- 表達 App 內介面語言。
- 提供對應 `Locale`。
- 透過 `CaseIterable` 提供 Menu 選項來源。
- 不提供 Bool mapping，避免語言模型被限制為兩種。
- 不提供任何 TMDB API query value。

#### `AppInterfaceLanguageStoring`／`AppInterfaceLanguageStore`

位置：`Feature/Data/Storage/AppInterfaceLanguageStore.swift`

```swift
nonisolated protocol AppInterfaceLanguageStoring: Sendable {
    func load() -> AppInterfaceLanguage
    func save(_ language: AppInterfaceLanguage)
}
```

實作規則：

- 透過 `AppPreferencesStorage` 存取 `UserDefaults`。
- Storage key 使用 `AppInterfaceLanguage.v1`。
- 不直接暴露 `UserDefaults`。
- `load()` 對缺值或未知 raw value 回傳 `.traditionalChinese`。
- 不建立單獨 UseCase；單一偏好讀寫沒有額外條件編排。

#### `AppInterfaceLocalization`

位置：`Feature/Config/AppInterfaceLocalization.swift`

責任：

- 持有不可變的 `AppInterfaceLanguage` value。
- 查字串時明確指定介面語言對應的 localization，不依賴系統語言。
- 可安全注入 ViewModel、Presentation Builder、Router 與需要產生文字的共用 Formatter。
- 不讀取或修改 `AppLocalization`。
- 不使用 global mutable state。

實作 API（v1.1 定案）：

```swift
nonisolated struct AppInterfaceLocalization: Sendable, Equatable {
    let language: AppInterfaceLanguage

    func string(_ key: StaticString, defaultValue: String) -> String {
        Bundle.main.localizedString(
            forKey: key.description,
            value: defaultValue,
            table: nil,
            localizations: [language.locale.language]
        )
    }

    func formatted(_ key: StaticString, defaultValue: String, _ arguments: CVarArg...) -> String {
        String(
            format: string(key, defaultValue: defaultValue),
            locale: language.locale,
            arguments: arguments
        )
    }
}
```

v1.0 草案的 `String(localized:defaultValue:bundle:locale:comment:)` 經實測不可用，原因有兩個：

1. 該 initializer 的 `locale` 只影響 interpolation 格式化，不會選擇 localization。以 Xcode 27 編譯 catalog 後實測，傳入 `zh-Hant` 仍回傳 `Bundle` preferred localization（`en`）的值，App 內語言選擇將完全無效。
2. `defaultValue` 若宣告為 `String.LocalizationValue`，`SWIFT_EMIT_LOC_STRINGS = YES` 會把呼叫端的英文字面值當成 key 抽取；在 Xcode IDE build 後同步進 catalog，產生數百筆以英文句子為 key 的無效項目。

`Bundle.localizedString(forKey:value:table:localizations:)`（iOS 17+）以明確 localization 查表，既有實測可正確選擇 `en`／`zh-Hant`；v1.4 以同一機制加入 `ja`。`String(format:locale:arguments:)` 能套用 `.stringsdict` 的 plural 規則。三項原則（明確 locale、value semantics、無 global mutation）維持不變。

`static let traditionalChinese` 只用於三種情況：`UICollectionReusableView`／cell 在 `configure` 前的暫存預設值、`BaseViewController` 在 `setInterfaceLocalization(_:)` 前的預設值，以及 `Error.errorMessage` 這個僅供 App Intents 與 developer log 使用的相容屬性。所有 initializer 與 function 參數都不得再有 `= .traditionalChinese` 預設值，確保漏傳時會編譯失敗。

### 7.2 資料流

```text
MainMemberSetting UIButton / UIMenu
    -> MainMemberSettingViewController
    -> MainMemberSettingViewModel 將 option raw value 映射為 AppInterfaceLanguage
    -> AppFlowRouting.applyInterfaceLanguage(...)
    -> AppComposition
        -> AppInterfaceLanguageStore.save(...)
        -> 更新 AppInterfaceLocalization value
        -> onInterfaceLanguageChanged(currentSession)
    -> SceneDelegate.replaceRoot(for:)
    -> MainTabBarController(.memberSetting)
    -> 各 factory 注入新的 AppInterfaceLocalization
```

### 7.3 責任邊界

#### View／ViewController

- 顯示 Menu 按鈕、目前選取值與勾選狀態。
- 將選取的 option ID 轉交 ViewModel／App flow。
- 不讀寫 `UserDefaults`。
- 不直接更新其他畫面文字。

#### ViewModel／Presentation Builder

- 使用注入的 `AppInterfaceLocalization` 產生本地 UI 文案。
- `MainMemberSettingViewModel` 由 `AppInterfaceLanguage.allCases` 建立 Menu options，並驗證 option raw value。
- 不 import UIKit。
- 不持有 concrete Store 或 `AppComposition`。

#### Router

- Alert、confirmation 與系統 presentation 的 App 自訂文案使用注入的 localization。
- 不決定語言、不持久化設定。

#### `AppComposition`

- 建立 `AppInterfaceLanguageStore`。
- 啟動時讀取介面語言。
- 建立 immutable `AppInterfaceLocalization` value。
- 注入各場景需要的 ViewModel、Builder、Router／Controller。
- 接收語言變更，儲存後通知 root replacement。

#### `SceneDelegate`

- 沿用現有 root replacement 責任。
- 語言切換時保留目前 Session 與 selected tab。
- 不處理字串查找或翻譯。

### 7.4 不建立的抽象

- 不建立 `LocalizationRepository`：沒有遠端或領域資料來源。
- 不建立 `ChangeLanguageUseCase`：流程只有同步偏好寫入與 App root 更新。
- 不建立 `LocalizationCoordinator`：root 仍由 `SceneDelegate` 管理。
- 不建立每個畫面一套 localizer protocol：共用 immutable value 即可。
- 不讓 View 自行從 singleton 查語言。

---

## 8. String Catalog 規格

### 8.1 資源

新增：

```text
MyTMDB_App/Localizable.xcstrings
```

Xcode project：

- `developmentRegion` 保持 `en`。
- `knownRegions` 保留 `en`、`zh-Hant`、`Base`，v1.4 新增 `ja`。
- String Catalog 必須加入 `MyTMDB_App` target。
- 不建立重複的 `.strings` 與 `.xcstrings` 來源。

v1.4 數量基線與完成目標：

| 指標 | v1.4 開始前 | v1.4 完成目標 |
|------|-------------|---------------|
| Catalog 全部 key | 475 | 476 |
| App 內本地化範圍 key | 448（`en`／`zh-Hant`） | 449（`en`／`zh-Hant`／`ja`） |
| 無 localization 的排除 key | 27 | 27 |

完成目標增加的一個 key 是 `main_member_setting.language.option.japanese`。27 個排除 key 不得為了讓統計歸零而納入日文翻譯；若未來要本地化 App Intents，需另立範圍與驗收。

### 8.2 Key 規則

使用穩定的語意 key，不直接以中文全文作為 key：

```text
main_tab.home.title
main_member_setting.navigation.title
main_member_setting.language.title
common.action.cancel
common.action.retry
common.state.loading
```

規則：

- 以 feature／畫面／元素／用途命名。
- 共用文案只有語意完全相同時才放 `common.*`。
- 不為了字面相同合併不同語意的 key。
- English default value 必須自然、可直接顯示。
- `zh-Hant` 必須提供完整翻譯，不依賴 fallback。
- `ja` 必須提供完整、自然的日文翻譯，不得依賴 English 或 `zh-Hant` fallback。
- 參數、plural 與句子順序交由 String Catalog 管理，不以字串相加拼句。
- 品牌、ID、數字與後端 value 使用 interpolation，不放進翻譯內容硬編碼。

v1.1 補充規則（皆經 `xcstringstool compile` 與執行期查表驗證）：

- 每個 key 都必須有明確的 `en` stringUnit。`extractionState: manual` 且缺 `en` 值的 key，會被編譯成 `en.lproj` 內 key = key，English 模式會直接顯示 `main_tab.home.title` 這類原始 key。
- `Int` 參數一律用 `%lld`，多參數一律用 positional specifier（`%1$@`、`%2$lld`），`en`、`zh-Hant` 與 `ja` 的 specifier 集合必須一致。
- 計數文案走 `BaseDisplayTextFormatter.CountUnit`，`en` 保留 `one`／`other` plural variation，`zh-Hant` 與 `ja` 可提供單一 stringUnit。
- 會隨媒體類型改變語法的句子（例如「沒有電影資料」、「搜尋影集」）不以 `%@` 插入 `displayName`，而是每種 `MediaKind` 一個 key，避免英文出現 `There are no Movie to show` 這類錯誤。
- 共用 key 合併了原本措辭不同的繁中文案時，統一採用「影集」；其餘 key 保留原繁中字面值。
- `STRING_CATALOG_GENERATE_SYMBOLS = YES` 會為所有 manual key 產生 `LocalizedStringResource` symbol；v1.4 已驗證 449 個 symbol 可產生，App 程式碼仍不使用這些 symbol。

### 8.3 注入規則

- `AppComposition` 建立的場景，以 initializer 注入 localization value。
- ViewModel／Presentation Builder 產生顯示文字後再交給 View。
- View 專屬且無狀態的固定文案，可由 Controller 建立 configuration 後傳入。
- 共用 Formatter 若產生使用者可見文字，需接收 localization／locale value。
- 不讓 Domain Entity、DTO、Repository 或 Network layer 依賴 String Catalog。

---

## 9. 預計檔案影響

### 9.1 v1.4 必須修改

- `Feature/Config/AppInterfaceLanguage.swift`：新增 `.japanese = "ja"`。
- `Main/MainMemberSetting/ViewModel/MainMemberSettingViewModel.swift`：補上日文 Menu option title 的 exhaustive `switch` case。
- `Feature/Formatter/BaseFormatter.swift`：日文與英文相同，對 TMDB 職稱／部門顯示正規化後的後端原值。
- `MyTMDB_App/Localizable.xcstrings`：既有 448 個範圍 key 補齊 `ja`，並新增三語完整的 `main_member_setting.language.option.japanese`。
- `MyTMDB_App.xcodeproj/project.pbxproj`：在 `knownRegions` 新增 `ja`。
- `Docs/SDD-InterfaceLanguage-In-App-Switch.md`：升級為 v1.4 三語規格並記錄驗證邊界。

### 9.2 沿用、不新增抽象

下列既有資料流與型別直接支援第三種語言，不需因 v1.4 修改責任或新增包裝層：

- `AppInterfaceLanguageStore` 以 raw value 儲存，既有 key `AppInterfaceLanguage.v1` 不需遷移或升版。
- `AppInterfaceLocalization` 依 `language.locale.language` 明確選擇 localization，沿用同一查表 API。
- `MainMemberSetting` 既有 `CaseIterable` Menu、單選勾選與 raw-value callback。
- `AppComposition` 儲存偏好、更新 immutable localization value，再由 `SceneDelegate` 重建 root。

不新增 Coordinator、UseCase、Repository、Service Locator、可變 Localization Manager、Notification、Combine publisher 或 feature flag。

### 9.3 明確不得因本功能修改

- `Feature/Config/AppLocalization.swift`
- 各 feature `Data/Repository/` 的 API query 行為
- `Feature/Data/Network/`
- DTO／Mapper 的後端欄位語意
- `Feature/AppIntents/`（App 外系統介面，另案處理）
- `Package.resolved`
- 第三方套件版本

---

## 10. 分階段實作計畫

v1.1–v1.3 已完成語言儲存、localization value 注入、雙語文案遷移與 Menu cutover。v1.4 不重做既有階段，以下工作在同一次 source delivery 完成；只有驗證狀態需依實際執行結果分開記錄。

### Phase J0 — 範圍與基線

1. 鎖定日文只處理第 6.1 節的 App 內本地文案。
2. 記錄 475 total／448 localized scope／27 unlocalized excluded 基線。
3. 明確排除 TMDB API／後端內容、App Intents／Shortcuts。
4. 鎖定不新增架構層、feature flag 或 storage migration。

完成條件：v1.4 SDD 規格、key count 與驗收責任一致。

### Phase J1 — 日文 String Catalog

1. 為既有 448 個 App 內範圍 key 補齊 `ja`。
2. 新增 `main_member_setting.language.option.japanese`，並提供 `en`／`zh-Hant`／`ja`。
3. 檢查所有 placeholder、positional specifier、換行與 English plural variation 未被破壞。
4. 日文使用自然 UI 措辭，不以繁中字面逐字轉換；品牌與 TMDB 原始內容保持不變。

完成條件：預期 476 total；449 個 App 內範圍 key 都有 `en`／`zh-Hant`／`ja`，27 個排除 key 維持原狀。

### Phase J2 — Source cutover

1. `AppInterfaceLanguage` 新增 `.japanese = "ja"`。
2. `MainMemberSettingViewModel` 的語言名稱 `switch` 新增 `.japanese`。
3. `BaseFormatter.CrewJobDisplayMapper` 的兩個語言 `switch` 讓 `.japanese` 與 `.english` 共用正規化後的 TMDB 原值。
4. Xcode project `knownRegions` 新增 `ja`。
5. 由既有 `CaseIterable` Menu 自動公開日文，不新增其他 UI 元件。

完成條件：所有 exhaustive `switch` 都覆蓋日文；Menu 可選「日本語」；偏好仍以既有 `AppInterfaceLanguage.v1` raw value 儲存。

### Phase J3 — Source 與靜態驗證

1. 驗證 catalog JSON、Xcode project plist 與 diff whitespace。
2. 編譯 catalog、產生 symbols，並比對 449 個 App 內 key 的三語完整性。
3. 比對 code key、catalog key 與 English default value，確認零缺漏、零多餘、零不一致。
4. 確認 `AppLocalization`、Repository 與 Network diff 為空。
5. 執行 Swift syntax parse；不把 syntax、catalog 或 source check 記成 Xcode Build。

完成條件：只依實際執行結果將個別靜態項目標記 Passed／Failed；未執行項目維持 `NotRun`。

### Phase J4 — 開發者自行驗收

1. 開發者在 Xcode 執行 Build。
2. 開發者依第 11 節操作 Simulator／實機。
3. 開發者確認繁中、英文、日文用字、截斷、格式、日期與 Accessibility。
4. 開發者回填 Passed／Failed 與裝置、OS、登入狀態。

未收到開發者明確驗收結果前，Developer Build、Runtime 與 Copy Review 必須保持 `NotRun`，不得由 source review 或靜態檢查推定通過。

---

## 11. 開發者自行驗收規格

### 11.1 驗收紀錄格式

| 欄位 | 內容 |
|------|------|
| 驗收者 | 開發者姓名／代號 |
| 日期 | `YYYY-MM-DD` |
| Xcode | 實際版本 |
| OS／裝置 | Simulator 或實機名稱與版本 |
| Build | Passed／Failed |
| 繁體中文 Runtime | Passed／Failed／NotRun |
| English Runtime | Passed／Failed／NotRun |
| 日本語 Runtime | Passed／Failed／NotRun |
| English Copy Review | Passed／Failed／NotRun |
| 日本語 Copy Review | Passed／Failed／NotRun |
| 備註 | 截圖、問題或例外 |

### 11.2 語言切換與持久化

- [ ] 初次啟動沒有語言設定時顯示繁體中文。
- [ ] 訪客模式可看到語言 Menu。
- [ ] 會員模式可看到語言 Menu。
- [ ] Menu 顯示目前介面語言。
- [ ] 目前語言選項顯示勾選。
- [ ] 可由 Menu 選擇繁體中文。
- [ ] 可由 Menu 選擇 English。
- [ ] 可由 Menu 選擇日本語。
- [ ] 重複選擇目前語言不會重建 root。
- [ ] 切換後立即回到設定分頁。
- [ ] 切換不會登出。
- [ ] 強制關閉再開啟後保留選擇。
- [ ] 登出後語言保留。
- [ ] 「清除所有本機資料」後語言保留。
- [ ] 快速重複點擊不會 crash、卡住或重複 present root。

### 11.3 繁體中文、英文與日文畫面矩陣

下列流程需各以繁體中文、英文與日文走查一次：

- [ ] 冷啟動與 Session validation error／retry。
- [ ] Login、Guest、Register。
- [ ] MainTabBar 五個分頁。
- [ ] Home section、查看更多、loading、empty、error。
- [ ] Search idle、typing、submitted、history、result、pagination。
- [ ] Movie／TV list、genre、sort、empty、error。
- [ ] Movie detail。
- [ ] TV detail。
- [ ] Season detail，包含第 0 季。
- [ ] Episode detail。
- [ ] Person detail。
- [ ] Review list、filter、pagination、review detail。
- [ ] MemberCenter overview 與 list。
- [ ] MainMemberSetting 所有 section、alert 與 destructive action confirmation。
- [ ] Rating、Genre 與其他 PageSheet。
- [ ] Trailer Player、WebView、Image Preview。

### 11.4 Copy 與版面

- [ ] 英文與日文不是逐字直譯，語意自然且操作動詞一致。
- [ ] Navigation title、button、cell、alert 無截斷或重疊。
- [ ] Dynamic Type 下主要操作仍可辨認。
- [ ] 日期、數量、季／集與評分句型符合當前介面語言。
- [ ] 空狀態、fallback 與錯誤訊息沒有殘留中文。
- [ ] 繁體中文模式沒有非預期英文 UI；品牌、API value 與後端內容除外。
- [ ] English 模式沒有非預期中文 UI；TMDB 後端內容除外。
- [ ] 日本語模式沒有非預期中文或英文 UI；品牌、API value、系統 UI 與 TMDB 後端內容除外。
- [ ] `API Data Language` value 可與介面語言不同，且沒有被 Menu 選擇改寫。

### 11.5 Accessibility

- [ ] VoiceOver 可聚焦語言 Menu 按鈕。
- [ ] Menu 按鈕 label 使用當前介面語言，value 讀出目前選取語言，且沒有額外自訂 hint。
- [ ] 切換後重新聚焦設定頁時不會讀出舊語言文案。
- [ ] MainTab、主要按鈕與既有 Accessibility 文案跟隨介面語言。

### 11.6 API 不變驗收

開發者可用既有設定頁 `API Data Language`、network log 或 request inspection 確認：

- [ ] 同一裝置切換 UI 前後，`language` query 不變。
- [ ] `region` 與 `timezone` query 不變。
- [ ] image／video language query 不變。
- [ ] TMDB 回傳的 title／overview 沒有因 UI 語言選擇被本機翻譯或覆寫。
- [ ] 因 root 重建發生的重新請求只屬畫面重新載入，query 語意沒有變更。

---

## 12. 靜態檢查、Build 與驗證邊界

### 12.1 Source 檢查

```bash
rg -n --glob '*.swift' '"[^"\n]*\p{Han}[^"\n]*"'

rg -n "AppleLanguages|method_exchangeImplementations|object_setClass" \
  MyTMDB_App Feature Main MainTabBar MainLogIn HomeSectionList Search \
  DetailContentList MovieDetail TVDetail SeasonDetail EpisodeDetail \
  PersonDetail ReviewList MemberCenter PageSheet

rg -n "import UIKit" \
  Main MainTabBar MainLogIn HomeSectionList Search DetailContentList \
  MovieDetail TVDetail SeasonDetail EpisodeDetail PersonDetail \
  ReviewList MemberCenter --glob '*ViewModel.swift'

git diff HEAD -- Feature/Config/AppLocalization.swift
git diff HEAD -- ':(glob)**/Data/Repository/*.swift'
git diff HEAD -- Feature/Data/Network
git diff --check
git diff --cached --check
plutil -lint MyTMDB_App.xcodeproj/project.pbxproj
python3 -m json.tool MyTMDB_App/Localizable.xcstrings > /dev/null
xcrun xcstringstool compile MyTMDB_App/Localizable.xcstrings -o "$TMPDIR/CineBaseStrings"
xcrun xcstringstool generate-symbols MyTMDB_App/Localizable.xcstrings -o "$TMPDIR/CineBaseSymbols" -l swift

rg -n --glob '*.swift' '^\s+(interface)?[lL]ocalization: AppInterfaceLocalization = ' . < /dev/null
rg -n --glob '*.swift' --glob '!Feature/AppIntents/**' 'error\.errorMessage([^(]|$)' . < /dev/null
```

`rg` 未指定路徑且 stdin 非 TTY 時會等待 stdin，因此上述兩行明確指定 `.` 並導入 `/dev/null`。第一行只比對參數預設值；reusable view 與 `BaseViewController` 的 stored property 預設值屬 7.1 允許範圍，不在比對內。

`plutil -lint` 只接受 property list，無法檢查 JSON 格式的 `.xcstrings`，v1.1 改用 `json.tool` 與 `xcstringstool`。

預期：

- 剩餘中文 string literal 已逐筆分類，不含遺漏的 App 內使用者文案（見 4.3 v1.1 表格）。
- 沒有 `AppleLanguages` hack、method swizzling 或 `Bundle.main` class replacement。
- ViewModel 沒有新增 UIKit import。
- `AppLocalization.swift`、各 Data Repository 與 `Feature/Data/Network` 無 diff。
- Xcode project 與 String Catalog 格式有效，catalog 可編譯且 symbol 可產生。
- 參數預設值不再出現 `= .traditionalChinese`。
- `error.errorMessage` 無參數版本只剩 App Intents 與 `AppLogger` developer log 使用。
- staged／unstaged diff 無 whitespace error。

另需以腳本比對：程式碼中每個 `string`／`formatted` 呼叫的 key 都存在於 catalog，catalog 沒有未使用的 key，且同一 key 在所有呼叫端的 English default 一致。v1.3 結果為 448 個 key，零缺漏、零多餘、零不一致。

v1.4 靜態驗證結果（2026-09-20）：

| 項目 | 結果 |
|------|------|
| Catalog 數量 | 476 total；449 個範圍 key 具備 `en`／`zh-Hant`／`ja`；27 個排除 key 維持無 localization |
| Placeholder | 449 個日文字串與 English 的 `%@`／`%lld`／positional specifier 集合一致 |
| Code／catalog key | 449 個範圍 key 均可在 Swift source 找到；零缺漏、零多餘；416 個直接呼叫的 English default 零不一致 |
| Catalog JSON／compile | `jq empty`、`xcstringstool compile`、`xcstringstool generate-symbols` 均 Passed |
| 編譯產物 | `en.lproj` 445 筆 strings + 4 筆 plural；`zh-Hant.lproj` 449 筆；`ja.lproj` 449 筆；generated symbols 449 筆 |
| Swift syntax | `AppInterfaceLanguage.swift`、`BaseFormatter.swift`、`MainMemberSettingViewModel.swift` parse Passed |
| Xcode project | `plutil -lint MyTMDB_App.xcodeproj/project.pbxproj` Passed |
| API 邊界 | `AppLocalization`、Repository、Network 無 diff |

另需人工檢查所有 Repository diff，確認 API query 未改變。靜態搜尋不能取代這項 diff review。

### 12.2 Build

本 SDD 建立階段不執行 build。依使用者指定，Build 由開發者自行執行與記錄。

建議命令：

```bash
xcodebuild \
  -project MyTMDB_App.xcodeproj \
  -scheme MyTMDB_App \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  -disableAutomaticPackageResolution \
  -derivedDataPath /tmp/MyTMDB_AppInterfaceLanguageDerivedData \
  build
```

不得因 build 失敗自行更新第三方套件、Resolve Package Versions、Reset Package Caches 或修改 `Package.resolved`。

v1.1 實作者編譯檢查歷史紀錄（不等於開發者 Build 驗收）：

| 項目 | 內容 |
|------|------|
| 日期 | 2026-09-19 |
| Xcode | 27.0（27A266a） |
| 指令 | 上方建議命令，改用 `-onlyUsePackageVersionsFromResolvedFile`，DerivedData 放在暫存目錄 |
| 結果 | `** BUILD SUCCEEDED **`；專案 Swift 原始碼零 warning，僅有 2 筆連結器 `ld` address warning（未另行比對 HEAD 是否原本就有） |
| 產物檢查 | `en.lproj` 含 445 筆 `.strings` 與 4 筆 plural `.stringsdict`，`zh-Hant.lproj` 含 449 筆 |
| `Package.resolved` | 未變動 |

v1.2 移除設定列副標題、v1.3 改為 Menu、v1.4 新增日文後皆未重新執行 Build；這些版本只完成第 12.1 節的 Swift 語法、String Catalog、project 與 diff 靜態檢查。Developer Build 仍由開發者自行執行。

### 12.3 Runtime 與 Copy Review

Runtime 與英文／日文 Copy Review 完全由開發者依第 11 節執行。

- Source Implementation Done 不等於 Runtime Passed。
- Static Verification Passed 不等於 Build Passed。
- Build Passed 不等於三種語言文案與畫面已驗收。
- 未收到開發者結果前，不得代為勾選第 11 節或將 SDD 標記 Complete。

---

## 13. 風險與處理

| 風險 | 影響 | 處理方式 |
|------|------|----------|
| UI 與 API 語言不同 | 英文／日文介面可能搭配中文片名／簡介 | 這是明確產品邊界；設定頁保留 API language value |
| 漏掉散落的 literal | English／日本語模式出現中文 | 機械掃描 + 第 11 節逐畫面走查 |
| 先公開語言 Menu | 使用者看到混合語言介面 | Menu 必須在三語 catalog 完成後才加入 `.japanese` case |
| 使用系統 locale 查字串 | App 內語言選擇不生效或重啟後不一致 | 每次查字串明確傳入 interface locale |
| 全域 mutable language | Swift 6 data race 或隱性依賴 | 使用 immutable localization value，由 Composition 注入 |
| Root rebuild 重置導航 | 使用者離開目前 detail stack | Menu 只在設定 root；切換後明確回設定分頁 |
| Root rebuild 重新打 API | 額外載入或畫面閃動 | 接受重新載入，但 query 語意不得改變 |
| String Catalog interpolation 錯誤 | 參數遺失、語序錯誤或 crash | 使用 catalog placeholder／plural，開發者三語走查 |
| 英文／日文長度改變造成截斷 | Button、Cell、Alert 版面退化 | Dynamic Type 與主要尺寸手動驗收 |
| Accessibility Menu 不可聚焦 | VoiceOver 無法選擇語言 | Cell 不聚焦，改由 Menu 按鈕提供 label、目前語言 value 與 UIKit Menu semantics |
| 語言模型綁定 Bool | 新增第三種語言需重寫 UI 與 mapping | `CaseIterable` 語言 case + raw value Menu option，不使用 `isEnglish` |
| 把 API 文案誤當 UI 文案 | 未授權的資料語言行為變更 | 依第 6 節分類；Repository 與 AppLocalization diff review |
| 預設參數掩蓋漏傳 | English 模式局部殘留中文 | 移除所有 `= .traditionalChinese` 參數預設值，由編譯器強制傳遞 |
| catalog 缺 `en` 值 | English 模式顯示原始 key | 每個 key 皆寫入 `en` stringUnit，並以腳本比對 code 與 catalog |

### 13.1 已知限制（v1.1）

以下行為不屬於本 SDD 範圍，開發者驗收時請勿視為缺陷：

- **UIKit 與系統提供的文字跟隨 iOS 系統語言**，不跟隨 App 內語言選擇。例如 `UISearchController` 的「取消」、預設返回按鈕、分享面板、`SFSafariViewController`、WebKit 錯誤的 `localizedDescription`。App 新增 `zh-Hant.lproj` 後，繁中裝置上的這些系統文字會從原本的英文變為中文。
- **App Intents 與 Shortcuts** 維持原本中文，依 3.2 另案處理。
- **TMDB 職稱／部門**：繁中模式沿用 `BaseFormatter.CrewJobDisplayMapper` 對照表；English／日本語模式直接顯示 TMDB 原始英文值（例如 `Director`、`Acting`），符合後端內容不在本次翻譯範圍的邊界。
- **Developer log**：`AuthFlowHandler` 與 `MainTabBarAvatarImageProvider` 的 `AppLogger` 訊息仍使用中文 `errorMessage`，屬 developer-only。
- **繁中措辭統一**：搜尋篩選的「劇集」、以及開啟影集詳情的無障礙提示，改為共用 key 的「影集」。登入頁分頁提示改用 `ListFormatter`，繁中由「登入、訪客、註冊」變為「登入、訪客和註冊」。
- **切換語言會重置導航堆疊**：維持 5.2 設計，root 重建後停在設定分頁。

---

## 14. 回退策略

### 日文 cutover 尚未完成

- 不公開語言 Menu。
- 新增的 String Catalog 與 localization value 可保留，不影響繁體中文既有流程。
- 任一 feature 遷移有問題時，可只回退該 feature 的注入與字串呼叫。

### 日文 cutover 後

- 若只有日文內容有問題，優先移除 `.japanese` case 以隱藏日文選項；保留已完成的 catalog 文案供修復版本使用。
- 若整體介面語言功能有問題，再隱藏／移除 `.appInterfaceLanguage` row，暫時固定 `.traditionalChinese`。
- 不刪除使用者已儲存的 `AppInterfaceLanguage.v1`，避免修復版本重新開放時遺失選擇。
- 不以修改 `AppLocalization` 或 API query 作為回退手段。
- 若 root replacement 有問題，回退 app-flow callback，不回退已完成的 String Catalog 文案。

---

## 15. 完成定義

只有同時符合下列條件，才能將本 SDD 標記為 Complete：

- Phase 1–5 與 Phase J0–J3 source implementation 完成。
- String Catalog 的 449 個範圍 key 包含完整 `en`、`zh-Hant` 與 `ja`。
- App 內本地使用者可見文案已依第 6 節完成分類與遷移。
- 語言 Menu 在訪客與會員模式皆正確顯示與運作。
- 語言偏好可持久化，且登出／清除帳號資料不會重置。
- `AppLocalization` 與所有 Repository API query 行為不變。
- Source／String Catalog／project 靜態檢查通過。
- Build 結果由開發者回填為 Passed。
- 第 11 節繁體中文、English、日本語、Copy、Accessibility、API 不變矩陣由開發者回填為 Passed。
- 沒有以 source review、static check 或 build 結果冒充 Runtime／Copy 驗收。

---

## 16. 實作狀態

截至 2026-09-26（v1.4）：

| 項目 | 狀態 | 證據／限制 |
|------|------|------------|
| Design | Ready | v1.4 三語範圍、API 邊界與驗收責任已鎖定 |
| Phase 0 | Done | 範圍、API 邊界與開發者驗收責任已定義 |
| Phase 1 基礎 | Done | `AppInterfaceLanguage`、Store、`AppInterfaceLocalization`、catalog、`zh-Hant` region、root 重建 callback |
| Phase 2 Shell／登入／共用元件 | Done | MainTab、Loading、ErrorMessage、BaseRouter、Login、Player、WebView、ImagePreview、Session alert |
| Phase 3 Main 與列表 | Done | Home、HomeSectionList、MainSearch、SearchResults、MainMediaList |
| Phase 4 詳情／會員／PageSheet | Done | Movie、TV、Season、Episode、Person、Review、ReviewDetail、MemberCenter、Settings、Genre、Rating、DetailContentList |
| Phase 5 Menu cutover | Done | 偏好設定第一列 Menu、單選勾選、Accessibility、寫入偏好、重建 root 回設定分頁 |
| Phase J0–J2 日文 source | Done | `.japanese`、Menu option、formatter boundary、`ja` region 與三語 catalog 已完成 |
| String Catalog | Done | 449 個範圍 key 的 `en`／`zh-Hant`／`ja` 完整；4 個 English plural；27 個排除 key 維持原狀 |
| Static Verification | Passed | v1.4 已通過第 12.1 節 JSON、catalog compile／symbols、placeholder、key、Swift parse、project 與 diff 檢查 |
| 實作者編譯檢查 | Passed | v1.1 歷史紀錄見 12.2；v1.4 由 2026-09-26 全專案 Build 涵蓋 |
| Xcode Build | Passed | 2026-09-26 iOS Simulator Debug build 通過（含 String Catalog 編譯） |
| Runtime — 繁體中文 | Partial | 2026-09-26 走查時首頁、詳情頁、公司頁、設定頁以繁體中文正常顯示；正式逐頁驗收仍待開發者 |
| Runtime — English | NotRun | 等待開發者驗收 |
| English Copy Review | NotRun | 等待開發者驗收 |
| Runtime — 日本語 | NotRun | 等待開發者驗收 |
| 日本語 Copy Review | NotRun | 等待開發者驗收 |
| API unchanged review | Source Passed／Runtime NotRun | `AppLocalization`、Repository、Network 無 diff；request 比對等待開發者 |

### 16.1 v1.1 進度盤點與修正

v1.1 接手時，工作區已有 Phase 1 與部分 Phase 2–4、5 的未提交修改（81 個修改檔、4 個新檔），但有以下問題，已全部修正：

| 問題 | 影響 | 修正 |
|------|------|------|
| `String(localized:…locale:)` 不依 `locale` 選語系 | Switch 對所有 catalog 文案無效 | 改用 `Bundle.localizedString(forKey:value:table:localizations:)`，見 7.1 |
| catalog 77 個 key 皆無 `en` 值 | English 模式顯示原始 key | 重建 catalog，449 個 key 皆有 `en`／`zh-Hant` |
| 程式碼使用的 183 個 key 未寫入 catalog | 繁中模式顯示英文 default | 補齊繁中，並以原始中文字面值為準 |
| 47 個檔案仍有中文 literal | English 模式殘留中文 | 完成 Season／Episode／Person／Review／MemberCenter／PageSheet／共用元件遷移 |
| 無法編譯 | `DetailRouter` 呼叫不存在的 initializer、數處缺 `return` 或引用未宣告屬性 | 補齊 initializer 與屬性，編譯通過 |
| 71 個 `= .traditionalChinese` 參數預設值 | 首頁海報、詳情頁、登入錯誤等漏傳仍顯示中文 | 移除預設值，由編譯器找出並補齊所有呼叫端 |
| English 以 `%@` 插入媒體名稱拼句 | `There are no Movie to show right now.` 等錯誤英文 | 改為每種 `MediaKind` 一個 key |
| 計數固定使用複數單位 | `1 episodes` | `CountUnit` 搭配 English plural variation |
| Switch 在遷移完成前已公開 | 違反 Phase 5 cutover 順序 | 遷移已全部完成，不再是風險 |

---

## 17. 修訂紀錄

| 版本 | 日期 | 內容 |
|------|------|------|
| 1.0 Draft | 2026-09-19 | 建立 App 內繁體中文／英文 Switch SDD；範圍限定本地寫死的 UI、格式化與 Accessibility 文案；明確排除 TMDB API localization 與後端內容；Build、Runtime、英文 Copy 由開發者自行驗收 |
| 1.1 | 2026-09-19 | 完成 Phase 1–5 source；查表改用 `Bundle.localizedString(…localizations:)`，`defaultValue` 改為 `String`；catalog 補齊 449 個 key 的 `en`／`zh-Hant` 與 English plural；移除 `.traditionalChinese` 參數預設值；媒體類型文案改為分 key；新增 4.3 殘留分類、8.2 補充規則、12.1 catalog 檢查、12.2 實作者編譯檢查、13.1 已知限制、16.1 盤點；開發者 Build、Runtime、Copy Review 仍為 NotRun |
| 1.2 | 2026-09-19 | 設定列文案簡化為「語言偏好」／`Language Preference`，移除副標題與自訂 Switch hint；String Catalog 調整為 448 個 key；Developer Build、Runtime、Copy Review 仍為 NotRun |
| 1.3 | 2026-09-19 | 語言控制由二元 Switch 改為 `UIButton` + 單選 `UIMenu`；`AppInterfaceLanguage` 改採 `CaseIterable`，Menu option 使用 raw value；移除 Bool mapping，保留 448 個雙語 key；Developer Build、Runtime、Copy Review 仍為 NotRun |
| 1.4 | 2026-09-20 | 新增日本語介面；449 個範圍 key 完成 `en`／`zh-Hant`／`ja`；新增 `.japanese`、Menu option、`ja` region，並讓日文維持 TMDB 後端職稱原值；Static Verification Passed；Developer Build、Runtime、Copy Review 仍為 NotRun |
| 1.5 | 2026-09-26 | 對齊現況：Xcode Build 更新為 Passed；繁體中文 Runtime 更新為 Partial；metadata 狀態改為規格／實作／驗證三欄 |
