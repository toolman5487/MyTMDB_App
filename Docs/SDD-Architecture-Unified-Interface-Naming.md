# SDD: CineBase 介面與命名統一

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| 文件 ID | `SDD-ARCHITECTURE-UNIFIED-INTERFACE-NAMING` |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | Swift 6.0，`SWIFT_STRICT_CONCURRENCY = complete` |
| 既有架構 | UIKit + MVVM + Clean Architecture + Router + `AppComposition` |
| 目標 | 統一 Domain、Data、Presentation、App 各層的介面角色、命名與呼叫形式 |
| 規格狀態 | `Accepted` |
| 實作狀態 | `Done`（統一命名與介面已套用） |
| 驗證狀態 | Build `Passed`（2026-09-26，iOS Simulator Debug）；Runtime `Partial`（主要流程走查正常，見 11.2） |
| 最後更新 | 2026-09-26 |

---

## 1. 目的

本文件定義 CineBase 各層公開介面的統一規則，解決下列問題：

- 縮寫大小寫混用，例如 `sessionId` / `sessionID`、`favoriteTv` / `favoriteTV`。
- ViewModel 同時存在 callback binding、`@Observable`、Controller 主動讀取等多種輸出方式。
- 相同用途的方法使用 `loadHome()`、`loadReviews()`、`loadInitial()`、`loadInitialContent()` 等不同名稱。
- Scene Builder 大多回傳 `UIViewController`，但個別方法回傳具體 ViewController。
- Router 方法在 `showDetail(for:)`、`showDetail(itemID:)`、`showMovieDetail(movieID:)` 之間缺少明確選用規則。
- Repository、UseCase、Storage、Factory 等角色雖已有慣例，但尚未集中成單一規格。

本文件只定義介面與命名遷移，不在同一階段改變業務規則、畫面、API request、資料格式或導航行為。

本文件是 `SDD-CleanArchitecture-Migration.md` 的補充規格：

- 分層、依賴方向與 UseCase 建立判準，以 Clean Architecture SDD 為準。
- Swift symbol、方法、參數與 protocol 角色命名，以本文件為準。
- 若兩份文件衝突，實作前必須先修訂文件，不得由實作者自行猜測。

---

## 2. 目標與非目標

### 2.1 目標

- 讓型別名稱可直接判斷角色與所屬邊界。
- 讓同類方法具有一致的動詞、參數標籤與回傳形式。
- 統一 Swift 常見縮寫的大小寫。
- 讓有狀態的 ViewModel 使用單一輸出契約。
- 讓 Scene Builder 隱藏具體 ViewController 型別。
- 保留既有 Clean Architecture 依賴方向。
- 以可分批、可 review、可回退的方式完成遷移。

### 2.2 非目標

- 不新增 Coordinator。
- 不新增泛型 DI container、Service Locator 或 `AppComposition.shared`。
- 不建立 `BaseViewModel`、`ViewModelProtocol` 或只為統一名稱而存在的空抽象。
- 不將 UIKit 改寫為 SwiftUI。
- 不建立 SPM package 或新的 Xcode target。
- 不修改 SwiftPM、第三方套件、`Package.resolved` 或 `project.pbxproj`。
- 不新增 Unit Test target、測試或 CI 流程。
- 不改變 TMDB endpoint、JSON key、URL query key、UserDefaults key 或 Codable 儲存格式。
- 不處理 Accessibility、UI 視覺、spacing、動畫或其他非命名需求。
- 不將既有 `EisodeDetail/` 路徑拼字納入本次更名；檔案搬移與 project membership 風險應另案處理（已於 2026-09-15 另案修正為 `EpisodeDetail/`）。

---

## 3. 現況盤點

### 3.1 已統一的部分

| 角色 | 現況 |
|------|------|
| Network | 單一 `NetworkServicing` 入口，Repository 經 protocol 注入 |
| Repository protocol | 主要採 `...Providing` |
| Repository implementation | 主要採 `...Repository` |
| UseCase protocol | 動詞短語 + `UseCase` |
| UseCase implementation | `Default` + UseCase protocol 名稱 |
| UseCase 呼叫 | 23 個檔案統一使用 `callAsFunction(...)` |
| Router protocol | `...Routing` |
| Scene Builder | `...SceneBuilding` |
| Concurrency | Domain/Data 介面採 `Sendable`，ViewModel 與 Router 位於 `@MainActor` |
| Composition | concrete Repository、UseCase、ViewModel 由 `AppComposition` 組裝 |

上述介面應保留，不重新建立同義的 `ServiceProtocol`、`RepositoryProtocol` 或 `Interactor`。

### 3.2 實作前基線與遷移結果

#### N1 — 縮寫命名

實作前以靜態搜尋找到 181 行、26 個 Swift 檔包含 `Id`、`Url`、`Api`、`Http`、`Tv` 或 `Tmdb` 形式。這些命中包含真正需要修改的 Swift identifier，也包含第三方 API 參數或不應修改的相容性資料，因此遷移採逐一 symbol patch，未執行全域批次取代。

主要範圍：

