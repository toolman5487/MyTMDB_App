# SDD: CineBase 區段標題 Header 共用基底

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | Swift 6.0，`SWIFT_STRICT_CONCURRENCY = complete` |
| 既有架構 | UIKit + MVVM + Clean Architecture + Router + `AppComposition` |
| 功能範圍 | 首頁、會員中心，以及 Movie／TV／Season／Episode／Person 詳情頁的區段標題 header |
| 狀態 | Implementation Done；Build Passed；Runtime Passed（iPhone、訪客模式）；會員中心、VoiceOver、iPad NotRun |
| 日期 | 2026-09-18 |

---

## 1. 目的

本文件定義區段標題 header 的共用基底 `BaseSectionHeaderView`。首頁、會員中心與五個詳情頁的區段標題 header 原本各自實作「標題 + disclosure 圖示 + 點擊 + 無障礙 + reuse 重置」，本次將共用行為集中到同一個 base class，並統一 disclosure 圖示的外觀。

本設計需符合下列原則：

- 只收斂跨 feature 共用的 UI 行為；各 feature 的 VoiceOver 文案與版面差異留在子類別，不把 feature-only 邏輯放進 base class。
- 沿用專案既有 base class 慣例：`BaseCollectionViewCell` 的 template method，以及 `BaseFilterHeaderView` → `BaseShowAllFilterHeaderView` 的繼承方式。
- 除第 4 節明列的 disclosure 外觀調整外，不改變 header 的高度、間距、點擊目的地與 VoiceOver 文案。
- 不新增 protocol、factory 或只為統一名稱而存在的抽象。

本文件遵循：

- `SDD-Clean-Architecture-Migration.md` 的分層原則；本次只涉及 Presentation 層的 View。
- `SDD-Unified-Interface-Naming.md` 的 Swift API 與 callback 命名規則。

---

## 2. 目標與非目標

### 2.1 目標

- 使用 disclosure 圖示的三個區段 header 皆繼承 `BaseSectionHeaderView`。
- Disclosure 的 SF Symbol、顏色與尺寸只在 base 定義一次。
- Disclosure 由 `chevron.right.2` 改為 `chevron.right`，顏色改為 `ThemeColor.textSecondary`；標題文字維持 `ThemeColor.highlight`。
- 標題與點擊 handler 在同一次 `configure` 設定，由 handler 是否存在決定 disclosure、可點擊狀態與 `.button` trait。
- 移除改用 base 後不再使用的 `MainHomeSectionTitleAttributedStringFactory`。

### 2.2 非目標

- 不調整 header 高度（詳情頁 28、首頁與會員中心 32）與左右間距（16）。
- 不統一各 feature 的 VoiceOver 文案；詳情頁「區段」、首頁「分類」維持原樣。
- 不修改 `DetailBaseViewController.dequeueDetailSectionHeader(at:title:onTap:)` 的對外介面；五個詳情頁 Controller 不變。
- 不處理會員中心沿用首頁 `MainHomeSectionHeaderView` 的跨 feature 依賴（見第 11 節）。
- 不改動未使用 disclosure 的 header：`MainMemberSettingSectionHeaderView`、各 Hero header、`BaseFilterHeaderView` 系列。
- 不新增第三方套件、SPM package、Xcode target 或測試 target。

---

## 3. 現況盤點

### 3.1 使用 `chevron.right.2` 的 header

| Header | 位置 | 使用端 | Disclosure | 點擊範圍 | VoiceOver 文案 |
|--------|------|--------|------------|----------|----------------|
| `DetailSectionHeaderView` | `Feature/Base/DetailBase/View/` | Movie、TV、Season、Episode、Person 詳情頁（經 `DetailBaseViewController`） | 可點時才顯示 | 整個 header | 「X 區段」；可點時 hint「點兩下查看完整列表」 |
| `MainHomeSectionHeaderView` | `Main/MainHome/View/Header/Section/` | `MainHomeViewController`、`MemberCenterViewController` | 一律顯示 | 整個 header | 「X 分類」、value「可查看更多」、hint「點兩下查看X完整列表」 |
| `MainHomeFeaturedHeaderView` | `Main/MainHome/View/Header/Carousel/` | `MainHomeViewController` 第一個區段 | 一律顯示 | 僅標題列；輪播自行處理點擊 | 同 `MainHomeSectionHeaderView`，套用在標題列 |

### 3.2 重複實作

