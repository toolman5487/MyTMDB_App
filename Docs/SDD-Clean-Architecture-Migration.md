# SDD: CineBase Clean Architecture 分層遷移

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | 6.0 language mode，`SWIFT_STRICT_CONCURRENCY = complete` |
| 現行 UI 架構 | UIKit + MVVM + Presentation Builder + Router |
| 目標架構 | Clean Architecture（Domain / Data / Presentation / App 四層，以資料夾表達，不建 SPM package） |
| 影響範圍 | 起點 243 個 Swift 檔 / 47,616 行；目前 314 個 Swift 檔 / 45,799 行 |
| 狀態 | Phase 1、Phase 2 完成；Phase 3 已完成 G5 的 4 個跨 feature UseCase，composition root 尚未開始 |
| 日期 | 2026-09-13 |

---

## 1. 目的

本文件定義 CineBase 由現行 MVVM 分層遷移至 Clean Architecture 的設計規格、分階段計畫與驗收標準。

本文件同時要回答一個前置問題：**這個遷移在什麼條件下才划算**。因此 Phase 3（依賴反轉與 composition root）帶有明確的進入條件，不是無條件執行的項目。實體模組拆分已取消，見 11 節。

本文件不涵蓋自動化測試規格。相關內容已於 v1.1 移除，見 16 節修訂紀錄與 13 節風險條目 R2。

---

## 2. 目標與非目標

### 2.1 架構目標

- 建立 Domain 層，讓業務規則不依賴 TMDB JSON 格式、不依賴 UIKit、不依賴任何第三方套件。
- 業務編排邏輯由 Service 移出，成為職責單一的 UseCase。
- 所有遠端資料存取統一經過 Repository 抽象，保留快取與本地資料來源的插入點。
- 建立 composition root，移除編譯期對 concrete type 的依賴。
- 讓層與層的依賴規則可透過固定的機械檢查與 code review 驗證，而非只依靠資料夾命名直覺。

### 2.2 品質目標

- 消除 Movie / TV 平行重複程式碼，重複檔案組數由 31 降至 10 以下（Detail 依 9.2 評估結果可例外）。
- 以 `MediaKind` 取代 2 個純二元的 `case movie / case tv` 列舉；其餘 3 個含額外語意的型別保留（見 9.1）。
- 遷移過程中每個 Phase 結束時 App 皆可編譯、可執行、功能不退化。
- 每個 Phase 可獨立驗收，不產生跨 Phase 的長期分支。

### 2.3 非目標

- 不改變現有產品功能、畫面與導覽行為。
- 不改寫 UIKit 為 SwiftUI。
- 不引入 RxSwift、Combine 或第三方 DI 框架。
- 不引入本地資料庫（Core Data / SwiftData / Realm）。Repository 只是**保留**插入點，本階段不實作快取。
- 不建立自動化測試，不新增測試 target。
- **不建立 SPM package**。層次收在各 feature 的 `Domain/`、`Data/` 資料夾，不設實體模組邊界（見 4.3）。
- 不搬移 Presentation 與 App 檔案的資料夾位置。架構缺口是 G1/G2/G3，檔案位置不是。
- 不為了分層而分層：只有真正含業務規則的程式碼才進 Domain（見 5.6）。

---

## 3. 現況盤點

### 3.1 量化現況

數值為兩個時間點的對照：**起點**為 `39e9882`，**現在**為 Phase 1、11 個 Phase 2 feature，以及 Phase 3 的 4 個跨 feature Account UseCase 完成實作後的工作樹。檔案數與行數以工作樹中的 Swift 原始碼為準；ViewModel / Service 數沿用原盤點口徑，計算對應角色資料夾內的 Swift 檔。

| 項目 | 起點 | 現在 |
|------|------|------|
| Swift 檔案數 | 243 | 314 |
| 程式碼行數 | 47,616 | 45,799 |
| Xcode target 數 | 1（`MyTMDB_App`，application） | 1 |
| 檔案組織方式 | 240 檔為顯式 `PBXFileReference`，`MyTMDB_App/` 資料夾使用 `PBXFileSystemSynchronizedRootGroup` | 不變 |
| ViewModel 資料夾內 Swift 檔案數 | 24 | 20 |
| Service 資料夾內 Swift 檔案數 | 22 | 8 |
| Repository 實作數 | 2（皆位於 `MemberCenter`） | 13 |
| UseCase 檔案數 | 0 | 20 |
| Domain Entity 型別數 | 0 | 89（分布於 40 檔） |
| `import UIKit` 出現在 ViewModel / Service / Model / Presentation | 2 檔 | 2 檔 |
| `= NetworkService()` 預設參數 | 18 處 | 17 處 |
| 其他 concrete dependency 預設參數 | 49 處 | 仍有多處，Phase 3 開始前依 10.1 重新盤點 |
| `convenience init()` 硬接依賴 | 4 處 | 4 處 |
| Movie / TV 平行檔案組 | 31 組 | 9 組（僅 MovieDetail↔TVDetail） |
| 獨立的 `case movie / case tv` 列舉 | 5 個 | 3 個（皆非二元，見 9.1） |

專案採用顯式檔案參照而非全資料夾同步，代表**新增 Swift 檔需手動加入 target**。既有 commit `711763f`（`fix: add member center list repository to target`）即為漏加所致。此為需持續注意的操作風險，見 13 節 R5。

依賴注入仍未進入系統性處理：`AppDependencies` 尚不存在、4 個 `convenience init()` 仍保留，且仍有 17 處 `= NetworkService()`。這是預期內的過渡狀態；composition root 屬於獨立步驟，不隨個別 feature 進行（見 10.4）。

### 3.2 已符合 Clean Architecture 的部分

這些是遷移中最難補的項目，專案已經具備，必須在遷移中**保留而非重寫**：

- **UI 框架隔離已成立。** 243 檔中 130 檔 `import UIKit`，但 ViewModel / Service / Model / Presentation 層僅 2 個例外：`MainLogIn/Service/AppRootFactory.swift` 與 `MainTabBar/Service/MainTabBarAvatarService.swift`。兩者本質為 UI factory，屬於位置放錯而非設計錯誤。
- **已分層 feature 的 DTO 未外洩至 UI 層。** `ReviewList`、`MovieDetail`、`TVDetail`、`SeasonDetail`、`EpisodeDetail`、`PersonDetail` 的 ViewModel、Presentation、Controller 與 View 均只使用 Domain Entity 或 presentation model。
- **Presentation 層已存在。** `MovieDetail`、`TVDetail`、`SeasonDetail`、`PersonDetail`、`EpisodeDetail`、`MainHome`、`MemberCenter` 共有 8 個 `SectionBuilder` / `PresentationBuilder`，皆為輸入輸出俱為值型別的靜態純函數。這等同 Clean 的 Presenter。
- **Protocol 邊界已建立。** `NetworkServicing`、`MovieDetailProviding`、`TVDetailProviding`、`ReviewProviding`、`SessionStoring`、`MemberCenterContentProviding` 等，依賴皆以 protocol 宣告。
- **Swift 6 嚴格並行已就緒。** Service 層一致標註 `nonisolated` + `Sendable`，ViewModel 標註 `@MainActor`，並行以 `async let` 與 `withThrowingTaskGroup` 實作。

### 3.3 落差清單

#### G1 — Domain Entity 覆蓋 Phase 2 範圍（已完成）

11 個 Phase 2 feature 均已完成 Entity / DTO 分離，Domain Entity 不具 `Decodable` / `Encodable` conformance。

HomeSectionList 原本直接使用 `MediaGenreListDTO`、MainHome 的 `MainHomeContent` 兼任 DTO 與 Model，以及 MemberCenter 直接使用 `MediaSummaryDTO` 的過渡狀態皆已解除。Phase 2 範圍執行 DTO 外洩檢查無輸出。

影響：尚未分層的 feature 仍可能讓 TMDB 欄位變更直接衝擊 Presentation。4.3 已補上逐 feature 的 DTO 外洩檢查；該檢查只要求正在驗收的 feature 無輸出，不要求尚未分層的 feature 提前通過。

#### G2 — UseCase 覆蓋明確業務編排（已完成）

`LoadReviewsUseCase`、`FilterReviewsUseCase`、`LoadMovieDetailUseCase`、`LoadTVDetailUseCase`、`LoadSeasonDetailUseCase`、`LoadEpisodeDetailUseCase`、`LoadPersonDetailUseCase`、`LoadPersonCreditsUseCase` 已建立。MovieDetail、TVDetail、SeasonDetail、EpisodeDetail 與 PersonDetail 的「主要資料失敗則整體失敗，輔助資料失敗則降級」已由 Service 移入 UseCase；PersonDetail 的作品類型路由與輸入驗證也已移入 UseCase。