- `AuthSession.sessionId`
- `LoginState.success(sessionId:)`
- `MemberCenterAccountContext.accountId` / `sessionId`
- `MemberCenterListRoute.accountId` / `sessionId`
- `MainTabBarAvatarProviding.fetchAvatarImage(sessionId:displayScale:)`
- `APIConfig.Account.*(accountId:)`
- `APIConfig.TV.*(seriesId:)`
- `APIConfig.List.*(listId:)`
- `APIConfig.Find.byExternalId(externalId:)`
- `favoriteTv`、`ratedTv`、`watchlistTv`

遷移後自有 Swift symbol 已改用標準縮寫。靜態搜尋只剩三個核准命中：YouTube SDK 的 `withVideoId`、`AuthSession` 相容性 key `sessionId`、`StoredUserProfile` 相容性 key `accountId`。

#### N2 — ViewModel 輸出契約

實作前 16 個 ViewModel 中：

- 11 個使用 `bind(onStateChange:)`。
- 3 個標記 `@Observable`：`MainHomeViewModel`、`ReviewListViewModel`、`SearchResultsViewModel`。
- 2 個沒有 state binding：`MainMemberSettingViewModel`、`MainTabBarViewModel`。

三個 `@Observable` ViewModel 的 UIKit Controller 沒有建立 Observation tracking，而是在操作後主動讀取 `viewModel.state`。因此目前同時存在 push 與 pull 兩種狀態輸出方式，且 `@Observable` 沒有成為實際畫面綁定介面。

遷移後 14 個具有非同步 state flow 的 ViewModel 全部使用 `bind(onStateChange:)`；`MainMemberSettingViewModel` 與 `MainTabBarViewModel` 保留同步 query/action 介面，不提供非同步 state binding；兩者列於 5.4，不另寫型別註解（1.2 起）。ViewModel 已無 `Observation` import 或 `@Observable`。

#### N3 — ViewModel 載入方法

實作前相同的首次載入語意使用：

- `loadHome()`
- `loadReviews(mediaID:)`
- `loadDailyTrending()`
- `loadInitial()`
- `loadInitialContent()`

分頁則混用：

- `loadNextPage(mediaID:)`
- `loadNextPageIfNeeded(currentItemID:)`
- `loadNextPageIfNeeded(currentMovieID:)`
- `loadNextDailyTrendingPageIfNeeded(currentResultID:)`

遷移後完整畫面首次載入統一為 `loadInitialContent(...)`；分頁門檻由 ViewModel 判斷時統一使用 `loadNextPageIfNeeded(currentItemID:)`。`ReviewListViewModel.loadNextPage()` 保留「Controller 已完成門檻判斷」的責任分工，`loadDailyTrending()` 則保留單一區塊載入語意。

#### N4 — Scene Builder 回傳型別

大部分 `make...ViewController` 回傳 `UIViewController`；`makeSearchResultsViewController(mediaKind:)` 回傳具體 `SearchResultsViewController`，讓呼叫端設定 `onItemSelected` 與 `onSortBarButtonVisibilityChanged`。

遷移後 factory 回傳 `UIViewController`，兩個 output callback 由 factory 參數注入；父畫面若需送入搜尋操作，只依賴窄化的 `SearchResultsHandling`，不再持有具體 `SearchResultsViewController` 型別。

#### N5 — Router 建立方式

目前 15 個 ViewController 以 protocol 屬性持有 Router，但在 ViewController 內建立具體 Router：

```swift
private lazy var router: MovieDetailRouting = MovieDetailRouter(
    sourceViewController: self,
    movieID: movieID,
    sceneBuilder: sceneBuilder
)
```

這符合目前「Router 屬 App 層、需要 weak source ViewController」的設計，不列為 Clean Architecture 違規。本次只統一命名，不強制導入 Router factory。若未來需要 Router mock，再另案評估注入 factory closure。

---

## 4. 核心命名規則

### 4.1 縮寫

Swift identifier 中的標準縮寫一律維持大寫：

| 不使用 | 統一使用 |
|--------|----------|
| `Id` | `ID` |
| `Url` | `URL` |
| `Api` | `API` |
| `Http` | `HTTP` |
| `Tv` | `TV` |
| `Tmdb` | `TMDB` |
| `Dto` | `DTO` |
| `Json` | `JSON` |
| `Uuid` | `UUID` |

範例：

```swift
let sessionID: String
let accountID: Int
let avatarURL: URL?

func fetchTVSeries(seriesID: Int) async throws -> TVSeries
```

不得使用：

```swift
let sessionId: String
let accountId: Int
let avatarUrl: URL?

func fetchTvSeries(seriesId: Int) async throws -> TVSeries
```

### 4.2 `id` 與具名 `...ID` 的選擇

當方法名稱已明確指出實體時，使用 `id`：

```swift
repository.movie(id: movieID)
repository.series(id: seriesID)
repository.person(id: personID)
repository.collection(id: collectionID)
```

當方法名稱本身無法判斷實體、同時接收多種 ID，或 ID 需要跨層保存時，使用具名 ID：