三個 header 各自實作下列相同邏輯：

- 以 `UIImage(systemName:withConfiguration:)` 建立 disclosure，設定為 `SymbolConfiguration(font:scale: .small)`。
- 以 `AppFactory.Label.sectionTitle` 建立標題，並以 `BaseDisplayTextFormatter.titleAttributedText` 組字；首頁另經 `MainHomeSectionTitleAttributedStringFactory` 純轉呼叫。
- `UITapGestureRecognizer` 與 closure 轉發。
- 無障礙套用與重置：標題空白時清除並移除 `.button`。
- `prepareForReuse` 清除標題、closure 與無障礙。
- 兩個 initializer 的 setup 樣板；`MainHomeSectionHeaderView` 的兩個 init 內容逐行重複。

### 3.3 點擊 API 不一致

| Header | 改動前 API |
|--------|------------|
| `DetailSectionHeaderView` | `configure(title:onTap:)` |
| `MainHomeSectionHeaderView` | `configure(title:)` 之後再指定 `onTitleTapped` |
| `MainHomeFeaturedHeaderView` | `configure(title:carouselItems:)` 之後再指定 `onTitleTapped`、`onCarouselSelected` |

「先 configure、後指定 closure」使 header 在 configure 當下無法得知是否可點，因此首頁只能一律顯示 disclosure。

---

## 4. 視覺規格

| 項目 | 規格 |
|------|------|
| 標題字型 | `AppFactory.Label.sectionTitle`（`.title3`） |
| 標題顏色 | `ThemeColor.highlight`（不變） |
| Disclosure 圖示 | SF Symbol `chevron.right`（原 `chevron.right.2`） |
| Disclosure 顏色 | `ThemeColor.textSecondary`，即 `.secondaryLabel`（原與標題同色） |
| Disclosure 尺寸 | `UIImage.SymbolConfiguration(font: 標題字型, scale: .small)`，以 text attachment 接在標題後方，垂直置中於 cap height |
| 顯示條件 | 有點擊 handler 時才顯示 |
| 左右間距 | 16；詳情頁取 `DetailLayoutMetrics.horizontalContentInset` |
| 高度 | 由使用端決定：詳情頁 28、首頁與會員中心 32 |

單一 `chevron.right` 搭配次要色是 iOS 常見的 disclosure 表現，可與品牌色標題區隔，避免圖示搶走標題的視覺重量。此調整由 base 一次套用到所有區段 header。

---

## 5. 架構設計

### 5.1 繼承結構

```text
UICollectionReusableView
└── BaseSectionHeaderView               Feature/Base/SectionHeader/
    ├── DetailSectionHeaderView         Feature/Base/DetailBase/View/
    └── MainHomeSectionHeaderView       Main/MainHome/View/Header/Section/
        └── MainHomeFeaturedHeaderView  Main/MainHome/View/Header/Carousel/
```

`MainHomeFeaturedHeaderView` 繼承 `MainHomeSectionHeaderView`，而非直接繼承 base：輪播 header 的標題列與首頁區段 header 相同（高度 `standardHeight`、VoiceOver 文案），差異只在上方多了輪播。繼承後，文案與高度只定義一次。

### 5.2 `BaseSectionHeaderView` 職責

負責：

- 建立標題列 `titleRowView` 與內部標題 label。
- 依 handler 組出標題 attributed text 與 disclosure。
- 點擊手勢、可點擊狀態與 `.button` trait。
- 無障礙套用與重置流程。
- `prepareForReuse` 重置標題、handler 與無障礙。
- 提供 `reuseIdentifier`。

不負責：

- 各 feature 的 VoiceOver 文案。
- 標題列以外的內容，例如輪播。
- Header 高度，由各使用端的 layout 決定。

### 5.3 介面

```swift
@MainActor
class BaseSectionHeaderView: UICollectionReusableView {

    class var reuseIdentifier: String { get }

    var titleHorizontalInset: CGFloat { get }

    let titleRowView: UIView

    func configureView()
    func setupHierarchy()
    func setupConstraints()
    func resetForReuse()
    func titleAccessibilityText(for title: String, isTappable: Bool) -> AccessibilityText

    func configure(title: String?, onTitleTap: (() -> Void)? = nil)
}
```