MainHome 的併發載入與部分失敗處理已由 `MainHomeService` 移入 `LoadHomeSectionsUseCase`；HomeSectionList 的類型篩選移入 `FilterMediaByGenreUseCase`。

MemberCenter 的帳號內容載入已由 `LoadMemberCenterOverviewUseCase` 與 `LoadAccountCollectionPageUseCase` 承接。跨 feature 的帳號媒體狀態則已抽為 `LoadAccountMediaStateUseCase`、`ToggleFavoriteUseCase`、`SubmitRatingUseCase`、`DeleteRatingUseCase`（見 G5）。

#### G3 — Repository 抽象尚未覆蓋全部遠端資料（部分完成）

目前有 13 個 Repository 實作，Phase 2 的 11 個 feature 與跨 feature 的帳號媒體狀態皆已有 Repository protocol 邊界。未列入 Phase 2 的既有功能仍有 `ViewModel → Service → NetworkService` 直通，因此全專案覆蓋仍屬部分完成。

影響：無快取、離線、本地資料來源的插入點。

#### G4 — 依賴反轉僅完成一半

protocol 已宣告，但仍有 17 處 `network: NetworkServicing = NetworkService()`、多處 concrete dependency 預設值、4 處 `convenience init()`，使編譯期依賴仍指向具體型別：

```swift
convenience init() {
    self.init(
        loadMovieDetailUseCase: DefaultLoadMovieDetailUseCase(
            repository: MovieDetailRepository(),
            auxiliaryFailureHandler: { _, _, _ in }
        ),
        accountStateService: MovieAccountStateService(),
        sessionStore: SessionStore(),
        accountService: AccountService(),
        accountMediaService: MemberCenterService()
    )
}
```

影響：無 composition root。抽換實作需逐處修改初始化呼叫端，變更成本與依賴數量成正比。

#### G5 — Detail 系列帳號流程（UseCase 已完成，組裝待 G4 收斂）

`MovieDetailViewModel`、`TVDetailViewModel`、`EpisodeDetailViewModel` 已不再直接編排 `SessionStoring`、`AccountServiceProtocol` 與 `AccountMediaStateProviding`。登入檢查、帳號解析、收藏與評分寫入已移至 4 個 Domain UseCase；`DetailAccountMediaStateController` 縮減為畫面狀態協調與錯誤文案映射。

剩餘工作：UseCase 與 Repository 的 concrete 組裝仍暫存在既有便利初始化，待 G4 的 `AppDependencies` 一次集中。

#### G6 — Movie / TV 平行重複（已完成）

起點以 Movie / TV token 正規化後可配對的檔案共 31 組；Phase 1 已降為 9 組，僅保留經評估不適合合併的 `MovieDetail↔TVDetail`。

以 `ReviewList` 為例，正規化後 diff 僅 36 行，且內容全為文案與參數名差異：

| 檔案 | Movie | TV |
|------|-------|-----|
| ViewModel | 237 行 | 237 行 |
| Service | 47 行 | 47 行 |
| Models | 212 行 | 210 行 |

例外是 `PageSheet/Genre`：兩個 controller 各僅 37 行，已共用 `BaseGenrePageSheetViewController`，證明此類去重在本專案是可行的。

原先 5 個彼此獨立的相關列舉中，2 個純二元型別已由 `MediaKind` 取代；其餘 3 個因包含額外 case 或持久化格式而保留，見 9.1。

結果：Phase 2 不再建立成對的 Movie / TV 分層檔案；可共用的 Entity 與 DTO 在第二個 feature 使用時升格至 `Feature/`。

#### G7 — 無模組邊界（已接受的限制）

單一 target 意味著層與層之間僅靠資料夾命名約束。在 ViewModel 中 `import UIKit` 或直接建立 `URLSession` 皆可通過編譯。

影響：3.2 所列的既有優點仍需依靠 4.3 的機械檢查與 code review 維持，無法由編譯器防止回退。模組拆分已取消，不再列為本遷移的待完成項目。

### 3.4 判定

**遷移可行，且 Phase 1、Phase 2 已完成。** G1、G2、G5 的業務分層已收斂；G3 在 Phase 2 範圍完成、全專案仍為部分覆蓋；下一步為 G4 的 composition root；G7 為已接受限制。

實際遷移順序為 **G6 → G1/G2/G3 → G4/G5**，理由：

1. G6 已先完成，避免 Domain / Data 層把原有 Movie / TV 重複放大。
2. G1/G2/G3 可逐 feature 交付，每次都能獨立取得 Entity、UseCase、Repository 的價值。
3. G4/G5 必須等需要依賴反轉的 feature 完成分層後，再由 composition root 一次收斂，避免過渡期出現多個組裝點（見 10.4）。

---

## 4. 目標架構

### 4.1 分層

```text
App
  Controller / View / Cell / Router / AppDelegate / SceneDelegate
  Composition Root (AppDependencies)
  import UIKit, SnapKit, SDWebImage, Lottie, SkeletonView, YouTubeiOSPlayerHelper
        |
        v
Presentation
  ViewModel / ViewState / SectionBuilder / PresentationModels
  import Foundation, Domain
        |
        v
Domain
  Entity / UseCase / Repository protocol / DomainError / MediaKind
  import Foundation
        ^
        |
Data
  DTO / Mapper / Repository impl / NetworkService / SessionStore / APIConfig
  import Foundation, Domain
```

### 4.2 依賴規則

| 層 | 可依賴 | 不可依賴 |
|----|--------|----------|
| Domain | Foundation | 其他任何層、UIKit、任何第三方套件 |
| Data | Foundation、Domain | Presentation、App、UIKit |
| Presentation | Foundation、Domain | Data、App、UIKit |
| App | 全部 | 無限制 |

補充規則：

- Domain 型別**不得** conform `Decodable` 或 `Encodable`。序列化是 Data 層的責任。
- Presentation 層**不得** import Data。ViewModel 只認識 Domain 的 UseCase protocol。
- Data 層的 DTO **不得**離開 Data 層，一律經 Mapper 轉為 Domain Entity 後才向外傳遞。
- Router 屬於 App 層；ViewModel 不持有 Router，維持現行以 Controller 轉發的做法。
- 只有 App 層可以建立 concrete 型別。其餘各層一律以 protocol 注入。

### 4.3 層次邊界

**不建立 SPM package，也不設頂層 `Domain/`、`Data/` 資料夾。** 層次收在各自的 feature 資料夾底下，**先分 feature、再分層、最後分角色**：

```text
MovieDetail/
  Domain/Entity/  Domain/Repository/  Domain/UseCase/
  Data/DTO/  Data/Mapper/  Data/Repository/
  Presentation/  ViewModel/  Controller/  View/  Router/
TVDetail/     同上
ReviewList/   同上
SeasonDetail/ 同上
EisodeDetail/ 同上（保留既有資料夾拼字）
PersonDetail/  同上
Feature/
  Domain/Entity/  Domain/Error/       跨 feature 共用
  Data/DTO/  Data/Mapper/
Network/                              尚未歸層的基礎設施
```

理由是與專案既有的「一個畫面一個資料夾」慣例一致：打開 `MovieDetail/` 就能看到這個畫面的全部，從 Entity 到 Controller，不必在四個頂層目錄之間跳。同一個領域的 Entity、UseCase、Repository 也自然看得到彼此。

跨 feature 共用的部分放 `Feature/`，沿用專案既有的共用程式碼位置，不另立頂層資料夾。

**共用的判準**：被一個以上的 feature 使用，或本身不屬於任何單一 feature（`CalendarDay`、`Page`、`DomainError`）。只有單一 feature 使用的型別一律歸該 feature，**即使名稱看似通用**。由專屬升格為共用的時機是第二個 feature 開始使用它——`MediaSummary` 與 `MediaDTO` 即是在 TVDetail 分層時由 MovieDetail 專屬升格而來。

**與 SPM package 的關係**：此結構不再與 `Sources/<target>/` 同形。若日後決定拆 package，需要先把各 feature 的 `Domain/` 與 `Data/` 收攏，屬額外工作。這是為了日常可讀性而付出的代價，且 Phase 3 的模組拆分已依決議取消。

**代價必須明講**：資料夾不是編譯期邊界。Domain 裡寫 `import UIKit` 仍會通過編譯。維持邊界只能靠兩件事：