```swift
showMovieDetail(movieID: movieID)
showEpisodeDetail(
    seriesID: seriesID,
    seasonNumber: seasonNumber,
    episodeNumber: episodeNumber
)
mediaState(kind: kind, mediaID: mediaID, sessionID: sessionID)
```

屬性與 enum associated value 原則上使用具名 ID：

```swift
case user(sessionID: String)
case success(sessionID: String)

struct MemberCenterAccountContext {
    let accountID: Int
    let sessionID: String
}
```

若 associated value 或 property 參與 Codable／UserDefaults，必須先依 4.3 建立相容性轉接，不能只做 source rename。

### 4.3 不得修改的外部名稱

下列名稱即使使用 snake_case 或第三方慣例，也不得因本 SDD 改動：

- JSON `CodingKeys`，例如 `session_id`、`guest_session_id`。
- URL query item name，例如 `api_key`、`language`、`page`。
- TMDB endpoint path。
- UserDefaults key，例如 `TMDBSessionID`、`AuthSession`。
- 第三方 SDK 方法或參數，例如 YouTube SDK 的 `withVideoId`。
- Codable case discriminator 與既有持久化 payload。

本次只修改 Swift 原始碼中的自有 symbol 與其 call site。

#### Codable 相容性規則

`AuthSession` 使用 synthesized Codable 儲存於 UserDefaults。將：

```swift
case user(sessionId: String)
```

直接更名為：

```swift
case user(sessionID: String)
```

可能同時改變 encoded associated-value key。實作時必須提供明確 Codable 相容層：

- Swift source API 使用 `sessionID`。
- encoding 維持既有 persisted key `sessionId`，除非另有資料遷移規格。
- decoding 至少接受既有 `sessionId`；若曾輸出新版 key，才同時接受 `sessionID`。
- `.loggedOut`、`.guest`、`.user` 的 case discriminator 不變。
- 先以舊 payload 驗證 decode，再移除 synthesized Codable。

`StoredUserProfile.accountId` 同樣不得直接改變既有 JSON key。目標形式應使用明確 mapping：

```swift
private enum CodingKeys: String, CodingKey {
    case accountID = "accountId"
    // Other existing keys remain unchanged.
}
```

只有不參與持久化的 local variable、parameter、Presentation model 與 routing value 才能直接 rename。

---

## 5. 各角色介面命名

### 5.0 Protocol 後綴選擇

先依責任選擇後綴，不以個人偏好混用 `Protocol`、`Service`、`Manager`：

| 責任 | 後綴 | 例子 |
|------|------|------|
| 提供 Domain 資料或查詢能力 | `Providing` | `MovieDetailProviding`、`AccountProfileProviding` |
| 持久化讀寫 | `Storing` | `SessionStoring`、`UserProfileStoring` |
| 技術基礎設施的多操作入口 | `Servicing` | `NetworkServicing` |
| 單一應用操作或業務編排 | `UseCase` | `LoadMovieDetailUseCase` |
| 畫面導航 | `Routing` | `MovieDetailRouting` |
| 畫面建立能力 | `SceneBuilding` | `DetailSceneBuilding` |
| 流程完成／協調能力 | `Handling` | `AuthFlowHandling` |
| 將輸入解析成明確結果 | `Resolving` | `AppIntentSessionResolving` |
| 單一副作用能力 | 動名詞能力後綴 | `ImageCacheClearing`、`AuxiliaryLoadFailureReporting` |
| UIKit child → parent 事件 | `Delegate` | `LoginPageViewDelegate` |
| 值的表示或轉換要求 | `Representable`／`Convertible` | `GenrePageSheetItemRepresentable`、`ErrorMessageConvertible` |

補充規則：

- 不在 protocol 名稱尾端加 `Protocol`。
- `Servicing` 只用於 Network、Analytics 等技術入口，不恢復 feature-level Service layer。
- `Providing` 可以是 Repository protocol，也可以是窄讀取能力；以所在層與完整型別名稱判斷角色。
- `Handling`、`Resolving`、`Reporting`、`Clearing`、`Enriching` 必須描述單一可辨識能力，不得成為模糊的通用後綴。
- `Manager`、`Helper`、`Utility` 不作為新 protocol 的角色名稱。
- UI view contract 可以直接以 `...View` 命名，例如 `AuthPageView`；它不屬於 Repository 或 Service。

### 5.1 Repository

#### Protocol

Repository 抽象使用名詞 + `Providing`：

```swift
protocol MovieDetailProviding: Sendable
protocol AccountProfileProviding: Sendable
protocol SearchHistoryProviding: Sendable
```

不得新增：

```swift
protocol MovieDetailRepositoryProtocol
protocol MovieDetailService
protocol MovieDetailDataSource
```

`DataSource` 只保留給 Repository 內部需要區分 remote/local source 的情境，不作為 Presentation 的依賴。

#### Implementation

concrete implementation 使用名詞 + `Repository`：

```swift
final class MovieDetailRepository: MovieDetailProviding
final class MainSearchRepository: MainSearchProviding
```

#### 方法