| 成員 | 用途 | 預設 |
|------|------|------|
| `reuseIdentifier` | 依實際型別回傳名稱 | `String(describing: self)` |
| `titleHorizontalInset` | 標題左右間距的 override point | `16` |
| `titleRowView` | 標題列容器，點擊與無障礙掛在此 view；子類別決定擺放位置 | 填滿 header |
| `configureView`／`setupHierarchy`／`setupConstraints`／`resetForReuse` | Template methods，與 `BaseCollectionViewCell` 相同 | 透明背景；`titleRowView` 填滿 header |
| `titleAccessibilityText(for:isTappable:)` | 各 feature 的 VoiceOver 文案 | `AccessibilityText(label: title)` |
| `configure(title:onTitleTap:)` | 設定標題與點擊 handler | — |

標題 label、點擊手勢、handler 與 disclosure 圖片的建立皆為 `private`，子類別不需要也無法存取。

### 5.4 `reuseIdentifier` 改為 `class var`

改動前各 header 以 `static let reuseIdentifier = String(describing: X.self)` 宣告。`MainHomeFeaturedHeaderView` 改為繼承 `MainHomeSectionHeaderView` 後，子類別無法重新宣告同名的 `static let`；若沿用，子類別會繼承父類別的值，兩種 header 以同一個 identifier 註冊，後註冊者覆蓋前者，一般區段會 dequeue 到輪播 header。

因此 base 以 `class var reuseIdentifier: String { String(describing: self) }` 依實際型別回傳名稱，寫法沿用 `BaseFilterHeaderCollectionViewCell`。三個 header 的 identifier 字串與改動前相同，註冊與 dequeue 的呼叫端不需修改。

### 5.5 點擊與 disclosure 規則

`configure(title:onTitleTap:)` 以 handler 是否為 `nil` 作為唯一判斷來源：

| `onTitleTap` | Disclosure | `titleRowView.isUserInteractionEnabled` | `.button` trait |
|--------------|------------|------------------------------------------|-----------------|
| 非 `nil` | 顯示 | `true` | 加入 |
| `nil` | 不顯示 | `false` | 移除 |

首頁與會員中心的呼叫端一律傳入 handler，因此 disclosure 仍一律顯示；外觀依第 4 節更新。

### 5.6 標題列與無障礙

點擊與無障礙掛在 `titleRowView`，不掛在 header 本身：

- 一般 header 的 `titleRowView` 填滿整個 header，VoiceOver 讀到的 label、value、hint 與 traits 與改動前相同。
- 輪播 header 若將 header 本身設為 accessibility element，會遮蔽輪播內的元素；原實作即將無障礙套在標題列，base 統一採用此做法。
- 標題 label 設為 `isAccessibilityElement = false`，由 `titleRowView` 代表整列。

### 5.7 子類別

| 子類別 | Override 與新增 |
|--------|-----------------|
| `DetailSectionHeaderView` | `titleHorizontalInset` 回傳 `DetailLayoutMetrics.horizontalContentInset`；文案「X 區段」，可點時 hint「點兩下查看完整列表」 |
| `MainHomeSectionHeaderView` | 改為可繼承的 `class`；保留 `standardHeight = 32`；文案「X 分類」，可點時 value「可查看更多」、hint「點兩下查看X完整列表」 |
| `MainHomeFeaturedHeaderView` | `setupHierarchy`／`setupConstraints` 將 `titleRowView` 放在輪播下方，高度 `standardHeight`；`resetForReuse` 清除輪播與 `onCarouselSelected`；新增 `configure(title:carouselItems:onTitleTap:)` |

`MainHomeFeaturedHeaderView` 覆寫 `setupHierarchy`／`setupConstraints` 時不呼叫 super，因為 base 預設會將 `titleRowView` 直接加到 header 並填滿；做法與 `BaseShowAllFilterHeaderView.setupConstraints` 相同。標題列內部的 label 與手勢由 base 的私有方法在 init 時建立，不受子類別覆寫影響。

`MainHomeSectionHeaderView` 的 value 與 hint 改為「可點時才提供」。目前呼叫端一律傳入 handler，實際 VoiceOver 輸出不變。

### 5.8 `BaseDisplayTextFormatter`

`titleAttributedText(title:trailingImage:font:textColor:)` 原本以 `textColor` 為 trailing image 著色，無法讓 disclosure 與標題不同色。新增尾端參數：

```swift
@MainActor
static func titleAttributedText(
    title: String?,
    trailingImage: UIImage? = nil,
    font: UIFont,
    textColor: UIColor = ThemeColor.highlight,
    trailingImageColor: UIColor? = nil
) -> NSAttributedString?
```