1. 4.2 的依賴規則與 code review。
2. 下列機械檢查，每次動到 Domain 或 Data 後執行：

```bash
grep -rn "^import" --include='*.swift' */Domain/ | grep -v "import Foundation"
grep -rnE "NetworkServic|APIConfig|DTO|UIKit|ErrorMessage" --include='*.swift' */Domain/
grep -rnE "ViewModel|ViewController|UIKit" --include='*.swift' */Data/
rg -n '\b[A-Za-z][A-Za-z0-9]*DTO\b' MovieDetail -g '*.swift' -g '!MovieDetail/Data/**'
```

四項皆須無輸出。`*/Domain/` 會涵蓋每個 feature 的 Domain 與 `Feature/Domain`；第四項以 `MovieDetail` 示範，驗收其他 feature 時需同步替換搜尋路徑與排除路徑，避免尚未分層的 feature 阻擋逐步交付。

### 4.3.1 Presentation 與 App 的位置

Presentation（ViewModel、SectionBuilder、PresentationModels）與 App（Controller、View、Router）**留在原本的 feature 資料夾**，不另建頂層 `Presentation/` 與 `App/`。

理由：3.3 列出的架構缺口是 G1（缺 Entity）、G2（缺 UseCase）、G3（缺 Repository），這三者靠新增 Domain/Data 解決。把既有的 ViewModel 與 Controller 換個資料夾不會修正任何缺口，卻要動到上百個檔案與 `project.pbxproj`，在沒有測試的前提下是純風險。

判斷一個檔案屬於哪一層，看的是它的依賴與職責，不是它的路徑。

### 4.4 執行緒與 actor 規則

沿用專案現行規則，不做變更：

- Domain Entity、UseCase、Repository、Mapper 一律 `nonisolated` 且 `Sendable`。
- UseCase 以 `async throws` 暴露，不標註 `@MainActor`。
- ViewModel 標註 `@MainActor`，以既有 `bind(onStateChange:)` 輸出模式驅動 UI。
- 並行使用 `async let` 與 `withThrowingTaskGroup`，不使用 `DispatchQueue` 或 `@escaping` 回呼。
- 不使用 `@unchecked Sendable` 與 `nonisolated(unsafe)`。

---

## 5. Domain 層規格

### 5.1 命名規約

| 角色 | 規則 | 範例 |
|------|------|------|
| Entity | 名詞，無前綴 | `Movie`、`MovieCredits`、`Review` |
| Repository protocol | `...Providing` | `MovieDetailProviding` |
| Repository 實作 | `...Repository` | `MovieDetailRepository` |
| UseCase protocol | 動詞短語 + `UseCase` | `LoadMovieDetailUseCase` |
| UseCase 實作 | `Default` + protocol 名 | `DefaultLoadMovieDetailUseCase` |

Repository 命名沿用專案既有慣例（`MemberCenterContentProviding` protocol / `MemberCenterContentRepository` 實作）。UseCase 因動詞短語加 `ing` 會產生歧義，改採 `Default` 前綴，此為明確決定而非不一致。

### 5.2 Entity

Entity 由現有 DTO 去除傳輸關注點後取得。以 `MovieDetail` 為例：

```swift
// MARK: - Movie

nonisolated struct Movie: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let genres: [Genre]
    let releaseDate: Date?
    let runtime: Duration?
    let voteAverage: Double
    let voteCount: Int
    let status: MovieStatus
    let homepage: URL?
}
```

與現行 DTO 的差異，即為此層要吸收的責任：

| 現行 DTO | Domain Entity | 轉換責任歸屬 |
|----------|---------------|--------------|
| `Decodable` + `CodingKeys` | 無 | Data 層 DTO |
| `overview: String?` | `overview: String` | Mapper 決定空值語意 |
| `releaseDate: String` | `releaseDate: Date?` | Mapper 解析 |
| `runtime: Int?` | `runtime: Duration?` | Mapper 轉換單位 |
| `status: String` | `status: MovieStatus` | Mapper 映射列舉 |
| `?? "未命名"` fallback | 無 | Mapper 或 Presentation 決定顯示字串 |

在地化顯示文字（如 `"未命名"`）**不得**留在 Entity。Entity 表達「沒有標題」這個事實，由 Presentation 決定要顯示什麼。

### 5.3 Repository protocol

```swift
// MARK: - MovieDetailProviding

nonisolated protocol MovieDetailProviding: Sendable {
    func movie(id: Int) async throws -> Movie
    func credits(movieID: Int) async throws -> MovieCredits
    func videos(movieID: Int) async throws -> [Video]
    func images(movieID: Int) async throws -> MediaImages
    func collection(id: Int) async throws -> MovieCollection
    func recommendations(movieID: Int, page: Int) async throws -> Page<MovieSummary>
    func similar(movieID: Int, page: Int) async throws -> Page<MovieSummary>
    func watchProviders(movieID: Int) async throws -> WatchProviders
}
```

Repository 方法一律採名詞短語（無副作用查詢），符合 Swift API Design Guidelines。分頁統一以泛型 `Page<Element>` 表達，取代現行各自定義的 `MovieRecommendationsPage`、`MovieSimilarPage`、`TVRecommendationsPage` 等型別。

### 5.4 UseCase

UseCase 承接 G2 中由 Service 移出的編排邏輯：

```swift
// MARK: - LoadMovieDetailUseCase

nonisolated protocol LoadMovieDetailUseCase: Sendable {
    func callAsFunction(movieID: Int, recommendationPage: Int) async throws -> MovieDetailContent
}

// MARK: - DefaultLoadMovieDetailUseCase

nonisolated struct DefaultLoadMovieDetailUseCase: LoadMovieDetailUseCase {

    // MARK: - Properties

    private let repository: MovieDetailProviding

    // MARK: - Initialization

    init(repository: MovieDetailProviding) {
        self.repository = repository
    }

    // MARK: - LoadMovieDetailUseCase

    func callAsFunction(
        movieID: Int,
        recommendationPage: Int = 1
    ) async throws -> MovieDetailContent {
        guard movieID > 0 else { throw DomainError.invalidIdentifier }

        async let credits = optional { try await repository.credits(movieID: movieID) }
        async let videos = optional { try await repository.videos(movieID: movieID) }
        async let images = optional { try await repository.images(movieID: movieID) }
        async let recommendations = optional {
            try await repository.recommendations(movieID: movieID, page: recommendationPage)
        }
        async let similar = optional {
            try await repository.similar(movieID: movieID, page: recommendationPage)
        }
        async let watchProviders = optional {
            try await repository.watchProviders(movieID: movieID)
        }

        let movie = try await repository.movie(id: movieID)
        let collection = await loadedCollection(for: movie)

        return await MovieDetailContent(
            movie: movie,
            credits: credits ?? .empty,
            videos: videos ?? [],
            images: images ?? .empty,
            collection: collection,
            recommendations: recommendations ?? .empty(page: recommendationPage),
            similar: similar ?? .empty(page: recommendationPage),
            watchProviders: watchProviders ?? .empty
        )
    }
}
```

「主要資料失敗則整體失敗，輔助資料失敗則降級為空值」這條規則目前隱含在 `MovieDetailService.fetchAuxiliaryContent`，移入 UseCase 後成為此層的顯式契約。

Phase 2 必須抽出的跨 feature UseCase（對應 G5）：

| UseCase | 取代 | 涉及 Repository |
|---------|------|-----------------|
| `ToggleFavoriteUseCase` | `DetailAccountMediaStateController.toggleFavorite` | `AccountProviding`、`SessionProviding` |
| `SubmitRatingUseCase` | `DetailAccountMediaStateController.submitRating` | `AccountProviding`、`SessionProviding` |
| `DeleteRatingUseCase` | `DetailAccountMediaStateController.deleteRating` | `AccountProviding`、`SessionProviding` |
| `LoadAccountMediaStateUseCase` | `DetailAccountMediaStateController.loadAccountMediaState` | `AccountProviding`、`SessionProviding` |

建立 UseCase 的判準：**含條件判斷、跨 Repository 編排，或有降級策略者才建立**。單純轉呼叫 Repository 的操作不建立 UseCase，由 ViewModel 直接依賴 Repository protocol。

### 5.5 DomainError 與錯誤邊界

`DomainError` 只承載**領域自己判定的失敗**，不重新表述傳輸層錯誤：

```swift
// MARK: - DomainError

nonisolated enum DomainError: Error, Equatable {
    case invalidIdentifier(MediaKind)
}
```