- 無副作用查詢使用名詞短語：`movie(id:)`、`credits(movieID:)`、`reviews(kind:mediaID:page:)`。
- 寫入操作使用清楚動詞：`updateFavorite(...)`、`submitRating(...)`、`deleteRating(...)`。
- 不使用模糊名稱：`getData()`、`request()`、`fetchInfo()`、`process()`。
- 分頁統一回傳 `Page<Element>`，參數名稱統一為 `page`。

### 5.2 Storage

持久化抽象使用名詞 + `Storing`，實作使用名詞 + `Store`：

```swift
protocol SessionStoring
final class SessionStore: SessionStoring
```

方法命名：

```swift
func load() -> Value
func save(_ value: Value)
func clear()
```

面向 Domain／Presentation 的窄讀取能力可使用 `Providing`：

```swift
protocol AuthSessionProviding {
    func currentSession() -> AuthSession
    func clearSession()
}
```

不得讓 ViewModel 直接依賴 Data 層的 `SessionStoring` 或具體 Store。

### 5.3 UseCase

UseCase protocol 使用動詞短語 + `UseCase`，實作加 `Default` 前綴：

```swift
protocol LoadMovieDetailUseCase: Sendable
struct DefaultLoadMovieDetailUseCase: LoadMovieDetailUseCase
```

執行方法統一使用 `callAsFunction(...)`：

```swift
func callAsFunction(movieID: Int) async throws -> MovieDetailContent
```

不得混用 `execute()`、`perform()`、`invoke()`。`perform()` 保留給 App Intents 系統 API。

只在包含條件判斷、跨 Repository 編排或降級策略時建立 UseCase；單純轉呼叫不新增一層。

### 5.4 ViewModel

#### 型別

使用畫面名稱 + `ViewModel`：

```swift
final class MovieDetailViewModel
final class MainSearchViewModel
```

不新增通用 `BaseViewModel`、`AnyViewModel` 或空的 marker protocol。

#### State

使用畫面名稱 + `ViewState`：

```swift
enum MovieDetailViewState: Equatable {
    case idle
    case loading
    case loaded(MovieDetailPresentation)
    case empty
    case failed(ErrorMessage)
}
```

一般內容畫面優先使用：

- `.idle`
- `.loading`
- `.loaded(Content)`
- `.empty`
- `.failed(ErrorMessage)`

搜尋、登入等具有額外互動階段的畫面可以保留語意 case，例如 `.typing`、`.searching`、`.guestSuccess`，不得為了形式一致壓平成 Boolean 組合。

#### State output

有非同步狀態流的 UIKit ViewModel 統一使用：

```swift
func bind(
    onStateChange: @escaping @MainActor (FeatureViewState) -> Void
)
```

規則：

- `bind` 時立即送出目前 state。
- state setter 使用 `private(set)`。
- 重複 state 不重送。
- Controller 在 `bindViewModel()` 建立一次 binding。
- ViewModel 不 import UIKit。
- 不同的獨立狀態可增加具名 callback，例如 `onAccountStateChange`。
- 不保留未被 UIKit 觀察的 `@Observable`。

同步、無非同步 state flow 的 ViewModel 可以不提供 `bind`。程式碼不以型別註解標示（註解規則見第 13 節），改由本文件列出名單，避免誤判為遺漏：

- `MainMemberSettingViewModel`
- `MainTabBarViewModel`

新增同步 query/action model 時同步更新此名單。

#### Input method

統一使用語意動詞：

| 情境 | 命名 |
|------|------|
| 首次載入完整畫面 | `loadInitialContent()` |
| 使用相同條件重新載入 | `reloadContent()` |
| 使用者下拉重新整理 | `refreshContent()` |
| 接近尾端時載入下一頁 | `loadNextPageIfNeeded(currentItemID:)` |
| 已確定必須載入下一頁 | `loadNextPage()` |
| 搜尋 | `search(keyword:)` |
| 選擇篩選 | `selectFilter(_:)` |
| 選擇排序 | `selectSortOption(_:)` |
| 提交資料 | `submit...(...)` |
| 刪除資料 | `delete...()` |
| 切換狀態 | `toggle...()` |

`loadNextPageIfNeeded` 的參數統一為 `currentItemID`。ViewModel 已持有 media kind 或查詢上下文時，不重複使用 `currentMovieID`、`currentResultID` 等名稱。

若首次載入只涵蓋單一明確區塊而非整頁，可保留具體名稱，例如 `loadDailyTrending()`；必須在同一 ViewModel 中與完整頁面載入語意清楚區分。

### 5.5 Router

Router protocol 使用畫面名稱 + `Routing`；實作使用畫面名稱 + `Router`：

```swift
protocol MovieDetailRouting: AnyObject
final class MovieDetailRouter: BaseRouter, MovieDetailRouting
```

方法動詞：

| 動作 | 命名 |
|------|------|
| App 內 push / present / sheet | `show...` |
| Safari 或外部 URL | `open...` |
| 返回上一頁 | `close()`、`dismiss()` 或 `pop()`，依實際 presentation 語意 |

參數規則：

```swift
func showDetail(for item: HomeContentItem)
func showMovieDetail(movieID: Int)
func showMediaDetail(kind: MediaKind, id: Int)
```