`trailingImageColor` 為 `nil` 時沿用 `textColor`。其他呼叫端（`DetailHeroHeaderView`、`SeasonDetailHeroHeaderView`、`EpisodeDetailHeroHeaderView`、`PersonDetailHeroHeaderView`）使用不含 trailing image 的 `titleAttributedText(_:font:)`，行為不變。

---

## 6. 呼叫端 API

Handler 改由 `configure` 注入，並使用 weak capture：

```swift
headerView.configure(title: section.title) { [weak self] in
    self?.showSectionList(for: section.category)
}
```

| 呼叫端 | 改動前 | 改動後 |
|--------|--------|--------|
| `MainHomeViewController` 一般區段 | `configure(title:)` + `onTitleTapped` | `configure(title:onTitleTap:)` |
| `MainHomeViewController` 輪播 | `configure(title:carouselItems:)` + `onTitleTapped` | `configure(title:carouselItems:onTitleTap:)`；`onCarouselSelected` 不變 |
| `MemberCenterViewController` | `configure(title:)` + `onTitleTapped` | `configure(title:onTitleTap:)` |
| `DetailBaseViewController` | `configure(title:onTap:)` | `configure(title:onTitleTap:)`；`dequeueDetailSectionHeader` 介面不變 |

`onTitleTapped` 屬性移除。輪播 header 的 `configure` 不提供 `carouselItems` 預設值，避免與 base 的 `configure(title:onTitleTap:)` 產生 overload 歧義。

---

## 7. 檔案影響範圍

| 檔案 | 變更 |
|------|------|
| `Feature/Base/SectionHeader/BaseSectionHeaderView.swift` | 新增 |
| `Feature/Base/DetailBase/View/DetailSectionHeaderView.swift` | 改繼承 base，只保留 override |
| `Main/MainHome/View/Header/Section/MainHomeSectionHeaderView.swift` | 改繼承 base，改為可繼承的 `class` |
| `Main/MainHome/View/Header/Carousel/MainHomeFeaturedHeaderView.swift` | 改繼承 `MainHomeSectionHeaderView`，只保留輪播相關實作 |
| `Main/MainHome/View/Factory/MainHomeSectionTitleAttributedStringFactory.swift` | 刪除，連同空的 `Factory` 資料夾 |
| `Feature/Formatter/BaseDisplayTextFormatter.swift` | `titleAttributedText` 新增 `trailingImageColor` |
| `Feature/Base/DetailBase/Controller/DetailBaseViewController.swift` | 參數標籤改為 `onTitleTap` |
| `Main/MainHome/Controller/MainHomeViewController.swift` | 改用新的 `configure` |
| `MemberCenter/Controller/MemberCenterViewController.swift` | 改用新的 `configure` |
| `MyTMDB_App.xcodeproj/project.pbxproj` | 新增 `Feature/Base/SectionHeader` group 與 target membership；移除 factory 與 `Factory` group |

原三個 header 與 factory 共 478 行，改為 base 與三個子類別共 349 行；disclosure 只在 `BaseSectionHeaderView` 定義一次。

---

## 8. 驗收規格

### 8.1 UI

| Case | 預期結果 |
|------|----------|
| 首頁一般區段 | 標題為 highlight 色，後接次要色 `chevron.right`；點擊標題進入分類列表 |
| 首頁輪播 header | 標題列同上；點擊標題列進入分類列表；點擊輪播項目進入詳情頁 |
| 詳情頁可點區段（主要演員、幕後人員、劇照等） | 顯示次要色 `chevron.right`；點擊進入完整列表 |
| 詳情頁不可點區段（電影資訊等） | 無 disclosure；點擊無反應 |
| Header reuse | 首頁捲到底後點擊重用的 header，標題、disclosure 與目的地皆對應正確區段 |
| 會員中心內容區段 | 同首頁一般區段 |

### 8.2 VoiceOver

| Header | 狀態 | Label | Value | Hint | Traits |
|--------|------|-------|-------|------|--------|
| 詳情頁 | 可點 | 「X 區段」 | — | 「點兩下查看完整列表」 | `.button` |
| 詳情頁 | 不可點 | 「X 區段」 | — | — | — |
| 首頁、會員中心、輪播標題列 | 可點 | 「X 分類」 | 「可查看更多」 | 「點兩下查看X完整列表」 | `.button` |
| 任一 | 標題空白 | 不是 accessibility element | — | — | — |