隨各 feature 遷移逐步加入新 case（例如 `requiresUserLogin`）。Domain 不持有任何顯示字串，文案由 Presentation 的 `DomainError: ErrorMessageConvertible` 提供。

**傳輸層錯誤不經 Domain 重新包裝。** Swift 的 `throws` 預設不具型，因此 Repository 拋出的 `NetworkError` 可以直接穿過 UseCase 到達 Presentation，而 Domain 的原始碼**完全不需要提及 `NetworkError`**——沒有 import、沒有型別引用，就沒有編譯期依賴，4.2 的規則仍然成立。

這是一個刻意的取捨，理由與代價如下：

| | 內容 |
|---|---|
| 替代方案 | 在 Domain 定義 `TransportFailure` 列舉，由 Repository 把 `NetworkError` 映射過去，Presentation 再映射成 `ErrorMessage` |
| 不採用的原因 | 現行 `NetworkError+ErrorMessage.swift` 有 191 行、涵蓋 HTTP 狀態碼、TMDB API code、`URLError.Code` 的細緻文案。重新表述一次等於複製這 191 行，且任一邊漏改就造成錯誤 UI 退化 |
| 代價 | Domain 的錯誤契約不精確：從簽章看不出 UseCase 可能拋出哪些非領域錯誤 |
| 收斂路徑 | 改用 typed throws（`throws(DomainError)`），屆時必須同時提供 `TransportFailure` 與其文案映射。這是獨立工作，不隨個別 feature 進行 |

見 13 節 R11。

### 5.6 什麼該進 Domain

新增 Domain 型別前先套用下列判準，避免把 Presentation 或 Data 的關注點誤放進來。

**應進 Domain：**

- 條件判斷與有效性規則（`mediaID > 0`、未登入不可寫入收藏）
- 跨 Repository 的編排與降級策略（主要資料失敗即失敗、輔助資料失敗則降級）
- 集合運算規則（篩選、排序、分頁去重、上限截斷）
- 領域述詞（`Review.isRated`、`Page.hasNextPage`）

**不進 Domain：**

| 關注點 | 正確位置 | 例 |
|---|---|---|
| 顯示文字、在地化 | Presentation | `ReviewFilter.title`、`MediaKind.displayName` |
| 數值與日期的顯示格式 | Presentation | `BaseDisplayTextFormatter.displayDate(from:)` |
| JSON 欄位名、wire format 解析 | Data | `ISO8601DateParsing`、`CodingKeys` |
| 多個 API 欄位擇一 | Data Mapper | 作者名稱取 `name` → `username` → `author` |
| 字串 trimming、空值語意 | Data Mapper | `content.trimmingCharacters(in:)` |
| 圖片 URL 組裝 | Presentation | `APIConfig.tmdbImageURL` |

**UseCase 的建立判準**（同 5.4）：只有含條件、編排或降級策略者才建立 UseCase。單純轉呼叫 Repository 不建立。純粹的集合運算若不需要注入替身，可以是 Entity 的擴充而非 UseCase——ReviewList 的分頁去重即實作為 `[Review].appending(uniqueReviewsFrom:)`。

---

## 6. Data 層規格

### 6.1 DTO

現行 `Model/` 目錄下的 `Decodable` 型別整體移入 Data 層，型別名加 `DTO` 後綴以與 Entity 區分：

| 現行 | 遷移後 |
|------|--------|
| `MovieDetail`（Decodable） | `MovieDetailDTO` |
| `MovieCreditsResponse` | `MovieCreditsDTO` |
| `TVDetail` | `TVDetailDTO` |

DTO 的 access level 在 Phase 3 收為 package 內可見，確保無法外洩。

### 6.2 Mapper

```swift
// MARK: - MovieDetailDTO Mapping

extension MovieDetailDTO {

    func mapped() -> Movie {
        Movie(
            id: id,
            title: title ?? "",
            originalTitle: originalTitle ?? title ?? "",
            tagline: tagline ?? "",
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            genres: genres.map { $0.mapped() },
            releaseDate: DateFormatter.tmdbDate.date(from: releaseDate ?? ""),
            runtime: runtime.map { .seconds($0 * 60) },
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            status: MovieStatus(rawValue: status ?? "") ?? .unknown,
            homepage: homepage.flatMap(URL.init(string:))
        )
    }
}
```

Mapper 一律為無副作用的 `mapped()` 名詞短語方法，符合命名規約。

搬移 DTO 的 decode fallback 時需注意：現行 fallback 同時混合了「資料缺失」與「顯示文案」兩種語意（例如 `?? "未命名"`）。Mapper 只負責前者，後者一律移至 Presentation，見 13 節 R3。

**Mapper 承擔的四類工作**（ReviewList 試點歸納）：

1. **型別轉換**：wire format 字串轉為語意型別。ISO8601 字串 → `Date?`、分鐘數 → `Duration?`、狀態字串 → 列舉。
2. **欄位擇一**：多個 API 欄位表達同一概念時的優先序。例如作者名稱取 `authorDetails.name` → `authorDetails.username` → `author`。
3. **正規化**：trimming、空字串轉 nil。
4. **結構攤平**：DTO 的巢狀結構若對領域無意義則攤平。例如 `ReviewDTO.authorDetails.rating` → `Review.rating`。

**Entity 持有已解析的型別，不是字串。** 這是分層的實質收益之一：`Review.updatedAt` 是 `Date?`，排序時直接比較；遷移前每次排序都要重新解析 ISO8601 字串。若 Entity 仍持有字串，等於把 Data 的工作推給 Domain 和 Presentation 反覆執行。

**解析工具屬於 Data。** wire-format 解析器（如 `ISO8601DateParsing`）放在 `Data/Mapper/`，不得借用 Presentation 的格式化工具——`BaseDisplayTextFormatter` 是顯示用途，Data 引用它會反向跨層。

### 6.3 Repository 實作

```swift
// MARK: - MovieDetailRepository

nonisolated final class MovieDetailRepository: MovieDetailProviding {

    // MARK: - Properties

    private let network: NetworkServicing
    private let localization: AppLocalization

    // MARK: - Initialization

    init(network: NetworkServicing, localization: AppLocalization) {
        self.network = network
        self.localization = localization
    }

    // MARK: - MovieDetailProviding

    func movie(id: Int) async throws -> Movie {
        let dto: MovieDetailDTO = try await network.get(
            path: APIConfig.Movie.detail(id: id),
            queryItems: localization.queryItems
        )
        return dto.mapped()
    }
}
```

現行 22 個 Service 依此模式改寫為 Repository。`NetworkService`、`APIConfig`、`AppLocalization`、`NetworkError`、`SessionStore`、`UserProfileStore`、`SearchHistoryStore` 一併歸入 Data 層。

注意 `init` 不再提供 concrete 預設值——這是 G4 的修正點。

---

## 7. Presentation 層規格

### 7.1 ViewModel

ViewModel 保留現行的 state enum + `bind` 輸出模式，僅更換依賴型別：

```swift
// MARK: - MovieDetailViewModel

@MainActor
final class MovieDetailViewModel {

    // MARK: - Properties

    private(set) var state: MovieDetailViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (MovieDetailViewState) -> Void)?
    private let loadMovieDetail: LoadMovieDetailUseCase
    private let toggleFavorite: ToggleFavoriteUseCase
    private let submitRating: SubmitRatingUseCase
    private let deleteRating: DeleteRatingUseCase

    // MARK: - Initialization

    init(
        loadMovieDetail: LoadMovieDetailUseCase,
        toggleFavorite: ToggleFavoriteUseCase,
        submitRating: SubmitRatingUseCase,
        deleteRating: DeleteRatingUseCase
    ) {
        self.loadMovieDetail = loadMovieDetail
        self.toggleFavorite = toggleFavorite
        self.submitRating = submitRating
        self.deleteRating = deleteRating
    }
}
```

`convenience init()` 一律刪除。所有建構改由 composition root 負責。

### 7.2 SectionBuilder

8 個 `SectionBuilder` / `PresentationBuilder` 的**位置不變、責任不變**，僅將輸入由 DTO 改為 Domain Entity：

```swift
static func makeSections(
    content: MovieDetailContent,
    localization: AppLocalization
) -> [MovieDetailSectionItem]
```

這些是遷移中改動面最小的一層，可作為各 feature 遷移的最後一步。

### 7.3 ErrorMessage 映射