- 傳入完整 item 時使用 `for item:`。
- 只有 scalar identifier 時，方法名稱必須包含實體，參數使用具名 `...ID`。
- 共用 Router 不接收 feature-specific presentation model。
- Router 不建立 Repository、UseCase 或 ViewModel。
- ViewModel 不持有 Router。

### 5.6 Scene Builder 與 Factory

Scene Builder protocol 使用導航範圍 + `SceneBuilding`：

```swift
protocol DetailSceneBuilding: LoginSceneBuilding
protocol MemberCenterSceneBuilding: DetailSceneBuilding
```

建立畫面的方法使用 `make` + 完整畫面名稱：

```swift
func makeMovieDetailViewController(movieID: Int) -> UIViewController
```

規則：

- 對外統一回傳 `UIViewController`，隱藏具體 Controller。
- 呼叫端需要事件 callback 時，callback 由 factory 參數注入。
- 不為了回傳具體型別而擴大 Scene Builder 介面。
- Scene Builder 依導航能力拆分，不建立單一全 App 巨型 protocol。

搜尋畫面的目標形式：

```swift
func makeSearchResultsViewController(
    mediaKind: MediaKind,
    onItemSelected: @escaping @MainActor (Int) -> Void,
    onSortBarButtonVisibilityChanged: @escaping @MainActor (Bool, MediaSortOrder?) -> Void
) -> UIViewController
```

callback 的實際 Sendable／actor 標註應以 Swift 6 編譯結果為準，但不得讓 factory 回傳具體 `SearchResultsViewController`。

### 5.7 Factory property name

注入屬性依角色命名，不依具體型別命名：

```swift
private let repository: MovieDetailProviding
private let loadMovieDetail: LoadMovieDetailUseCase
private let sessionProvider: AuthSessionProviding
private let sceneBuilder: DetailSceneBuilding
```

同一型別注入多個不同用途時，使用用途名稱，例如 `contentRepository`、`genreRepository`。不得使用 `manager`、`helper`、`handler` 作為無法判斷責任的萬用名稱。

既有 `AuthFlowHandler`、`AppIntentFavoriteActionHandler` 有明確流程責任，不因本規則更名。

### 5.8 Error

- 技術層錯誤：`...Error`，例如 `NetworkError`。
- 領域錯誤：`DomainError` 或 feature-specific `...Error`。
- 畫面文案：`ErrorMessage`。
- 表示可預期結果而非 Swift error 時，可使用 `...Result`。
- 不使用 `errorString`、`messageError` 或以裸 `String` 取代錯誤型別。

目前 `NetworkError` 穿透到 Presentation 是既有 Clean Architecture SDD 接受的例外，本次只統一名稱，不改寫錯誤邊界。

---

## 6. 目標介面範例

```swift
nonisolated protocol MediaSearchProviding: Sendable {
    func search(
        kind: MediaKind,
        keyword: String,
        page: Int
    ) async throws -> Page<MediaSummary>
}

nonisolated protocol SearchMediaUseCase: Sendable {
    func callAsFunction(
        kind: MediaKind,
        keyword: String,
        page: Int
    ) async throws -> Page<MediaSummary>
}

@MainActor
final class SearchResultsViewModel {
    private(set) var state: SearchResultsViewState = .idle

    private let searchMedia: SearchMediaUseCase
    private var onStateChange: (@MainActor (SearchResultsViewState) -> Void)?

    init(searchMedia: SearchMediaUseCase) {
        self.searchMedia = searchMedia
    }

    func bind(
        onStateChange: @escaping @MainActor (SearchResultsViewState) -> Void
    ) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    func search(keyword: String) async {
        // Existing behavior is preserved.
    }

    func loadNextPageIfNeeded(currentItemID: Int) async {
        // Existing behavior is preserved.
    }
}
```

此範例只表示命名與介面形狀，不授權改變現有搜尋行為。

---

## 7. 遷移對照表

### 7.1 確定更名

| 現況 | 目標 |
|------|------|
| `sessionId` | `sessionID`，Codable key 保留 `sessionId` |
| `guestSessionId` | `guestSessionID` |
| `accountId` | `accountID`，`StoredUserProfile` key 保留 `accountId` |
| `seriesId` | `seriesID` |
| `listId` | `listID` |
| `reviewId` | `reviewID` |
| `externalId` | `externalID` |
| `episodeId` | `episodeID` |
| `episodeGroupId` | `episodeGroupID` |
| `seasonId` | `seasonID` |
| `favoriteTv` | `favoriteTV` |
| `ratedTv` | `ratedTV` |
| `ratedTvEpisodes` | `ratedTVEpisodes` |
| `watchlistTv` | `watchlistTV` |
| `fetchAvatarImage(sessionId:displayScale:)` | `fetchAvatarImage(sessionID:displayScale:)` |

### 7.2 需依語意調整