---

## 9. 靜態檢查與驗證紀錄

### 9.1 Source 檢查

```bash
rg -n "chevron\.right\.2" --glob '*.swift' .

rg -n "onTitleTapped|MainHomeSectionTitleAttributedStringFactory" --glob '*.swift' .

rg -n "disclosureSymbolName" --glob '*.swift' .

git diff --check
```

預期：

- 前兩項無輸出。
- `disclosureSymbolName` 只出現在 `BaseSectionHeaderView.swift`。
- diff 無 whitespace error。

結果：符合預期。

### 9.2 Build

```bash
xcodebuild \
  -project MyTMDB_App.xcodeproj \
  -scheme MyTMDB_App \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/MyTMDB_AppSectionHeaderDerivedData \
  build
```

結果：BUILD SUCCEEDED，0 error、0 warning；改動前以相同命令建立的基準同為 0 warning。

### 9.3 Runtime

環境：iPhone 17 Pro Simulator（iOS 26.5），訪客 session。

- 8.1 除「會員中心內容區段」外全部通過。
- 會員中心內容區段需 TMDB 帳號登入才會出現，未驗證；其使用與首頁相同的 `MainHomeSectionHeaderView`，呼叫端改法相同。
- 8.2 未以實際 VoiceOver 操作驗證。
- iPad 未驗證；輪播 header 的 iPad 寬度上限（720）程式碼未變更。

---

## 10. 風險與處理

| 風險 | 影響 | 處理方式 |
|------|------|----------|
| 子類別繼承父類別的 `static let reuseIdentifier` | 兩種 header 共用 identifier，dequeue 到錯誤型別 | Base 改用 `class var`（5.4） |
| 子類別覆寫 `setupHierarchy` 未擺放 `titleRowView` | 標題列不顯示 | 標題列內部由 base 私有方法建立；子類別只負責擺放 `titleRowView` |
| Header 本身成為 accessibility element | 輪播內元素無法被 VoiceOver 存取 | 無障礙掛在 `titleRowView`（5.6） |
| Feature 文案收進 base | Base 需要知道各 feature 語意 | 文案經 `titleAccessibilityText(for:isTappable:)` 由子類別提供 |
| `onTitleTap` 強參考 Controller | 循環參考 | 呼叫端使用 `[weak self]`；reuse 時 base 清除 handler |
| Disclosure 改色影響其他 trailing image 呼叫端 | 其他標題的圖示顏色改變 | 新參數預設 `nil`，沿用 `textColor` |
| 誤動 `project.pbxproj` | Target membership 遺失 | 以腳本逐項比對替換，並以 `plutil -lint` 與 Xcode Build 驗證 |

---

## 11. 後續事項

- 會員中心沿用首頁的 `MainHomeSectionHeaderView`，屬跨 feature 依賴。可另建 `MemberCenterSectionHeaderView: BaseSectionHeaderView`，或將共用文案的 header 移至 `Feature/`。本次不處理。
- `MainHomeViewController.Layout.headerHeight`、`MemberCenterViewController.Layout.sectionHeaderHeight` 與 `MainHomeSectionHeaderView.standardHeight` 皆為 32，屬重複定義，可另案收斂。

---

## 12. 實作狀態

截至 2026-09-18：

- Design：Ready。
- Source Implementation：Done（依第 7 節檔案範圍）。
- Static Verification：Passed（9.1）。
- Xcode Build：Passed（9.2）。
- Runtime／UI：Passed（9.3，iPhone 訪客模式）。
- 會員中心 Runtime：NotRun。
- VoiceOver：NotRun。
- iPad：NotRun。

---

## 13. 參考資料

- [Apple Developer Documentation — UICollectionReusableView](https://developer.apple.com/documentation/uikit/uicollectionreusableview)
- [Apple Developer Documentation — UIColor.secondaryLabel](https://developer.apple.com/documentation/uikit/uicolor/secondarylabel)
- [Apple Human Interface Guidelines — SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)

---

## 14. 修訂紀錄

| 版本 | 日期 | 內容 |
|------|------|------|
| 1.0 | 2026-09-18 | 建立 `BaseSectionHeaderView`，三個區段 header 改為繼承；disclosure 改為次要色 `chevron.right`；Build 與 iPhone 訪客模式 Runtime 通過，會員中心、VoiceOver、iPad NotRun |