`DomainError → ErrorMessage` 的映射與在地化文案置於 Presentation 層，取代現行 `NetworkError+ErrorMessage.swift` 的位置。DTO fallback 中屬於顯示語意的預設文案（如 `"未命名"`）一併集中至此。

---

## 8. App 層規格

### 8.1 Composition Root

```swift
// MARK: - AppDependencies

@MainActor
final class AppDependencies {

    // MARK: - Properties

    private let network: NetworkServicing
    private let sessionStore: SessionStoring

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        sessionStore: SessionStoring = SessionStore()
    ) {
        self.network = network
        self.sessionStore = sessionStore
    }

    // MARK: - Factories

    func makeMovieDetailViewModel() -> MovieDetailViewModel {
        let repository = MovieDetailRepository(
            network: network,
            localization: .current
        )
        return MovieDetailViewModel(
            loadMovieDetail: DefaultLoadMovieDetailUseCase(repository: repository),
            toggleFavorite: makeToggleFavoriteUseCase(),
            submitRating: makeSubmitRatingUseCase(),
            deleteRating: makeDeleteRatingUseCase()
        )
    }
}
```

`AppDependencies` 是全專案**唯一**允許出現 concrete 依賴預設值的位置。

由 `SceneDelegate` 建立單一實例並向下傳遞。不引入第三方 DI 容器，不使用 service locator，不使用全域單例。

### 8.2 Router

`BaseRouter`、`DetailRouter` 及各 feature Router 維持現狀，歸屬 App 層。Router 需要建立下一個畫面的 ViewModel 時，透過持有的 `AppDependencies` 取得。

### 8.3 位置修正

| 檔案 | 現況 | 遷移後 |
|------|------|--------|
| `MainLogIn/Service/AppRootFactory.swift` | Service 層但 import UIKit | App 層 |
| `MainTabBar/Service/MainTabBarAvatarService.swift` | Service 層但 import UIKit | 拆為 Data 層取資料 + App 層產生 UIImage |

---

## 9. MediaKind 統一規格

本節對應 G6，是 Phase 1 的核心，且**必須早於任何分層工作完成**。

### 9.1 MediaKind

```swift
// MARK: - MediaKind

nonisolated enum MediaKind: String, Sendable, Codable, CaseIterable {
    case movie
    case tv
}
```

`MediaKind` 屬於領域概念，位於 `Domain/Entity/MediaKind.swift`。其顯示文字與圖示（`displayName`、`systemImageName`）屬 Presentation，置於 `Feature/Media/MediaKind+Presentation.swift`。

**本節初版有誤。** 初版列出 5 個「應被取代」的列舉，實際盤點後只有 2 個是純二元 movie/tv：

| 型別 | 判定 | 處置 |
|------|------|------|
| `MemberCenterAccountMediaType` | 純二元 | **已取代** |
| `MainHomeMediaType` | 純二元 | **已取代** |
| `PersonCreditMediaType` | 含 `unknown(String)` 關聯值，保留 API 未知原始值 | 保留，非 MediaKind |
| `MainSearchMediaType` | 含 `person`、`unknown`，涵蓋非影音結果 | 保留，非 MediaKind |
| `SearchHistoryScope` | 含 `multi`，表達搜尋範圍而非媒體種類，且已持久化於本地 | 保留，非 MediaKind |

判準：只有**恰好為 movie 與 tv 兩個 case** 的列舉才是 `MediaKind`。多一個 case 就代表它表達的是另一個概念，強行合併會扭曲模型，且 `SearchHistoryScope` 這類已持久化的型別改變形狀還會破壞既有存檔。

### 9.2 合併範圍與順序

**本節初版把合併對象切成四個獨立群組，這是錯的。** 實作時發現群組之間存在型別耦合，必須先統一共用型別才能各自合併。實際執行順序與結果：

| 順序 | 內容 | 結果 |
|------|------|------|
| 1 | `ReviewList/Movie` + `ReviewList/TV` **與** `PageSheet/ReviewDetail` | 20 檔 3,499 行 → 10 檔 1,765 行（−1,734） |
| 2 | 統一 grid 型別為 `MediaGridEntry` / `MediaGridItem` / `MediaSortOption` | 34 檔，−664 +231 |
| 3 | `MovieSearch` + `TVSearch` | 12 檔 1,454 行 → 7 檔 815 行（−639） |
| 4 | `MainMovieList` + `MainTVList` 與兩個 genre page sheet | 16 檔 2,686 行 → 8 檔 1,415 行（−1,271） |

**兩處耦合是初版沒看出來的：**

- 評論列表與評論詳情透過 item 型別耦合（Router 直接推出 ReviewDetail page sheet），拆開提交需要一次性 shim，故合併為同一 commit。
- 搜尋與主列表透過 grid 型別耦合：`MovieGridMovieItem` / `MovieSortOption` 同時被 `MovieSearch` 與 `MainMovieList` 使用，TV 側亦然。且 Movie 的 grid 型別在共用的 `Feature/Components/MovieGrid`，TV 的卻在 `Main/MainTVList/Model`，對稱性本來就不一致。必須先做順序 2 的型別統一，順序 3 與 4 才能各自獨立建置與回退。

**教訓**：規劃合併順序前，先確認各組**沒有共用型別**。有共用型別就必須先統一型別，再分別合併。

`PageSheet/Genre` 原本不列入合併範圍（兩個 controller 各僅 37 行，已透過 `BaseGenrePageSheetViewController` 共用），但順序 4 統一 genre item 型別後兩者只剩標題不同，順勢合併為一個。

**`MovieDetail` ↔ `TVDetail`（9 組平行檔）決定不合併。** `TVDetailModels.swift` 1,035 行 vs `MovieDetailModels.swift` 686 行，TV 多出 season / episode 概念，合併成本高於收益。依本節授權保留，並以共用的 `MediaKind` 與 Domain Entity 承接共通部分。

### 9.3 合併手段

- 業務差異以 `MediaKind` 參數表達，不以泛型過度抽象。
- 文案差異（`"電影 ID 不正確"` vs `"影集 ID 不正確"`）集中為 `MediaKind` 的 Presentation 擴充。
- API 路徑差異集中於 `APIConfig`，以 `MediaKind` 選擇 endpoint。
- Cell 與 View 若版面完全相同則合併；若版面不同則保留兩個 View，**但共用同一個 ViewModel 與 Repository**。

### 9.4 合併作業程序

每組合併採固定程序，確保行為可對照：

1. 以 Movie / TV token 正規化後執行 `diff`，產出差異清單。
2. 逐項判定每處差異屬於「文案」「參數名」「真實業務差異」何者，記錄於該次 commit 訊息。
3. 僅有第三類差異需要以 `MediaKind` 分支表達；前兩類直接合併。
4. 合併後對 movie 與 tv 兩條路徑各走查一次（見 12.1）。
5. 一組一個 commit，不跨組混合。

---

## 10. 依賴注入規格

### 10.1 必須移除的模式

| 模式 | 數量 | 處置 |
|------|------|------|
| `convenience init()` 內建立完整依賴 | 4 | 刪除，改由 `AppDependencies` 建構 |
| `network: NetworkServicing = NetworkService()` | 17 | 移除預設值，改為必填參數 |
| 其他 concrete dependency 預設參數 | Phase 3 開始前重盤 | 移除預設值，改為必填參數；值型別行為預設不計入 |
| Controller 內 `self.viewModel = XxxViewModel()` | 多處 | 改為 init 注入 |

### 10.2 允許保留的預設值

- `AppDependencies.init` 的 `network` 與 `sessionStore`（唯一 composition root）。
- 值型別的行為預設值，例如 `recommendationPage: Int = 1`、`localization: AppLocalization = .current`。此類為參數預設而非依賴預設。

### 10.3 UIViewController 注入模式

```swift
// MARK: - Initialization

init(viewModel: MovieDetailViewModel, movieID: Int) {
    self.viewModel = viewModel
    self.movieID = movieID
    super.init(nibName: nil, bundle: nil)
}
```

移除現行 `init(viewModel: XxxViewModel = XxxViewModel())` 形式的預設參數。

### 10.4 composition root 不隨個別 feature 進行

**依賴反轉是跨全專案的單一步驟，不可拆進各 feature 的分層工作。**

理由：`AppDependencies` 的價值在於成為唯一的組裝點。若隨 feature 逐步導入，過渡期會同時存在兩種注入方式（部分走 composition root、部分走預設參數），組裝點不唯一，等於沒有 composition root，卻已付出改動成本。

因此分層工作（Domain / Data）與依賴反轉（10.1–10.3）分開執行：