| 現況 | 目標 | 條件 |
|------|------|------|
| `loadHome()` | `loadInitialContent()` | 代表首頁完整首次載入時 |
| `loadReviews(mediaID:)` | `loadInitialContent(mediaID:)` | media ID 尚未成為 ViewModel 初始化上下文時 |
| `loadInitial()` | `loadInitialContent()` | 無額外行為差異時 |
| `loadNextPage(mediaID:)` | `loadNextPage()` 或 `loadNextPageIfNeeded(currentItemID:)` | 依呼叫端是否已做觸發判斷 |
| `loadNextPageIfNeeded(currentMovieID:)` | `loadNextPageIfNeeded(currentItemID:)` | ViewModel 已持有 `MediaKind` 時 |
| `loadNextPageIfNeeded(currentResultID:)` | `loadNextPageIfNeeded(currentItemID:)` | 不需暴露 item 類型差異時 |

### 7.3 不更名

- Repository 的 `movie(id:)`、`series(id:)`、`person(id:)`。
- UseCase 的 `callAsFunction(...)`。
- `Providing`、`Repository`、`UseCase`、`Routing`、`SceneBuilding` 後綴。
- `MainSearchMediaType`、`SearchHistoryScope` 等具有不同領域語意的型別。
- `AuthFlowHandler` 與 App Intent 系統要求的 `perform()`。

---

## 8. 實作階段

### Phase 0 — 基線與保護

- 記錄 `git status`、staged diff、unstaged diff。
- 確認本次不修改 `AppComposition.swift` 中使用者尚未提交的既有變更，除非該行是核准範圍內的介面 call site。
- 執行既有五項 Clean Architecture 邊界檢查。
- 產生 identifier inventory，人工分類自有 symbol、第三方 API、字串與持久化名稱。
- 不執行全域 search-and-replace。

### Phase 1 — 縮寫與 ID 命名

- 先為 `AuthSession` 與 `StoredUserProfile` 建立並驗證 Codable 相容層。
- 再改 Domain 與 Presentation 的公開／跨 feature value types。
- 再改 Router、Scene Builder、ViewModel 方法參數。
- 最後改 Data 層 `APIConfig` Swift 參數名稱與 call site。
- JSON key、query key、UserDefaults key、Codable 格式保持不變。
- 每一組 rename 必須與全部 call site 放在同一 commit。

### Phase 2 — ViewModel 輸出介面

- 將三個未實際被觀察的 `@Observable` ViewModel 收斂為 `bind(onStateChange:)`。
- Controller 在 `bindViewModel()` 設定 binding。
- 移除 Controller 為同步狀態而手動呼叫的重複 render，但保留 loading、取消與 retry 行為。
- `MainMemberSettingViewModel`、`MainTabBarViewModel` 依實際狀態流決定是否維持同步介面。
- 不新增通用基底型別。

### Phase 3 — ViewModel input method

- 依 5.4 統一首次載入、重新載入、分頁方法名稱。
- 方法更名與 Controller call site 同步提交。
- 不在本階段搬動 pagination 判斷責任或改變觸發門檻。

### Phase 4 — Scene Builder 與 Router

- 將搜尋 Scene Builder 的 callback 改為參數注入。
- Scene Builder 對外統一回傳 `UIViewController`。
- Router 的 `show`／`open` 與參數標籤依 5.5 統一。
- Router 仍由現有 Controller／App 層持有，不新增 Coordinator。

### Phase 5 — 文件與收尾

- 更新 `SDD-CleanArchitecture-Migration.md` 中 ViewModel output、Scene Builder 與命名範例。
- 更新不再正確的數量與路徑。
- 執行驗收矩陣。
- runtime 尚未走查時，狀態不得標記為 Implemented 或 Complete。

---

## 9. 靜態驗收

以下命令以專案預設 zsh 可執行的 `rg` glob 撰寫，不依賴 Bash 對多行變數的 word splitting。

### 9.1 Clean Architecture 邊界

```bash
rg -n '^import ' -g '**/Domain/**/*.swift' | rg -v 'import Foundation'
rg -n 'NetworkServic|APIConfig|DTO|UIKit|ErrorMessage' -g '**/Domain/**/*.swift'
rg -n 'ViewModel|ViewController|UIKit' -g '**/Data/**/*.swift'
rg -n '\b[A-Za-z][A-Za-z0-9]*DTO\b' -g '*.swift' -g '!**/Data/**'
```

以上四項預期無輸出。Data 不得引用 Presentation type 的第五項檢查，需沿用 `SDD-CleanArchitecture-Migration.md` 的型別清單檢查，或整理成獨立 script 後執行。

### 9.2 命名

```bash
rg -n '\b[A-Za-z][A-Za-z0-9]*(Id|Url|Api|Http|Tv|Tmdb|Dto|Json|Uuid)\b' -g '*.swift'
rg -n '\b(favoriteTv|ratedTv|watchlistTv)\b' -g '*.swift'
```

允許命中必須逐筆列入例外清單；第三方 SDK symbol、字串內容與相容性 key 不納入失敗。

### 9.3 ViewModel

```bash
rg -n '^import Observation|@Observable' -g '*ViewModel.swift'
rg -n 'func bind\(' -g '*ViewModel.swift'
rg -n 'func (loadHome|loadReviews|loadInitial|loadNextPage)\b' -g '*ViewModel.swift'
```

預期：

- 第一項無輸出，除非未來有真正使用 Observation tracking 的核准 feature。
- 有非同步 state flow 的 ViewModel 都有 `bind`。
- 第三項只保留經 5.4 明確核准的語意例外。

### 9.4 Composition 與 Router

```bash
rg -n -- '-> [A-Za-z][A-Za-z0-9]*ViewController' MyTMDB_App/Composition/AppComposition.swift | rg -v -- '-> UIViewController'
rg -n 'Repository\(|Default[A-Za-z]+UseCase\(|ViewModel\(' -g '*Router.swift'
rg -n 'AppComposition' -g '*ViewModel.swift' -g '*UseCase.swift' -g '*Repository.swift'
```

預期三項無輸出。第一項已排除 `-> UIViewController`，只回報單行宣告中的具體 feature ViewController；多行宣告仍需 code review。

### 9.5 Diff

```bash
git diff --check
git diff --cached --check
```

實作時必須分別檢查 staged 與 unstaged 範圍，不得自動 reset 或重新 stage 使用者既有修改。

---

## 10. Build 與 Runtime 驗收

### 10.1 Build

本 SDD 建立階段不執行 build。實作完成後，僅在使用者明確允許時執行：

```bash
xcodebuild \
  -project MyTMDB_App.xcodeproj \
  -scheme MyTMDB_App \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  -disableAutomaticPackageResolution \
  -derivedDataPath /tmp/MyTMDB_AppUnifiedInterfaceDerivedData \
  build
```

不得因 build 失敗自行 Resolve Package Versions、Reset Package Caches、修改 package reference 或 `Package.resolved`。

### 10.2 Runtime

介面更名雖不應改變行為，仍需走查受影響流程：

- 冷啟動 session validation。
- 使用者登入、訪客登入、登出。
- MainHome 初次載入與 retry。
- MainSearch daily trending、搜尋、分頁、搜尋紀錄。
- Movie / TV list 篩選、排序、搜尋結果跳轉。
- Movie / TV / Season / Episode / Person detail 導航。
- Review list 首頁、篩選與分頁。
- MemberCenter overview、列表與分頁。
- App Intent 的 movie / TV detail 與 favorite action。

未執行 runtime 走查時，只能回報 source/static/build 結果，不得宣稱功能驗證完成。

---

## 11. 驗收條件

- [x] Swift 自有 symbol 的標準縮寫統一為 `ID`、`URL`、`API`、`HTTP`、`TV`、`TMDB`、`DTO`、`JSON`、`UUID`。
- [x] JSON key、query key、UserDefaults key 與 Codable payload 未改變。
- [x] `AuthSession` 可以解碼更名前已存在的 `.guest`／`.user` payload。
- [x] `StoredUserProfile` 可以解碼既有 `accountId` payload。
- [x] Repository protocol 使用 `...Providing`，實作使用 `...Repository`。
- [x] UseCase 使用 `...UseCase`、`Default...UseCase` 與 `callAsFunction(...)`。
- [x] 有非同步狀態流的 UIKit ViewModel 統一使用 `bind(onStateChange:)`。
- [x] 未被實際觀察的 `@Observable` 已移除。
- [x] 首次載入、refresh、reload、pagination 方法符合 5.4。
- [x] Router 使用 `...Routing`／`...Router` 與 `show`／`open` 語意。
- [x] Scene Builder 不回傳具體 feature ViewController。
- [x] ViewModel 不持有 Router、`AppComposition` 或 Data concrete type。
- [x] Router 不建立 Repository、UseCase 或 ViewModel。
- [x] Domain／Data／Presentation 靜態邊界檢查通過。
- [x] 未新增 Coordinator、BaseViewModel、Service Locator 或無業務價值的 UseCase。
- [x] 未修改 SwiftPM、第三方套件、`Package.resolved` 或 `project.pbxproj`。
- [x] `git diff --check` 與 staged diff check 通過。
- [x] Build：Passed（2026-09-26，iOS Simulator Debug build）。
- [ ] Runtime：Partial（2026-09-26 主要流程走查正常，見 11.2）。

### 11.1 本次驗證紀錄

- 全專案 Swift parser：Passed。
- `AuthSession` 舊 `sessionId` payload decode、新 `sessionID` payload decode、舊 key encode 相容性 executable check：Passed。
- `StoredUserProfile` 舊 `accountId` payload decode 與舊 key encode 相容性 executable check：Passed。
- 四項 Domain／Data 邊界檢查與 Data 不引用 Presentation 型別檢查：Passed，無輸出。
- 命名檢查：Passed；僅保留三個 4.3 核准例外。
- ViewModel Observation 檢查：Passed，無輸出；14 / 16 個 ViewModel 提供 `bind`，其餘 2 個為已註解的同步 query/action model。
- Scene Builder、Router construction、`AppComposition` leak 檢查：Passed，無輸出。
- `git diff --check`、`git diff --cached --check`：Passed。
- Xcode Build：NotRun。
- Runtime / UI：NotRun。

### 11.2 現況複核（2026-09-26）

以目前 HEAD 重跑第 9 節靜態驗收，確認後續新增的 `CompanyDetail`、圖片預覽重構與 `ThemeColor` 統一未破壞本文件規則：