- 分層期間，ViewModel 仍以既有的預設參數注入 UseCase，例如
  `init(mediaKind:loadReviewsUseCase: LoadReviewsUseCase = DefaultLoadReviewsUseCase(repository: ReviewRepository()))`。
- 待需要分層的 feature 都完成後，再一次性建立 `AppDependencies` 並移除全部預設值。

這也是 3.1 中依賴注入四列在分層試點後未變動的原因，屬預期結果而非遺漏。

---

## 11. 分階段交付計畫

**計畫順序在 v1.2 調整。** 原 Phase 2（依賴反轉 + UseCase）與 Phase 3（Entity/DTO + 模組拆分）混合了兩件性質不同的工作。實作後拆為：分層（可逐 feature 進行）與依賴反轉（必須一次到位，見 10.4）。模組拆分已依決議取消。

### Phase 1：消除 Movie / TV 重複 — 已完成

**目的**：在增加層數之前先降低重複基數（G6）。

實際交付（6 個 commit）：

- 建立 `MediaKind`，取代 2 個純二元列舉（初版預期 5 個，更正見 9.1）。
- 依 9.2 實際順序完成四組合併。
- 走查發現並修正一個迴歸：合併後的主列表共用同一 controller，搜尋的 `mediaKind` 寫死為 `.movie`，導致影集分頁回傳電影結果。

結果：243 檔 47,616 行 → 222 檔 43,846 行，平行檔案組 31 → 9。

### Phase 2：分層（Domain / Data）

**目的**：處理 G1、G2、G3。

**逐 feature 進行**，每個 feature 一個 commit，每個 commit 結束時專案可編譯、可執行、可走查。

單一 feature 的作業程序：

1. 由 DTO 萃取 Entity，依 6.2 的四類工作撰寫 Mapper。
2. 定義 Repository protocol（Domain）與實作（Data），取代原 Service。
3. 依 5.6 判準把業務規則由 ViewModel 移入 UseCase 或 Entity 擴充。
4. ViewModel 改依賴 UseCase protocol，暫時保留預設參數注入（見 10.4）。
5. 執行 4.3 的四項機械邊界檢查，皆須無輸出。
6. 執行 12.1 走查，兩種 `MediaKind` 各走一次。

進度：

| Feature | 狀態 |
|---------|------|
| `ReviewList` | **已完成**，作為模式範本（`1ffc566`） |
| `MovieDetail` | **已完成**，抽出 `LoadMovieDetailUseCase`（`d00ec9a`） |
| `TVDetail` | **已完成**，並將跨 Movie / TV 共用型別升格至 `Feature/`（`4db4120`） |
| `SeasonDetail` | **已完成**；DTO 外洩與舊 Service 已移除，靜態檢查、build 與手動走查通過 |
| `EpisodeDetail` | **已完成**；DTO 外洩與舊 Service 已移除，靜態檢查通過，手動審查由開發者完成 |
| `PersonDetail` | **已完成**；DTO 外洩與舊 Service 已移除，靜態檢查通過，手動審查由開發者完成 |
| `MainMediaList` | **已完成**（`d103977`）；LoadMediaListUseCase 承接「取類型清單→決定初始類型→取第一頁」的編排 |
| `Search` | **已完成**（`d103977`，與 MainMediaList 同一 commit，兩者透過 MediaGrid 型別耦合）；客戶端排序移入 SortMediaUseCase |
| `HomeSectionList` | **已完成**（`d8c1940`）；`FilterMediaByGenreUseCase` 承接類型篩選，`HomeSectionListGenre` 因與 `MediaGenre` 完全重複而刪除 |
| `MainHome` | **已完成**（`d8c1940`，與 HomeSectionList 同一 commit，兩者透過 5 個 `MainHomeContent*` 型別耦合）；`LoadHomeSectionsUseCase` 承接併發載入與部分失敗處理 |
| `MemberCenter` | **已完成**；帳號 Entity、DTO / Mapper、Repository 與 2 個 UseCase 已分層，舊 Service 與重複 Model / Repository 已移除；靜態檢查與 build 通過，手動走查待完成 |

以本表 11 個 feature 為計數口徑，目前完成分層實作 11 個（100%）。此比例只表示 feature 數量，不代表 Phase 3 或全專案所有既有功能也已完成依賴反轉。

**不必全部做完。** 每個 feature 分層後即獨立產生價值；未分層的 feature 維持現狀不受影響。

**獨立價值：有。** 業務規則脫離 UI 生命週期，Entity 持有已解析型別避免重複解析。

### Phase 3：依賴反轉（composition root）

**目的**：處理 G4、G5。

目前進度：G5 的 4 個跨 feature UseCase 已完成並通過 build；G4 的 `AppDependencies` 與全專案 concrete 預設值清理尚未開始。

交付：

- 建立 `AppDependencies` composition root。
- 移除 4 處 `convenience init()`、17 處 network 預設值，以及 Phase 3 開始前重新盤點的其他 concrete dependency 預設值。
- 由 `DetailAccountMediaStateController` 抽出 4 個跨 feature UseCase（G5）。
- 依 feature 分批提交，每批結束時專案可編譯、可執行。

**進入條件**：需要依賴反轉的 feature 都已完成 Phase 2 分層。理由見 10.4——過渡期若同時存在兩種注入方式，組裝點不唯一，等於沒有 composition root。

**獨立價值：有。** 完成後抽換任一實作的成本不再與呼叫端數量成正比。

### 已取消：模組拆分

原 Phase 3 包含建立 `Packages/CineBaseCore` 並拆為三個 SPM target。**依決議取消**，層次改以資料夾表達（見 4.3）。

代價是沒有編譯期邊界強制，改以 4.3 的機械檢查與 code review 維持。若日後情境改變（團隊增員、需要第二個 app target、需要抽換資料來源），4.3 的層次優先佈局可讓拆 package 成為單純的檔案搬移。

## 12. 驗收標準

本專案不採用自動化測試，因此各 Phase 的驗收以**靜態檢查**與**手動走查**兩類條件構成。

### 12.1 共通迴歸走查

每個 Phase 結束、Phase 1 每完成一組合併、Phase 2 每完成一個 feature 時執行：

- [ ] `xcodebuild build` 成功且無新增警告。
- [ ] 首頁、電影列表、影集列表可載入並捲動。
- [ ] 電影詳情、影集詳情、季詳情、集詳情、人物詳情可開啟，各 section 顯示正確。
- [ ] 搜尋（電影 / 影集 / 綜合）可輸入、可送出、可開啟結果。
- [ ] 評論列表可載入、可分頁、可開啟評論詳情。
- [ ] 會員中心可載入，登入 / 登出流程正常。
- [ ] 收藏與評分可成功寫入，未登入時顯示需登入訊息。
- [ ] 4 個公開 App Intents shortcut 可正常觸發。

Phase 1 的合併項目與 Phase 2 的分層項目，皆需在 **movie 與 tv 兩條路徑各走查一次**。

### 12.2 Phase 1 — 已通過

- [x] `MediaKind` 存在，2 個純二元舊列舉已刪除（更正見 9.1）。
- [x] Movie / TV 平行檔案組數 9，低於 20（Detail 決定不合併）。
- [x] 專案總行數減少 3,770 行，達 3,000 行門檻。
- [x] 每組合併的 commit 訊息記載了 9.4 第 2 步的差異判定結果。
- [x] 12.1 走查通過，並於走查中發現並修正一個迴歸。

### 12.3 Phase 2（每個 feature 各自驗收）

- [ ] 該 feature 的 Service 已由 Domain 的 Repository protocol + Data 的實作取代。
- [ ] 該 feature 的 DTO 位於 `<feature>/Data/DTO`，Entity 位於 `<feature>/Domain/Entity`，且 Entity 無 `Decodable` / `Encodable` conformance。
- [ ] 業務規則已依 5.6 判準移出 ViewModel。
- [ ] 4.3 的四項機械邊界檢查皆無輸出：

```bash
grep -rn "^import" --include='*.swift' */Domain/ | grep -v "import Foundation"
grep -rnE "NetworkServic|APIConfig|DTO|UIKit|ErrorMessage" --include='*.swift' */Domain/
grep -rnE "ViewModel|ViewController|UIKit" --include='*.swift' */Data/
rg -n '\b[A-Za-z][A-Za-z0-9]*DTO\b' MovieDetail -g '*.swift' -g '!MovieDetail/Data/**'
```

- [ ] 該 feature 的 12.1 相關項目在 movie 與 tv 兩條路徑各走查通過。