- 9.1 Clean Architecture 邊界四項：Passed，無輸出。
- 9.2 命名：Passed；只命中三個 4.3 核准例外（`YTPlayerView` 的 `withVideoId:`、`StoredUserProfile` 的 `accountId` 相容 key、`AuthSession` 的 `sessionId` 相容 key）。
- 9.3 ViewModel：Observation 檢查無輸出；17 個 ViewModel 中 15 個提供 `bind`，其餘為 5.4 名單內的 `MainMemberSettingViewModel`、`MainTabBarViewModel`；載入方法只命中 5.4 核准的 `ReviewListViewModel.loadNextPage()`。
- 9.4 Composition 與 Router 三項：Passed，無輸出。
- Xcode Build：Passed（iOS Simulator Debug build）。
- Runtime / UI：Partial（iPhone 17 Simulator 訪客模式走查首頁、電影／影集詳情、公司詳情、圖片預覽與設定頁，皆正常；未逐一走查所有畫面）。

---

## 12. 風險與緩解

| 編號 | 風險 | 緩解 |
|------|------|------|
| R1 | 全域 rename 誤改 JSON／儲存格式 | 只用 IDE/compiler-aware rename 或逐 symbol patch；字串與 CodingKeys 不批次替換 |
| R2 | `AuthSession` Codable shape 被誤改 | 更名前建立相容性確認；不得改 case discriminator 或儲存 payload |
| R3 | ViewModel output 遷移漏掉 loading／pagination render | 一個 feature 一個 commit，對照原 Controller 每個 render 點 |
| R4 | callback 改由 Scene Builder 注入後形成引用環 | callback 使用 weak capture；Router／Controller 來源維持 weak ownership |
| R5 | 為一致性建立過度抽象 | 禁止 BaseViewModel、巨大 Scene Builder、每個 Repository 方法一個 UseCase |
| R6 | 單一 target 無法阻止跨層引用 | 每個 phase 重跑靜態邊界檢查與 code review |
| R7 | 使用者既有 `AppComposition.swift` 修改被覆蓋 | patch 前重讀檔案，分別檢查 staged／unstaged diff，不 reset |
| R8 | 更名造成 App Intent 或 deep-link 失效 | factory／route call site 同 commit 修改，並保留 runtime 走查項目 |
| R9 | build 操作擾動 SwiftPM | 未授權不 build；授權後使用 `-disableAutomaticPackageResolution` 與獨立 DerivedData |

---

## 13. 維護規則

- 新增 acronym identifier 時遵守 4.1。
- 新增 Repository、UseCase、Router、Scene Builder 時遵守第 5 節。
- 新增 ViewModel 前先判斷是否真的有非同步 state flow；有才使用統一 binding。
- 程式碼註解只使用 `// MARK: -` 分段，不寫行內 `//`、文件註解 `///` 或 `/* */`，也不保留既有的說明註解；需要說明的設計決策寫進 SDD。檔頭的 Xcode 範本（檔名、專案、建立者）不在此限。
- 新增 pagination 時使用 `loadNextPageIfNeeded(currentItemID:)`，除非 feature 有文件化差異。
- 新增 scene factory 時回傳 `UIViewController`，事件由 factory 參數或窄 protocol 注入。
- 不以「所有名稱都一樣」取代領域語意；Search、Login 等合法狀態差異應保留。
- 每次修改 Domain 或 Data 後執行 Clean Architecture 靜態邊界檢查。
- 每次更名先確認 persisted data、App Intent、deep-link、selector 與第三方 SDK 是否依賴原始名稱。
- 本文件完成一個 phase 後，更新狀態與修訂紀錄，不以計畫內容冒充已實作結果。

---

## 14. 修訂紀錄

| 版本 | 日期 | 內容 |
|------|------|------|
| 1.3 | 2026-09-26 | 對齊現況：新增 11.2 以目前 HEAD 重跑第 9 節靜態驗收（全部通過）；Build 更新為 Passed、Runtime 為 Partial；metadata 狀態改為規格／實作／驗證三欄 |
| 1.2 | 2026-09-22 | 註解規則改為只使用 `// MARK: -`：5.4 刪除同步 query/action model 的型別註解要求，改由本文件列出名單；第 13 節新增註解維護規則。程式碼同步移除 `MainMemberSettingViewModel`、`MainTabBarViewModel` 的型別註解與 `AppDelegate`／`SceneDelegate` 的 Xcode 範本註解，並將 12 處 `// MARK:` 補上 `-`。11.1 為 1.1 當時的驗證紀錄，不回溯修改 |
| 1.1 | 2026-09-15 | 套用統一命名與介面：縮寫／ID、Codable 相容層、ViewModel binding 與載入方法、搜尋 Scene Builder callback 注入及 Router 動詞；Swift parser、Codable executable check、Clean Architecture 與靜態命名檢查通過，Build / Runtime NotRun |
| 1.0 | 2026-09-15 | 依目前 337 個 Swift 檔、16 個 ViewModel、23 個 UseCase、單一 target 與現行 Clean Architecture SDD 建立介面與命名統一規格；只建立文件，尚未修改 production code、執行 build 或 runtime 走查 |