### 12.4 Phase 3

- [ ] `AppDependencies` 存在，且為專案中唯一含 concrete 依賴預設值的型別。
- [ ] 全專案 `grep "convenience init()"` 結果為 0。
- [ ] 全專案 `grep "= NetworkService()"` 結果為 1（僅 `AppDependencies`）。
- [ ] 全專案無 `UseCase = Default...UseCase(...)` 形式的預設參數。
- [x] `DetailAccountMediaStateController` 已由 4 個 UseCase 取代業務編排，縮減為畫面狀態協調器。
- [ ] 未登入 / guest 路徑不會寫入收藏（以走查確認）。
- [ ] 12.1 走查全數通過。

---

## 13. 風險與緩解

| 編號 | 風險 | 影響 | 緩解 |
|------|------|------|------|
| R1 | Phase 1 合併 Detail 時 movie / tv 行為差異被抹平 | 功能退化且不易察覺 | Detail 合併為選擇性項目；合併前依 9.4 逐項判定差異類別，不得整批套用 |
| R2 | 無自動化測試，重構迴歸只能靠人工 | Phase 1 涉及約 3,800 行變更，人工走查可能漏掉邊界情境 | 一組一個 commit 以便精準回退；每組合併後立即執行 12.1 走查；不同時進行兩組合併。此為本計畫已知的最大弱點，若日後改變測試策略應優先補上 Phase 1 合併範圍的覆蓋 |
| R3 | Mapper 吃掉 DTO 的 decode fallback 導致顯示文案改變 | UI 出現空字串 | 搬移前先列出所有含顯示語意的 fallback（如 `?? "未命名"`），明確移至 Presentation 而非刪除 |
| R4 | 移除 49 處預設參數造成大範圍修改 | 單次 commit 過大、難以 review | 依 feature 分批，每批一個 commit，每批結束可編譯 |
| R5 | 新增檔案漏加入 target | 編譯期未報錯但執行期缺功能 | 專案採顯式檔案參照（見 3.1）；每次新增檔案後確認 target membership，或評估將各 feature 資料夾改為 `PBXFileSystemSynchronizedRootGroup` |
| R6 | Entity 與 DTO 雙軌並存期間認知負擔 | 開發者誤用 DTO | DTO 一律加 `DTO` 後綴；Phase 3 後以 access level 封閉 |
| R7 | 過度抽象：為每個 Repository 方法造一個 UseCase | 產生大量單行轉呼叫類別 | 套用 5.4 的判準：只有含條件、編排或降級策略者才建立 UseCase |
| R8 | 無編譯期層次邊界 | 資料夾不擋違規 import，Domain 可能悄悄依賴 Data 或 UIKit，DTO 也可能外洩至其他層 | 每次動到 Domain 或 Data 後執行 4.3 的四項機械檢查；新增 feature 時一併執行 |
| R9 | App Intents 依賴既有 service，遷移時斷裂 | Siri / Shortcuts 失效 | `Feature/AppIntents` 改為依賴 UseCase；每 Phase 執行 12.1 的 Intents 走查項目 |
| R10 | 遷移期間 TMDB API 變更 | 同時處理重構與外部變更 | 每個 Phase 控制在可於短期內完結的範圍，不長期開分支 |
| R11 | Domain 的 throws 不具型 | 從 UseCase 簽章看不出可能拋出哪些非領域錯誤，呼叫端只能概括處理 | 已知取捨，理由見 5.5。收斂路徑為 typed throws，需同時提供 `TransportFailure` 與其文案映射，屬獨立工作 |
| R12 | 分層期間兩種架構並存 | 已分層與未分層的 feature 寫法不同，易誤用 | 分層以 feature 為單位一次做完，不留半分層狀態；`ReviewList` 作為模式範本供對照 |
| R13 | 規劃合併或分層順序時漏看型別耦合 | 拆成多個 commit 後無法各自建置，被迫回頭合併 | 動工前先確認各組**沒有共用型別**；有共用型別就先統一型別再分別處理（9.2 的教訓） |

---

## 14. 維護規則

- 新增 feature 時，依 4.2 的依賴規則配置檔案；不得在 Presentation 層 import Data。
- 新增業務規則時，先套用 5.6 判準：顯示文案進 Presentation、wire format 進 Data Mapper、條件與編排進 Domain。
- 新增 UseCase 前先確認它含條件、編排或降級策略；純集合運算改為 Entity 擴充。
- 新增依賴時，於 `AppDependencies` 註冊（Phase 3 完成後）；在此之前沿用預設參數注入，但不得於 ViewModel 或 Controller 內組裝多層依賴。
- 新增 Domain 型別時，確認未 conform `Decodable` / `Encodable`，且只 import Foundation。
- **每次動到 `Domain/` 或 `Data/` 後，執行 4.3 的四項機械檢查**，四項皆須無輸出。
- Entity 一律持有已解析的型別（`Date?`、`URL?`、列舉），不持有 wire format 字串。
- 新增 Movie / TV 相關功能時，一律使用 `MediaKind`，不得新增第 6 個媒體型別列舉。
- 新增任何 Swift 檔後，確認已加入 target（見 R5）。
- 每完成一個 Phase，更新本文件 3.1 的量化現況與 16 節修訂紀錄。
- 每季複審一次 Phase 3 的進入條件。

---

## 15. 參考程式路徑

### 15.1 分層模式範本（ReviewList）

照抄這一組就能推廣到其他 feature。

| 角色 | 路徑 |
|------|------|
| Entity | `ReviewList/Domain/Entity/Review.swift`、`Feature/Domain/Entity/Page.swift`、`ReviewList/Domain/Entity/ReviewFilter.swift` |
| Entity 擴充承載集合規則 | `ReviewList/Domain/Entity/Review.swift` 的 `[Review].appending(uniqueReviewsFrom:)` |
| 領域錯誤 | `Feature/Domain/Error/DomainError.swift` |
| Repository protocol | `ReviewList/Domain/Repository/ReviewProviding.swift` |
| UseCase（含條件） | `ReviewList/Domain/UseCase/LoadReviewsUseCase.swift` |
| UseCase（集合規則） | `ReviewList/Domain/UseCase/FilterReviewsUseCase.swift` |
| DTO | `ReviewList/Data/DTO/ReviewDTO.swift` |
| Mapper | `ReviewList/Data/Mapper/ReviewDTO+Mapping.swift` |
| wire-format 解析 | `Feature/Data/Mapper/ISO8601DateParsing.swift` |
| Repository 實作 | `ReviewList/Data/Repository/ReviewRepository.swift` |
| Presentation 模型與文案 | `ReviewList/Presentation/ReviewPresentationModels.swift` |
| ViewModel（依賴 UseCase） | `ReviewList/ViewModel/ReviewListViewModel.swift` |

### 15.2 其他路徑

| 用途 | 路徑 |
|------|------|
| 網路層（尚未歸入 Data 資料夾） | `Network/NetworkService.swift`、`Network/APIConfig.swift`、`Network/NetworkError.swift`、`Network/AppLocalization.swift` |
| 既有 Repository（Phase 2 時併入 Data） | `MemberCenter/Repository/MemberCenterContentRepository.swift`、`MemberCenter/List/Repository/MemberCenterListContentRepository.swift` |
| 跨 feature 共用的 Domain / Data | `Feature/Domain/Entity/`、`Feature/Domain/Repository/MediaGenreProviding.swift`、`Feature/Data/DTO/`、`Feature/Data/Mapper/`、`Feature/Data/Repository/MediaGenreRepository.swift` |
| 已完成的詳情編排 UseCase | `MovieDetail/Domain/UseCase/LoadMovieDetailUseCase.swift`、`TVDetail/Domain/UseCase/LoadTVDetailUseCase.swift`、`SeasonDetail/Domain/UseCase/LoadSeasonDetailUseCase.swift`、`EisodeDetail/Domain/UseCase/LoadEpisodeDetailUseCase.swift`、`PersonDetail/Domain/UseCase/LoadPersonDetailUseCase.swift`、`PersonDetail/Domain/UseCase/LoadPersonCreditsUseCase.swift` |
| 下一個 DTO / Entity 分離位置 | `MemberCenter/Model/MemberCenterAccountModels.swift`、`MemberCenter/List/Model/MemberCenterListModels.swift`、`MemberCenter/ViewModel/Builder/MemberCenterPresentationBuilder.swift`（三者直接使用 `MediaSummaryDTO`） |
| UseCase 抽取來源（跨 feature） | `Feature/Base/DetailBase/ViewModel/DetailAccountMediaStateController.swift` |
| 待移除的 convenience init | `MovieDetail/ViewModel/MovieDetailViewModel.swift`、`TVDetail/ViewModel/TVDetailViewModel.swift`、`SeasonDetail/ViewModel/SeasonDetailViewModel.swift`、`PersonDetail/ViewModel/PersonDetailViewModel.swift` |
| 保留、非 MediaKind 的媒體型別 | `PersonDetail/Domain/Entity/PersonCredits.swift`、`Main/MainSearch/Model/MainSearchModels.swift`、`Feature/SearchHistory/Model/SearchHistoryModels.swift` |
| 去重完成的參考樣板 | `PageSheet/Genre/Base/BaseGenrePageSheetViewController.swift` |
| 顯示語意 fallback 集中處 | `Feature/Formatter/BaseDisplayTextFormatter.swift`、`Feature/Components/ErrorMessage/Model/NetworkError+ErrorMessage.swift` |
| 待搬移的 UIKit 汙染 | `MainLogIn/Service/AppRootFactory.swift`、`MainTabBar/Service/MainTabBarAvatarService.swift` |
| App Intents 相依面 | `Feature/AppIntents/Support/AppIntentFavoriteActionHandler.swift`、`Feature/AppIntents/Support/AppIntentSessionResolver.swift` |
| 相關文件 | `Docs/SDD-Apple-Intelligence-Siri-AppIntents.md` |

---

## 16. 修訂紀錄

| 版本 | 日期 | 說明 |
|------|------|------|
| 2.2 | 2026-09-13 | 完成 MemberCenter 的 Domain / Data / UseCase 分層，Phase 2 達 11 / 11；刪除舊 Service、重複 Model 與 Repository。開始 Phase 3：新增 `AccountSessionProviding` / `AccountSessionRepository` 與 `LoadAccountMediaStateUseCase`、`ToggleFavoriteUseCase`、`SubmitRatingUseCase`、`DeleteRatingUseCase`，MovieDetail、TVDetail、EpisodeDetail 與 App Intent 收藏改走共用 UseCase，`DetailAccountMediaStateController` 僅保留畫面狀態協調。靜態邊界檢查與 simulator Debug build 通過；composition root 尚待實作 |
| 2.1 | 2026-09-13 | 完成 HomeSectionList 與 MainHome 分層（同一 commit，兩者透過 5 個 `MainHomeContent*` 型別耦合）。去重：`MainHomeContent` 與 `MediaSummaryDTO` 欄位完全重疊而刪除；`HomeSectionListGenre` 與 `MediaGenre` 相同、且 `init(movieGenre:)` 與 `init(tvGenre:)` 實作一模一樣而刪除；取類型的網路呼叫抽成共用 `MediaGenreProviding` / `MediaGenreRepository`；`TMDBPageResponse` 由 `MainHome/Model` 移至 `Feature/Data/DTO`。命名統一為 `HomeCategory` / `HomeContentItem`。行為差異一處：全部分類載入失敗時改拋底層錯誤而非預先包成 `ErrorMessage`，以符合 4.3 的 Domain 邊界。Phase 2 進度 10 / 11，僅剩 MemberCenter |
| 2.0 | 2026-09-13 | 完成 MainMediaList 與 Search 分層（同一 commit，兩者透過 MediaGrid 型別耦合）。共用型別下沉：刪除與 `MediaSummaryDTO` 重疊的 `MediaGridEntry`；`MediaSummary` 補 overview / backdropPath / popularity；`MediaSortOption` 依關注點拆為 Domain 的 `MediaSortOrder`、Presentation 的 title、Data 的 `discoverSortValue`，排序規則移入 Search 的 `SortMediaUseCase`；`MediaGenre` 升格至 `Feature/`。分層後才看清兩個排序是不同機制：MainMediaList 伺服器端、Search 客戶端 |
| 1.9 | 2026-09-13 | EpisodeDetail 與 PersonDetail 的手動審查已由開發者完成，兩者狀態由「待 build 與手動走查」改為已完成。Phase 2 進度 6 / 11，下一批依序為 MainMediaList、Search、HomeSectionList、MainHome、MemberCenter |
| 1.8 | 2026-09-13 | 完成 PersonDetail 的 Domain / Data / UseCase 分層實作：將人物 ID 驗證、電影／劇集作品路由、主要與輔助資料載入降級移入兩個 UseCase；新增 Person Entity、Repository、DTO / Mapper 與領域錯誤，將日期與 URL wire format 解析移至 Mapper，移除舊 Model / Service。Phase 2 進度更新為 6 / 11；靜態檢查通過，build 與手動走查仍待執行 |
| 1.7 | 2026-09-13 | 完成 EpisodeDetail 的 Domain / Data / UseCase 分層實作：將輸入驗證、第 0 季評分支援規則、主要與輔助資料載入降級移入 `LoadEpisodeDetailUseCase`；新增 Episode Entity、Repository、DTO / Mapper 與 Presentation Models，移除舊 Model / Service。SeasonDetail 更新為已驗收，Phase 2 進度更新為 5 / 11；EpisodeDetail 靜態檢查通過，build 與手動走查仍待執行 |
| 1.6 | 2026-09-13 | 完成 SeasonDetail 的 Domain / Data / UseCase 分層實作：新增 Season Entity、Repository protocol 與實作、DTO / Mapper、`LoadSeasonDetailUseCase`，移除舊 Model / Service，並將顯示 fallback 收回 Presentation。Phase 2 進度更新為 4 / 11；靜態邊界檢查通過，build 與手動走查仍待執行 |
| 1.5 | 2026-09-13 | 依目前程式碼與 Git 歷史回填進度：Phase 2 已完成 ReviewList、MovieDetail、TVDetail，共 3 / 11 個 feature。更新檔案、行數、Repository、UseCase、Entity 與依賴預設值現況；將 G1–G3 標為部分完成、G6 標為完成、G7 標為已接受限制。修正 Phase 3 與模組拆分、MediaKind 目標、feature 內分層等過期敘述及 15 節路徑。新增逐 feature DTO 外洩檢查，並將 SeasonDetail、EpisodeDetail 列為下一批遷移項目 |
| 1.4 | 2026-09-12 | 4.3 結構定案為「先分 feature、再分層、最後分角色」：取消頂層 `Domain/`、`Data/`，改收在各 feature 資料夾底下，跨 feature 共用放 `Feature/`。與專案既有的一畫面一資料夾慣例一致。邊界檢查指令改用 `*/Domain/`、`*/Data/`。並記錄此結構不再與 SPM `Sources/` 同形的代價 |
| 1.3 | 2026-09-12 | 4.3 的資料夾結構曾改為「先分層、再分種類」，隨即於 1.4 再調整 |
| 1.2 | 2026-09-12 | 依 Phase 1 與 ReviewList 分層試點的實作結果回填判準與取捨。**更正兩處規格錯誤**：9.1 原稱可取代 5 個媒體型別列舉，實際只有 2 個是純二元；9.2 原把合併對象切成四個獨立群組，實際存在型別耦合，需先統一共用型別。**決議取消 SPM package**，4.3 改寫為資料夾層次邊界並補上三項機械檢查，新增 4.3.1 說明 Presentation 與 App 檔案為何留在原位。**新增判準**：5.6「什麼該進 Domain」、6.2 Mapper 的四類工作與「Entity 持有已解析型別」、10.4「composition root 不隨個別 feature 進行」。5.5 DomainError 改寫，明列未具型 throws 的取捨理由與收斂路徑。11 節順序調整為「Phase 2 分層（逐 feature）／Phase 3 依賴反轉（一次到位）」並記錄 Phase 1 成果。12 節驗收改為逐 feature。風險表新增 R11（未具型 throws）、R12（兩種架構並存）、R13（漏看型別耦合），R8 改為無編譯期邊界。15 節新增分層模式範本 |
| 1.1 | 2026-09-12 | 移除全部自動化測試內容：刪除原 11 節「測試規格」與原 Phase 0「建立測試基礎」，計畫改為 Phase 1–3。驗收標準改以靜態檢查與手動走查構成（12 節），Phase 3 進入條件移除測試數量門檻。風險表改編號並新增 R2（無測試的迴歸風險）、R5（顯式檔案參照漏加 target）。新增 9.4 合併作業程序與 5.4 UseCase 建立判準，作為測試以外的品質手段 |
| 1.0 | 2026-09-12 | 初版。基於全專案盤點提出四層架構規格與 Phase 0–3 計畫 |
