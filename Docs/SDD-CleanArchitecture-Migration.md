# SDD: CineBase Clean Architecture 分層遷移

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| 文件 ID | `SDD-CLEAN-ARCHITECTURE-MIGRATION` |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | 6.0 language mode，`SWIFT_STRICT_CONCURRENCY = complete` |
| 現行 UI 架構 | UIKit + MVVM + Presentation Builder + Router + `AppComposition` factory |
| 目標架構 | Clean Architecture + `AppComposition` + make factory + Router（Domain / Data / Presentation / App 四層，以資料夾表達，不建 SPM package） |
| 影響範圍 | 起點 243 個 Swift 檔 / 47,616 行；2026-09-26 為 364 個 Swift 檔 / 53,354 行 |
| 規格狀態 | `Accepted` |
| 實作狀態 | `Done`（Phase 1–3 完成；模組拆分已取消） |
| 驗證狀態 | Build `Passed`（2026-09-26，iOS Simulator Debug）；Runtime `Partial`（12.1 主要流程走查正常；guest 收藏寫入與 App Intent 項目 NotRun） |
| 最後更新 | 2026-09-26 |

---

## 1. 目的

本文件定義 CineBase 由現行 MVVM 分層遷移至 Clean Architecture 的設計規格、分階段計畫與驗收標準。

本文件同時要回答一個前置問題：**這個遷移在什麼條件下才划算**。因此 Phase 3（`AppComposition`、make factory / Router 與依賴反轉）帶有明確的進入條件，不是無條件執行的項目。實體模組拆分已取消，見 11 節。

本文件不涵蓋自動化測試規格。相關內容已於 v1.1 移除，見 16 節修訂紀錄與 13 節風險條目 R2。

---

## 2. 目標與非目標

### 2.1 架構目標

- 建立 Domain 層，讓業務規則不依賴 TMDB JSON 格式、不依賴 UIKit、不依賴任何第三方套件。
- 業務編排邏輯由 Service 移出，成為職責單一的 UseCase。
- 所有遠端資料存取統一經過 Repository 抽象，保留快取與本地資料來源的插入點。
- 建立 `AppComposition` composition root，集中依賴組裝並移除 Presentation 對 concrete type 的依賴。
- 不引入 Coordinator；root / session 切換由 `SceneDelegate` 負責，tab / deep-link 流程由既有 `MainTabBarController` 負責，Router 執行 feature-local push / present。
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
- 不搬移 ViewModel、Controller、View、Router 的資料夾位置，也不另建頂層 `Presentation/` 與 `App/`。架構缺口是 G1/G2/G3，檔案位置不是。例外是舊的 `Service/`、`Model/`、`Network/` 角色資料夾：其職責已由分層取代，依 4.3.1 歸入 feature 內的 `Domain/`、`Data/`、`Presentation/`。
- 不為了分層而分層：只有真正含業務規則的程式碼才進 Domain（見 5.6）。

---

## 3. 現況盤點

### 3.1 量化現況

數值為兩個時間點的對照：**起點**為 `39e9882`，**現在**為 2026-09-26 的 HEAD（Phase 1–3 完成，並含其後新增的 CompanyDetail、圖片預覽重構與 `ThemeColor` 統一）。檔案數與行數以工作樹中的 Swift 原始碼為準；ViewModel / Service 數沿用原盤點口徑，計算對應角色資料夾內的 Swift 檔。

| 項目 | 起點 | 現在 |
|------|------|------|
| Swift 檔案數 | 243 | 364 |
| 程式碼行數 | 47,616 | 53,354 |
| Xcode target 數 | 1（`MyTMDB_App`，application） | 1 |
| 檔案組織方式 | 240 檔為顯式 `PBXFileReference`，`MyTMDB_App/` 資料夾使用 `PBXFileSystemSynchronizedRootGroup` | 不變 |
| ViewModel 資料夾內 Swift 檔案數 | 24 | 18 |
| Service 資料夾內 Swift 檔案數 | 22 | 0（`Service/`、`Model/`、`Network/` 角色資料夾皆已歸位，見 4.3.1） |
| Repository 實作數 | 2（皆位於 `MemberCenter`） | 18 |
| UseCase 檔案數 | 0 | 24 |
| Domain Entity 型別數 | 0 | 106（分布於 48 檔；2026-09-26 以 `Domain/Entity` 內頂層 struct／enum／class 計，同口徑下 2026-09-14 為 99） |
| `import UIKit` 出現在 ViewModel / Service / Model / Presentation / Data | 2 檔 | 0 檔（tab avatar 繪製移至 `MainTabBar/View/MainTabBarAvatarImageProvider`） |
| `AppComposition` 外的 `= NetworkService()` 預設參數 | 18 處 | 0 處 |
| 待移除的 concrete dependency 預設參數（不含 `AppComposition`） | 49 行（原盤點） | 0 行 |
| `convenience init()` 硬接依賴 | 4 處 | 0 處（保留 1 個純 UI convenience initializer） |
| Movie / TV 平行檔案組 | 31 組 | 9 組（僅 MovieDetail↔TVDetail） |
| 獨立的 `case movie / case tv` 列舉 | 5 個 | 3 個（皆非二元，見 9.1） |

專案同時使用顯式檔案參照與 `MyTMDB_App/` 的 `PBXFileSystemSynchronizedRootGroup`。一般 feature 新增 Swift 檔仍需確認 target membership；`MyTMDB_App/` 同步根目錄下的 `Composition/AppComposition.swift` 會自動納入 target。既有 commit `711763f`（`fix: add member center list repository to target`）即為顯式參照漏加所致。此為需持續注意的操作風險，見 13 節 R5。

`AppComposition` 已接管 runtime 組裝：集中建立 Repository、UseCase、ViewModel、ViewController 與 App Intent 依賴；`SceneDelegate` 持有單一 composition，直接處理 loading / login / main root；`LaunchSessionResolver` 在冷啟動時沿用已驗證 session，或在 `.loggedOut` 時建立並保存 guest；`MainTabBarController` 延續 tab 與 deep-link 導航責任；Router 只依賴窄化 Scene Builder。專案不建立 Coordinator，舊 `AppRootFactory` 已由不含 UIKit 的 `AuthFlowHandler` / `AuthSessionValidator` / `LaunchSessionResolver` 取代。依賴型 `convenience init`、composition 外的 `NetworkService()` 預設值與 Controller 內 ViewModel 組裝已清除。

舊 `AccountService` / `AccountServiceProtocol` 與未使用的 `AccountViewModel` 已刪除。會員資料一律經 Domain 的 `AccountProfileProviding.profile(sessionID:)` 取得，由 `AccountContentRepository` 實作並同步寫入 `UserProfileStoring`；`AuthSessionValidator`、`AuthFlowHandler`、`AccountSessionRepository`、`AppIntentSessionResolver`、`MainTabBarAvatarService` 與 `MainMemberSettingViewModel` 皆只依賴此窄介面。

### 3.2 已符合 Clean Architecture 的部分

這些是遷移中最難補的項目，專案已經具備，必須在遷移中**保留而非重寫**：

- **UI 框架隔離已成立。** ViewModel / Presentation / Domain / Data 不 import UIKit；原本唯一的例外 `MainTabBarAvatarService` 已拆為 Data 層 `AccountAvatarRepository` 與 View 層 `MainTabBarAvatarImageProvider`。舊 `AppRootFactory` 已移除。
- **已分層 feature 的 DTO 未外洩至 UI 層。** `ReviewList`、`MovieDetail`、`TVDetail`、`SeasonDetail`、`EpisodeDetail`、`PersonDetail` 的 ViewModel、Presentation、Controller 與 View 均只使用 Domain Entity 或 presentation model。
- **Presentation 層已存在。** `MovieDetail`、`TVDetail`、`SeasonDetail`、`PersonDetail`、`EpisodeDetail`、`MainHome`、`MemberCenter` 共有 8 個 `SectionBuilder` / `PresentationBuilder`，皆為輸入輸出俱為值型別的靜態純函數。這等同 Clean 的 Presenter。
- **Protocol 邊界已建立。** `NetworkServicing`、`MovieDetailProviding`、`TVDetailProviding`、`ReviewProviding`、`SessionStoring`、`MemberCenterContentProviding` 等，依賴皆以 protocol 宣告。
- **Swift 6 嚴格並行已就緒。** Service 層一致標註 `nonisolated` + `Sendable`，ViewModel 標註 `@MainActor`，並行以 `async let` 與 `withThrowingTaskGroup` 實作。

### 3.3 落差清單

#### G1 — Domain Entity 覆蓋 Phase 2 範圍（已完成）

11 個 Phase 2 feature 均已完成 Entity / DTO 分離；其新增的 Domain Entity 不具 `Decodable` / `Encodable` conformance。跨 feature 的既有 `MediaKind` 仍有未使用的 `Codable` conformance，列入 Phase 3 清理，見 9.1。

HomeSectionList 原本直接使用 `MediaGenreListDTO`、MainHome 的 `MainHomeContent` 兼任 DTO 與 Model，以及 MemberCenter 直接使用 `MediaSummaryDTO` 的過渡狀態皆已解除。Phase 2 範圍執行 DTO 外洩檢查無輸出。

影響：尚未分層的 feature 仍可能讓 TMDB 欄位變更直接衝擊 Presentation。4.3 已補上逐 feature 的 DTO 外洩檢查；該檢查只要求正在驗收的 feature 無輸出，不要求尚未分層的 feature 提前通過。

#### G2 — UseCase 覆蓋明確業務編排（已完成）

`LoadReviewsUseCase`、`FilterReviewsUseCase`、`LoadMovieDetailUseCase`、`LoadTVDetailUseCase`、`LoadSeasonDetailUseCase`、`LoadEpisodeDetailUseCase`、`LoadPersonDetailUseCase`、`LoadPersonCreditsUseCase` 已建立。MovieDetail、TVDetail、SeasonDetail、EpisodeDetail 與 PersonDetail 的「主要資料失敗則整體失敗，輔助資料失敗則降級」已由 Service 移入 UseCase；PersonDetail 的作品類型路由與輸入驗證也已移入 UseCase。

MainHome 的併發載入與部分失敗處理已由 `MainHomeService` 移入 `LoadHomeSectionsUseCase`；HomeSectionList 的類型篩選移入 `FilterMediaByGenreUseCase`。

MemberCenter 的帳號內容載入已由 `LoadMemberCenterOverviewUseCase` 承接；單頁收藏清單只轉呼叫 Repository，依 5.4 判準由 `MemberCenterListViewModel` 直接依賴 `AccountContentProviding`。會員設定的「重新整理會員資料」、「登出」、「清除所有本機資料」跨 session / 會員快取 / 搜尋紀錄編排，由 `RefreshAccountProfileUseCase`、`LogoutUseCase`、`ClearLocalDataUseCase` 承接。跨 feature 的帳號媒體狀態則已抽為 `LoadAccountMediaStateUseCase`、`ToggleFavoriteUseCase`、`SubmitRatingUseCase`、`DeleteRatingUseCase`（見 G5）。

#### G3 — Repository 抽象覆蓋全部遠端資料（已完成）

目前有 17 個 Repository 實作。Phase 2 範圍外的最後 4 條 `Service → NetworkServicing` 直通已改寫：

| 原 Service | 改寫後 |
|------------|--------|
| `TMDBAuthService` | `AuthenticationProviding` / `AuthenticationRepository`（`MainLogIn/Domain`、`MainLogIn/Data`），`LoginViewModel` 改依賴 protocol |
| `MainSearchService` | `MainSearchProviding` / `MainSearchRepository`、`LoadMainSearchDiscoveryUseCase`（併發載入每日熱門與熱門人物）；`MainSearchResult` 等 Entity 去除 `Decodable`，DTO 移入 `Main/MainSearch/Data/DTO` |
| `AppIntentEntityLookupService` | 刪除。與 `MovieDetailProviding.movie(id:)` / `TVDetailProviding.series(id:)` 打同一支 API，改由 `MovieEntity(detail:)` / `TVSeriesEntity(detail:)` 映射 |
| `MainTabBarAvatarService` | Data 層 `AccountAvatarProviding` / `AccountAvatarRepository` 取圖與快取；View 層 `MainTabBarAvatarImageProvider` 只負責產生 `UIImage` |

全專案除 `Feature/Data/` 與各 feature 的 `Data/` 外，已無 `NetworkServicing` 或 `URLSession` 使用端。Repository 即為快取、離線、本地資料來源的插入點。

#### G4 — 依賴反轉（已完成）

`AppComposition` 已成為唯一完整組裝點；`NetworkService()`、Repository、UseCase、ViewModel 與 ViewController 的 concrete 物件圖均由具名 `make...` factory 建立。ViewModel / Controller 的依賴便利初始化與 concrete 預設參數已移除，Router 僅接收窄化 Scene Builder protocol。

結果：抽換基礎實作集中修改 composition；Presentation 不再知道 concrete Data implementation，且沒有 `.shared` / `resolve<T>()` Service Locator。

#### G5 — Detail 系列帳號流程（已完成）

`MovieDetailViewModel`、`TVDetailViewModel`、`EpisodeDetailViewModel` 已不再直接編排 `SessionStoring`、`AccountServiceProtocol` 與 `AccountMediaStateProviding`。登入檢查、帳號解析、收藏與評分寫入已移至 4 個 Domain UseCase；`DetailAccountMediaStateController` 縮減為畫面狀態協調與錯誤文案映射。

UseCase 與 Repository 的 concrete 組裝已集中至 `AppComposition.makeDetailAccountMediaStateController()`，Detail ViewModel 僅接收已完成的畫面狀態協調器。

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

**遷移可行，且 Phase 1、Phase 2、Phase 3 實作已完成。** G1、G2、G3、G4、G5、G6 已收斂；G7 為已接受限制。simulator Debug clean build 已通過且無警告，剩餘工作是 12.1 runtime 人工走查。

實際遷移順序為 **G6 → G1/G2/G3 → G4/G5**，理由：

1. G6 已先完成，避免 Domain / Data 層把原有 Movie / TV 重複放大。
2. G1/G2/G3 可逐 feature 交付，每次都能獨立取得 Entity、UseCase、Repository 的價值。
3. G4/G5 必須等需要依賴反轉的 feature 完成分層後，再由 composition root 一次收斂，避免過渡期出現多個組裝點（見 10.4）。

---

## 4. 目標架構

### 4.1 分層

```text
App
  AppDelegate / SceneDelegate
  Composition Root + make factory (AppComposition)
  MainTabBarController (tab / deep-link flow)
  Router (feature-local push / present)
  Controller / View / Cell
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
  DTO / Mapper / Repository impl / NetworkService / SessionStore / APIConfig / SDWebImageCacheStore
  import Foundation, Domain
```

### 4.2 依賴規則

| 層 | 可依賴 | 不可依賴 |
|----|--------|----------|
| Domain | Foundation | 其他任何層、UIKit、任何第三方套件 |
| Data | Foundation、Domain、基礎設施轉接用的第三方套件（目前僅 SDWebImage） | Presentation、App、UIKit |
| Presentation | Foundation、Domain | Data、App、UIKit |
| App | 全部 | 無限制 |

**第三方套件的位置。** Domain 與 Presentation 不得 import 第三方套件。Data 可為基礎設施轉接引用第三方套件，但必須實作 Domain protocol 並只經 protocol 對外，例如 `SDWebImageCacheStore: ImageCacheClearing`。App 層的 Controller / View 可直接使用 UI 類套件（SnapKit、SDWebImage 的圖片載入、Lottie），但不得直接操作儲存或快取（例如 `SDImageCache.shared.clearDisk`），一律經 Domain protocol。

**跨層共用設定。** `Feature/Config/` 的 `TMDBResourceURL`（圖片、Gravatar、TMDB 網站網址）與 `AppLocalization` 只 import Foundation、不含 I/O，Data 與 Presentation 皆可引用。API endpoint 與 `NetworkService` 仍屬 `Feature/Data/Network/`，Presentation 不得引用。`Feature/Config/ThemeColor` 依賴 UIKit，只供 View 層使用。

補充規則：

- Domain 型別**不得** conform `Decodable` 或 `Encodable`。序列化是 Data 層的責任。
- Presentation 層**不得** import Data。ViewModel 只認識 Domain 的 UseCase / Repository protocol；本機 session、會員快取、搜尋紀錄分別經 `AuthSessionProviding`、`AccountProfileProviding`、`SearchHistoryProviding` 存取，不得直接依賴 `SessionStoring`、`UserProfileStoring` 等 Data 型別。唯一例外是 5.5 的 `NetworkError` 穿透。
- Data 層的 DTO **不得**離開 Data 層，一律經 Mapper 轉為 Domain Entity 後才向外傳遞。
- `SceneDelegate`、`MainTabBarController` 與 Router 均屬於 App 層；ViewModel 不持有它們，維持由 Controller 將使用者事件轉交導航物件的做法。
- `SceneDelegate` 只決定 loading / login / main root；`MainTabBarController` 管理 tab 與 App Intent / deep-link 入口；Router 只執行當前 feature 的 push / present / URL 開啟。
- `AppComposition` 只負責建立物件圖，不保存畫面流程狀態、不執行導航，也不得被 ViewModel 當作 Service Locator 使用。
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
EpisodeDetail/ 同上
PersonDetail/  同上
Feature/
  Domain/Entity/  Domain/Error/       跨 feature 共用
  Data/DTO/  Data/Mapper/  Data/Repository/
  Data/Network/                       NetworkService、APIConfig、NetworkError
  Data/Storage/                       AppPreferencesStorage（UserDefaults + Mutex）、SessionStore、UserProfileStore
  Components/<元件>/Presentation/      跨 feature 共用的 presentation model（例：HomeContent、MediaGrid）
  Config/                             TMDBResourceURL、AppLocalization（跨層共用設定，見 4.2）
MainLogIn/
  Domain/Repository/
  Data/DTO/  Data/Repository/
  Flow/  ViewModel/  Controller/  View/  Router/
```

理由是與專案既有的「一個畫面一個資料夾」慣例一致：打開 `MovieDetail/` 就能看到這個畫面的全部，從 Entity 到 Controller，不必在四個頂層目錄之間跳。同一個領域的 Entity、UseCase、Repository 也自然看得到彼此。

跨 feature 共用的部分放 `Feature/`，沿用專案既有的共用程式碼位置，不另立頂層資料夾。

**共用的判準**：被一個以上的 feature 使用，或本身不屬於任何單一 feature（`CalendarDay`、`Page`、`DomainError`）。只有單一 feature 使用的型別一律歸該 feature，**即使名稱看似通用**。由專屬升格為共用的時機是第二個 feature 開始使用它——`MediaSummary` 與 `MediaDTO` 即是在 TVDetail 分層時由 MovieDetail 專屬升格而來。

判準的「feature」不含 App 層入口：`MyTMDB_App/`（composition、SceneDelegate）、`MainTabBar/` 與 `Feature/AppIntents/` 依 4.2 可依賴任何層，它們引用某個 feature 的型別不構成升格理由。`Feature/Base/`、`Feature/Components/`、`Feature/SearchHistory/` 本身即為共用模組。反向規則同樣成立：放在 `Feature/` 卻只剩一個 feature 使用的型別，應移回該 feature。

v2.12 依此判準的調整：

| 型別 | 使用者 | 調整 |
|------|--------|------|
| `Genre`、`ProductionCompany` | MovieDetail、TVDetail | 由 `MovieDetail/Domain/Entity/Movie.swift` 拆出至 `Feature/Domain/Entity/` |
| `AggregateCredits` 系列 Entity / DTO / Mapper | TVDetail、SeasonDetail | 由 `TVDetail/` 移至 `Feature/Domain/Entity/`、`Feature/Data/DTO/`、`Feature/Data/Mapper/` |
| `Account`、`SessionStore`、`UserProfileStore`、`AccountProfile`、`AccountAvatarURLFactory` | MainLogIn、MemberCenter、MainMemberSetting、共用 Repository | 移至 `Feature/Data/DTO/`、`Feature/Data/Storage/`、`Feature/Domain/Entity/`、`Feature/Data/Mapper/AccountDTO+Mapping.swift`；`UserProfileStore` 的重複頭像網址邏輯改用 `AccountAvatarURLFactory` |
| `HomeCategory`、`HomeContentProviding`、`HomeContentRepository`、`HomeContentItem` | MainHome、HomeSectionList | 移至 `Feature/Domain/`、`Feature/Data/Repository/`、`Feature/Components/HomeContent/Presentation/`；首頁專屬的 `HomeSection`、`LoadHomeSectionsUseCase`、`displayPriority` 留在 MainHome |
| `AccountAvatarProviding`、`AccountAvatarRepository` | 僅 MainTabBar | 由 `Feature/` 移回 `MainTabBar/Domain/Repository/`、`MainTabBar/Data/Repository/` |
| `ImageCacheClearing`、`SDWebImageCacheStore` | 僅 MainMemberSetting | 由 `Feature/` 移回 `Main/MainMemberSetting/Domain/Repository/`、`Main/MainMemberSetting/Data/Storage/` |

保留在 `Feature/` 的單一使用者型別：`ISO8601DateParsing`、`CalendarDayParsing` 為通用 wire-format 解析工具；`LoadAccountMediaStateUseCase`、`SubmitRatingUseCase`、`DeleteRatingUseCase` 由 `Feature/Base` 的 `DetailAccountMediaStateController` 服務 MovieDetail、TVDetail、EpisodeDetail。

**與 SPM package 的關係**：此結構不再與 `Sources/<target>/` 同形。若日後決定拆 package，需要先把各 feature 的 `Domain/` 與 `Data/` 收攏，屬額外工作。這是為了日常可讀性而付出的代價，且 Phase 3 的模組拆分已依決議取消。

**代價必須明講**：資料夾不是編譯期邊界。Domain 裡寫 `import UIKit` 仍會通過編譯。維持邊界只能靠兩件事：

1. 4.2 的依賴規則與 code review。
2. 下列機械檢查，每次動到 Domain 或 Data 後執行：

```bash
DOMAIN_DIRS=$(find . -type d -name Domain -not -path './build/*' -not -path './.git/*')
DATA_DIRS=$(find . -type d -name Data -not -path './build/*' -not -path './.git/*')
PRES_DIRS=$(find . -type d \( -name Presentation -o -name ViewModel \) -not -path './build/*' -not -path './.git/*')

grep -rn "^import" --include='*.swift' $DOMAIN_DIRS | grep -v "import Foundation"
grep -rnE "NetworkServic|APIConfig|DTO|UIKit|ErrorMessage" --include='*.swift' $DOMAIN_DIRS
grep -rnE "ViewModel|ViewController|UIKit" --include='*.swift' $DATA_DIRS
grep -rnwE '[A-Za-z][A-Za-z0-9]*DTO' --include='*.swift' . | grep -v '/Data/'
PRES_TYPES=$(grep -rhoE "^(nonisolated )?(final )?(struct|enum|class|protocol) [A-Z][A-Za-z0-9]+" --include='*.swift' $PRES_DIRS | awk '{print $NF}' | sort -u | paste -sd'|' -)
grep -rnwE "$PRES_TYPES" --include='*.swift' $DATA_DIRS
```

五項皆須無輸出。`find` 會涵蓋所有層級的 `Domain/`、`Data/`（含 `Main/MainSearch/Domain`、`Feature/SearchHistory/Data` 等巢狀位置）。第四項檢查 DTO 是否外洩至 `Data/` 以外；第五項檢查 Data 層是否引用 Presentation / ViewModel 資料夾宣告的型別（v2.12 以此發現 `StoredUserProfile.headerContent` 建立 `MemberCenterProfileHeaderContent`，已刪除）。

### 4.3.1 Presentation 與 App 的位置

Presentation（ViewModel、SectionBuilder、PresentationModels）與 feature-local App 元件（Controller、View、Router）**留在原本的 feature 資料夾**，不另建頂層 `Presentation/` 與 `App/`。唯一的 composition root 放在 `MyTMDB_App/Composition/AppComposition.swift`，因為它屬於 App 入口而非任一 feature；不建立 Coordinator 目錄或型別。

理由：3.3 列出的架構缺口是 G1（缺 Entity）、G2（缺 UseCase）、G3（缺 Repository），這三者靠新增 Domain/Data 解決。把既有的 ViewModel 與 Controller 換個資料夾不會修正任何缺口，卻要動到上百個檔案與 `project.pbxproj`，在沒有測試的前提下是純風險。

判斷一個檔案屬於哪一層，看的是它的依賴與職責，不是它的路徑。

**舊角色資料夾的歸位規則。** `Service/`、`Model/`、`Network/` 不屬於任何一層，已依職責歸位，只搬位置、不改型別名稱與內容：

| 原位置 | 內容 | 歸位 |
|--------|------|------|
| `Network/` | `NetworkService`、`APIConfig`、`NetworkError`、`AppLocalization` | `Feature/Data/Network/`；`AppLocalization` 與 `APIConfig` 的外部資源網址其後移至 `Feature/Config/`（v2.10） |
| `MainLogIn/Service/SessionStore.swift`、`UserProfileStore.swift` | 本機 session / 會員資料儲存 | `MainLogIn/Data/Storage/`；跨 feature 使用，v2.12 升格至 `Feature/Data/Storage/` |
| `Feature/SearchHistory/Service/SearchHistoryStore.swift` | 本機搜尋紀錄儲存 | `Feature/SearchHistory/Data/Storage/` |
| `MainLogIn/Model/AccountModel.swift` | TMDB `Account` 回應模型 | `MainLogIn/Data/DTO/`；跨 feature 使用，v2.12 升格至 `Feature/Data/DTO/` |
| `MainLogIn/Model/AuthSession.swift` | 登入狀態 | `Feature/Domain/Entity/`（跨 feature 使用，v2.10 由 `MainLogIn/Domain/Entity/` 升格） |
| `Feature/SearchHistory/Model/SearchHistoryModels.swift` | 搜尋紀錄 Entity | `Feature/SearchHistory/Domain/Entity/` |
| `MainLogIn/Service/AuthFlowHandler.swift` | `AuthSessionValidator` / `AuthFlowHandler`，App 層流程元件（見 8.2） | `MainLogIn/Flow/` |
| `DetailContentList/Model`、`Feature/Base/DetailBase/Model`、`Feature/Components/ErrorMessage/Model`、`Feature/Components/MediaGrid/Model`、`Main/MainMemberSetting/Model` | 畫面狀態、presentation model、`ErrorMessage` 映射 | 同 feature 下的 `Presentation/` |

`Data/Storage/` 收納本機持久化（UserDefaults），與 `Data/Repository/` 的遠端資料來源區分。`AuthSession`、`SearchHistoryScope`、`SearchHistoryEntry` 保留 `Codable`：它們以 JSON 存於 UserDefaults，移除會讓既有登入狀態與搜尋紀錄無法解碼；此為本機儲存相容性例外，不是 wire-format 序列化。`MainHome/Domain/Entity/HomeCategory` 原有未使用的 `Codable` 已於 v2.10 移除。

`Feature/Base/`、`Feature/Components/`（`Presentation/` 以外）、`Feature/Formatter/`、`Feature/Logger/`、`Feature/Extension/`、`PageSheet/` 為依元件分組的共用 UI 基礎設施，不在此次歸位範圍。

### 4.4 執行緒與 actor 規則

沿用專案現行規則，不做變更：

- Domain Entity、UseCase、Repository、Mapper 一律 `nonisolated` 且 `Sendable`。
- UseCase 以 `async throws` 暴露，不標註 `@MainActor`。
- ViewModel 標註 `@MainActor`；具有非同步 state flow 的 ViewModel 以 `bind(onStateChange:)` 驅動 UI，binding 立即送出目前 state，且相同 state 不重送。同步 query/action model 不建立空的 binding。
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
| `ToggleFavoriteUseCase` | `DetailAccountMediaStateController.toggleFavorite` | `AccountSessionProviding`、`AccountMediaStateProviding` |
| `SubmitRatingUseCase` | `DetailAccountMediaStateController.submitRating` | `AccountSessionProviding`、`AccountMediaStateProviding` |
| `DeleteRatingUseCase` | `DetailAccountMediaStateController.deleteRating` | `AccountSessionProviding`、`AccountMediaStateProviding` |
| `LoadAccountMediaStateUseCase` | `DetailAccountMediaStateController.loadAccountMediaState` | `AccountSessionProviding`、`AccountMediaStateProviding` |

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

搬移 DTO 的 decode fallback 時需注意：現行 fallback 同時混合了「資料缺失」與「顯示文案」兩種語意（例如 `?? "未命名"`）。Mapper 只負責前者，後者一律移至 Presentation，見 13 節 R3。已完成：DTO 缺值一律 decode 為空字串，`未命名`、`未命名影片`、`未命名平台`、`未命名系列`、`未命名季數`、`未命名片單` 等文案改由 Presentation 轉換點以 `BaseDisplayTextFormatter.text(_:fallback:)` 補上，App Intent entity 同樣於映射時補上。

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

現行 22 個 Service 依此模式改寫為 Repository。`NetworkService`、`APIConfig`、`NetworkError`、`SessionStore`、`UserProfileStore`、`SearchHistoryStore` 一併歸入 Data 層（已完成，位置見 4.3.1）；`AppLocalization` 為跨層共用設定，位於 `Feature/Config/`（見 4.2）。`NetworkError.errorDescription` 僅保留英文除錯描述，使用者文案一律由 Presentation 的 `NetworkError+ErrorMessage` 提供。

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

### 8.1 AppComposition（Composition Root）

```swift
// MARK: - AppComposition

@MainActor
final class AppComposition {

    // MARK: - Properties

    private let network: NetworkServicing
    private let sessionStore: SessionStoring
    private let userProfileStore: UserProfileStoring
    private let searchHistoryStore: SearchHistoryProviding

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        sessionStore: SessionStoring = SessionStore(),
        userProfileStore: UserProfileStoring = UserProfileStore(),
        searchHistoryStore: SearchHistoryProviding = SearchHistoryStore()
    ) {
        self.network = network
        self.sessionStore = sessionStore
        self.userProfileStore = userProfileStore
        self.searchHistoryStore = searchHistoryStore
    }

    // MARK: - Factories

    func makeMovieDetailViewController(movieID: Int) -> UIViewController {
        let repository = MovieDetailRepository(
            network: network,
            localization: .current
        )
        let viewModel = MovieDetailViewModel(
            loadMovieDetailUseCase: DefaultLoadMovieDetailUseCase(
                repository: repository,
                failureReporter: AppLoggerAuxiliaryFailureReporter()
            ),
            accountMediaController: makeDetailAccountMediaStateController()
        )
        return MovieDetailViewController(
            movieID: movieID,
            viewModel: viewModel,
            sceneBuilder: self
        )
    }
}
```

`AppComposition` 是全專案**唯一**允許建立完整 concrete 依賴鏈與提供 concrete 依賴預設值的位置。它是工廠與 Composition Root，不是讓外部任意查詢服務的 DI Container。

上例是目前已落地介面的精簡示意；實際檔案依各畫面的建構參數提供對應 `make...` factory。

一般 App 執行流程由 `SceneDelegate` 建立並持有單一 `AppComposition`，再直接呼叫 root factory。App Intent 是獨立系統入口，可建立自己的短生命週期 `AppComposition`，但不得使用全域 `.shared`。不引入第三方 DI 容器。

`AppComposition` 可以：

- 建立 Repository implementation、UseCase、ViewModel、ViewController 與 App Intent handler / query factory。
- 保存需要共享生命週期的基礎設施，例如 `NetworkServicing`、`SessionStoring`、`UserProfileStoring`。
- 以 protocol 或 factory closure 暴露特定畫面的建構能力。

`AppComposition` 不可以：

- 保存目前頁面、登入流程步驟或 navigation stack 等流程狀態。
- 持有 `UIWindow`、執行 `push` / `present` 或保存 navigation stack；session 變化僅透過注入 closure 回報 `SceneDelegate`。
- 傳入 ViewModel、UseCase 或 Repository，讓下層任意取用依賴。
- 以 `resolve<T>()`、字串 key 或全域 singleton 形成 Service Locator。

### 8.2 Root、登入與 Tab 流程（不使用 Coordinator）

本專案明確不建立 Coordinator。流程沿用 UIKit 現有擁有者，畫面及依賴一律向 `AppComposition` 的 `make...` factory 取得：

```text
SceneDelegate
  ├─ AppComposition
  ├─ LaunchSessionResolver → existing session / new guest session
  ├─ loading / login / main root switch
  └─ MainTabBarController
       ├─ tab navigation stacks
       ├─ App Intent / deep-link destination
       └─ Feature Router → narrow Scene Builder → AppComposition factory
```

| 元件 | 責任 | 不負責 |
|------|------|--------|
| `SceneDelegate` | 建立 window / composition、啟動 session resolution、loading / login / main root 切換、接收 URL context | 建立 Repository / UseCase / ViewModel、feature-local push 細節 |
| `LaunchSessionResolver` | 驗證已存 session；冷啟動為 `.loggedOut` 時建立並保存 guest | 建立或切換畫面、處理非冷啟動登出導航 |
| `AuthSessionValidator` | 經 `AccountProfileProviding` 驗證已存 session，清理失效的 session / profile | 建立或切換畫面 |
| `AuthFlowHandler` | 保存登入或訪客 session、經 `AccountProfileProviding` 取得並快取會員資料、以 closure 回報 session 完成 | 持有 window / navigation controller、建立畫面 |
| `MainTabBarController` | 建立 tab navigation stack、切換 tab、以 `initialTab` 還原選取中的 tab、把 App Intent / deep link 導向正確 feature | 建立 Repository / UseCase / ViewModel |

`AuthFlowHandler` 的完成 closure 由 `AppComposition` 注入並回報 `SceneDelegate`；此 closure 只傳遞 `AuthSession`，不形成額外流程物件。登出則由 `AppFlowRouting` 的窄介面通知 composition，再透過同一 session callback 讓 `SceneDelegate` 替換 root。

**登入入口與 root 替換規則：**

| 情境 | 登入頁呈現 | `LoginEntryContext` | 登入後 |
|------|------------|---------------------|--------|
| 冷啟動無 session 或已存會員失效 | Loading root 執行 `LaunchSessionResolver`，自動建立並保存 guest | 不先顯示登入頁 | 建立 `MainTabBarController`，明確停在 `.home` |
| App 內主動登出、清除所有本機資料或 guest 建立失敗後選擇登入 | `SceneDelegate` 設為 root | `.root`：登入 / 訪客 / 註冊三頁 | 建立 `MainTabBarController`，停在首頁 |
| 訪客於設定頁、會員中心、詳情頁或 App Intent 觸發登入 | 由 Router / `MainTabBarController` 以 `.present`（page sheet）呈現 | `.inApp`：登入 / 註冊兩頁，顯示關閉按鈕；登入進行中停用關閉與下滑關閉 | `SceneDelegate` 替換 root 前讀取舊 `MainTabBarController.selectedTabKind`，傳給新 tab bar 的 `initialTab`；只還原 tab，不還原 tab 內的 navigation stack |

`LoginSceneBuilding.makeLoginNavigationController(context:)` 為唯一登入頁 factory，呼叫端必須明確指定 context。

**設定頁依帳號模式組裝。** `MainMemberSettingViewModel` 經 `AuthSessionProviding` 判斷帳號模式：會員顯示會員資料卡、帳號區塊與登出；訪客（含 `.loggedOut`）改顯示訪客卡（登入 / 註冊）、隱藏帳號區塊與登出。「註冊」直接以 Safari 開啟 `TMDBResourceURL.signup`。

### 8.3 Router

`BaseRouter`、`DetailRouter` 及各 feature Router 歸屬 App 層，只負責 feature-local 的 `push`、`present`、page sheet、Safari 與外部 URL 開啟。

Router 不直接建立 Repository、UseCase 或 ViewModel，也不直接持有 concrete `AppComposition`。需要下一個畫面時，注入對應的 Scene Builder protocol 或 factory closure：

```swift
@MainActor
protocol DetailSceneBuilding: AnyObject {
    func makeMovieDetailViewController(movieID: Int) -> UIViewController
    func makeTVDetailViewController(seriesID: Int) -> UIViewController
    func makePersonDetailViewController(personID: Int) -> UIViewController
}

@MainActor
final class DetailRouter: BaseRouter {
    private let sceneBuilder: DetailSceneBuilding

    init(
        sourceViewController: UIViewController,
        sceneBuilder: DetailSceneBuilding
    ) {
        self.sceneBuilder = sceneBuilder
        super.init(sourceViewController: sourceViewController)
    }

    func showMovieDetail(movieID: Int) {
        guard movieID > 0 else { return }
        show(
            sceneBuilder.makeMovieDetailViewController(movieID: movieID),
            using: .push
        )
    }
}
```

Scene Builder protocol 依導航範圍拆分，例如 `DetailSceneBuilding`、`MemberCenterSceneBuilding`；不得建立一個暴露全 App 畫面的巨大 factory protocol。Factory 對外回傳 `UIViewController`；父畫面需要接收 child event 時，由 factory 參數注入 callback。父畫面需要送入 child action 時，只依賴窄化的 action protocol（例如 `SearchResultsHandling`），不得要求 factory 暴露具體 ViewController 型別。

共用 Router（`Feature/Base/` 的 `DetailRouter` 等）的參數只能使用 Domain 型別或基本值，不得依賴特定 feature 的 presentation model。例如人物作品跳轉使用 `showMediaDetail(kind: MediaKind, id: Int)`，由 PersonDetail 自行將 `PersonDetailCreditItem` 轉為 `MediaKind`。

### 8.4 責任與事件流

| 元件 | 核心責任 | 可持有 |
|------|----------|--------|
| `AppComposition` | 組裝物件圖 | shared infrastructure、factory |
| `SceneDelegate` | root / session 流程 | window、單一 `AppComposition`、session validation task |
| `MainTabBarController` | tab / deep-link 流程 | tab navigation controllers、窄化 Scene Builder |
| Router | 執行局部導航 | source view controller、窄化 Scene Builder |
| ViewController | 顯示畫面、轉交 UI event | ViewModel、Router protocol |
| ViewModel | UI state、呼叫 UseCase、Presentation mapping | Domain protocol；不得持有 Router / `AppComposition` |

資料流與導航流分離：

```text
資料：ViewController → ViewModel → UseCase → Repository protocol ← Repository
導航：ViewController → Router → Scene Builder → AppComposition
流程：SceneDelegate → AppComposition make factory → Login / MainTab；MainTabBarController → feature Router
```

### 8.5 位置修正

| 檔案 | 現況 | 遷移後 |
|------|------|--------|
| `MainLogIn/Service/AppRootFactory.swift` | Service 層但 import UIKit，並混合 root factory 與 auth flow | 已刪除；`AppComposition` 承接畫面組裝、`SceneDelegate` 承接 root 切換、`AuthFlowHandler` 承接 session 完成事件 |
| `MainLogIn/Service/AccountService.swift` | Service 直通 `NetworkServicing`，與 `AccountContentRepository.profile(sessionID:)` 打同一支 `Account.me` API | 已刪除；改由 `Feature/Domain` 的 `AccountProfileProviding` 窄介面接收，`AccountContentProviding` 繼承之 |
| `MainLogIn/ViewModel/AccountViewModel.swift` | 無使用端 | 已刪除 |
| `MainTabBar/Service/MainTabBarAvatarService.swift` | Service 層但 import UIKit | 已拆為 `MainTabBar/Data/Repository/AccountAvatarRepository.swift`（取圖與快取）+ `MainTabBar/View/MainTabBarAvatarImageProvider.swift`（產生 `UIImage`） |
| `MainLogIn/Service/TMDBAuthService.swift`、`MainLogIn/Model/TMDBAuthModels.swift` | Service 直通 `NetworkServicing` | 已刪除；改為 `AuthenticationProviding` / `AuthenticationRepository` / `AuthenticationDTO` |
| `Main/MainSearch/Service/MainSearchService.swift`、`Main/MainSearch/Model/MainSearchModels.swift` | Service 直通 `NetworkServicing`，Model 兼任 DTO 與 presentation model | 已刪除；拆為 MainSearch 的 Domain / Data 與 `Presentation/MainSearchPresentationModels.swift` |
| `Feature/AppIntents/Queries/AppIntentEntityLookupService.swift` | 與詳情 Repository 重複的 DTO 與 API 呼叫 | 已刪除；改用 `MovieDetailProviding` / `TVDetailProviding` |

---

## 9. MediaKind 統一規格

本節對應 G6，是 Phase 1 的核心，且**必須早於任何分層工作完成**。

### 9.1 MediaKind

```swift
// MARK: - MediaKind

nonisolated enum MediaKind: String, Sendable, CaseIterable, Equatable {
    case movie
    case tv
}
```

`MediaKind` 屬於領域概念，位於 `Domain/Entity/MediaKind.swift`。其顯示文字與圖示（`displayName`、`systemImageName`）屬 Presentation，置於 `Feature/Media/MediaKind+Presentation.swift`。

目前原始碼仍保留 `Codable`，但全專案沒有 `MediaKind` 的 encode / decode 使用點，且與 4.2 的 Domain 序列化禁令衝突。Phase 3 移除該 conformance；若未來需要持久化，由 Data 層 DTO 或 storage mapper 轉換 `rawValue`。

**本節初版有誤。** 初版列出 5 個「應被取代」的列舉，實際盤點後只有 2 個是純二元 movie/tv：

| 型別 | 判定 | 處置 |
|------|------|------|
| `MemberCenterAccountMediaType` | 純二元 | **已取代** |
| `MainHomeMediaType` | 純二元 | **已取代** |
| `PersonCreditMediaType` | 含 `unknown(String)` 關聯值，保留 API 未知原始值 | 保留，非 MediaKind |
| `MainSearchMediaType` | 含 `person`，涵蓋非影音結果；`unknown` 已移除，改由 Mapper 過濾不支援的結果 | 保留，非 MediaKind |
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
| `convenience init()` 內建立完整依賴 | 4 | 刪除，改由 `AppComposition` 建構 |
| `network: NetworkServicing = NetworkService()` | 17 | 移除預設值，改為必填參數 |
| concrete dependency 預設參數 | 49 行（包含前述 17 行 network 預設） | 移除預設值，改為必填參數；值型別行為預設不計入 |
| Controller 內 `self.viewModel = XxxViewModel()` | 多處 | 改為 init 注入 |

### 10.2 允許保留的預設值

- `AppComposition.init` 的基礎設施預設值（唯一 composition root），例如 `network`、`sessionStore`、`userProfileStore`、`searchHistoryStore`。
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

理由：`AppComposition` 的價值在於成為唯一的組裝點。若隨 feature 長期分批啟用，會同時存在兩種 runtime 注入方式（部分走 composition root、部分走預設參數），組裝點不唯一，等於沒有 composition root，卻已付出改動成本。

因此分層工作（Domain / Data）與依賴反轉（10.1–10.3）分開執行：

- 分層期間，ViewModel 仍以既有的預設參數注入 UseCase，例如
  `init(mediaKind:loadReviewsUseCase: LoadReviewsUseCase = DefaultLoadReviewsUseCase(repository: ReviewRepository()))`。
- 待需要分層的 feature 都完成後，先加入尚未接入 runtime 的 `AppComposition` 與 Scene Builder protocol；下一個 cutover commit 再一次接管 `SceneDelegate` 並移除全部預設值。不得合併或發布只有部分畫面走新組裝方式的中間狀態。

### 10.5 防止 Service Locator

- ViewModel、UseCase、Repository initializer 不得接收 `AppComposition`。
- 只有 `SceneDelegate` 持有完整 `AppComposition`；其他 UI 元件只接收完成的依賴或窄化 Scene Builder protocol。
- Router 只接收導航範圍所需的 Scene Builder protocol 或 factory closure，不接收 concrete `AppComposition`。
- Controller 接收已建構的 ViewModel 與 Router factory；不得以 `AppComposition.shared` 取得依賴。
- `AppComposition` 不提供泛型 `resolve<T>()`、subscript 或字串 key 查詢。

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
5. 執行 4.3 的五項機械邊界檢查，皆須無輸出。
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

### Phase 3：依賴反轉（AppComposition + make factory + Router）

**目的**：處理 G4、G5。

目前進度：G5 的 4 個跨 feature UseCase 已完成；G4 已由 `AppComposition` 接管 runtime 組裝，Auth / MainTab / Router 已改走 factory 注入，全專案 concrete dependency 預設值已清理；帳號資料取得統一經 `AccountProfileProviding`；G3 剩餘 4 條 Service 直通已改寫，舊 `Service/`、`Model/`、`Network/` 資料夾已歸位。機械邊界檢查與 simulator Debug clean build（無警告）通過；runtime 走查部分完成（2026-09-26：首頁、電影／影集詳情、公司詳情、圖片預覽與設定頁正常）。

交付：

- 建立 `AppComposition` composition root，以具名 `make...` factory 集中建立 Repository、UseCase、ViewModel、ViewController 與 App Intent 依賴。
- 不建立 Coordinator；`SceneDelegate` 管理啟動與 root 切換，`AuthFlowHandler` 以 session closure 回報登入完成，`MainTabBarController` 管理 tab stack 與跨 tab / deep-link 流程。
- Router 改依賴窄化 Scene Builder protocol 或 factory closure，不直接建立 ViewModel，也不持有 concrete `AppComposition`。
- 移除 4 處 `convenience init()`、17 處 network 預設值、49 行 concrete dependency 預設參數，以及 Controller 內的 ViewModel 組裝。
- 移除 `MediaKind` 未使用的 `Codable` conformance；若未來需要持久化，改由 Data 層 mapper 轉換 `rawValue`。
- 由 `DetailAccountMediaStateController` 抽出 4 個跨 feature UseCase（G5）。
- 以單一 cutover 接管 `SceneDelegate` 和全部 feature；不得留下兩套 runtime 組裝路徑。完成後以靜態檢查、Xcode build 與人工走查分別驗收，不得把 parser 結果表述為 build 通過。

**進入條件**：需要依賴反轉的 feature 都已完成 Phase 2 分層。理由見 10.4——過渡期若同時存在兩種 runtime 注入方式，組裝點不唯一，等於沒有 composition root。

**獨立價值：有。** 完成後抽換任一實作的成本不再與呼叫端數量成正比。

### 已取消：模組拆分

原 Phase 3 包含建立 `Packages/CineBaseCore` 並拆為三個 SPM target。**依決議取消**，層次改以資料夾表達（見 4.3）。

代價是沒有編譯期邊界強制，改以 4.3 的機械檢查與 code review 維持。若日後情境改變（團隊增員、需要第二個 app target、需要抽換資料來源），4.3 的層次優先佈局可讓拆 package 成為單純的檔案搬移。

## 12. 驗收標準

本專案不採用自動化測試，因此各 Phase 的驗收以**靜態檢查**與**手動走查**兩類條件構成。

### 12.1 共通迴歸走查

每個 Phase 結束、Phase 1 每完成一組合併、Phase 2 每完成一個 feature 時執行：

- [x] `xcodebuild build` 成功且無新增警告（2026-09-14 simulator Debug clean build，專案內 0 warning）。
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
- [ ] 4.3 的五項機械邊界檢查皆無輸出：

```bash
DOMAIN_DIRS=$(find . -type d -name Domain -not -path './build/*' -not -path './.git/*')
DATA_DIRS=$(find . -type d -name Data -not -path './build/*' -not -path './.git/*')
PRES_DIRS=$(find . -type d \( -name Presentation -o -name ViewModel \) -not -path './build/*' -not -path './.git/*')

grep -rn "^import" --include='*.swift' $DOMAIN_DIRS | grep -v "import Foundation"
grep -rnE "NetworkServic|APIConfig|DTO|UIKit|ErrorMessage" --include='*.swift' $DOMAIN_DIRS
grep -rnE "ViewModel|ViewController|UIKit" --include='*.swift' $DATA_DIRS
grep -rnwE '[A-Za-z][A-Za-z0-9]*DTO' --include='*.swift' . | grep -v '/Data/'
PRES_TYPES=$(grep -rhoE "^(nonisolated )?(final )?(struct|enum|class|protocol) [A-Z][A-Za-z0-9]+" --include='*.swift' $PRES_DIRS | awk '{print $NF}' | sort -u | paste -sd'|' -)
grep -rnwE "$PRES_TYPES" --include='*.swift' $DATA_DIRS
```

- [ ] 該 feature 的 12.1 相關項目在 movie 與 tv 兩條路徑各走查通過。

### 12.4 Phase 3

- [x] `AppComposition` 存在，且為專案中唯一建立完整 concrete 依賴鏈與提供 concrete 依賴預設值的型別。
- [x] `SceneDelegate` 只建立並持有一組 `AppComposition`，不直接組裝 feature，也不建立 Coordinator。
- [x] `SceneDelegate` 管理 loading / login / main root；`AuthFlowHandler` 回報 session 完成；`MainTabBarController` 管理 tab stack 與跨 tab / deep-link 路由。
- [x] ViewModel、UseCase、Repository 均未引用 `AppComposition` 或 Router。
- [x] Router 未直接建立 Repository、UseCase、ViewModel，且只依賴窄化 Scene Builder protocol／factory closure。
- [x] 專案不存在 `AppComposition.shared`、`resolve<T>()` 或其他 Service Locator API。
- [x] `MediaKind` 不再 conform `Codable`，Domain Entity 均不承擔 wire-format 序列化。
- [x] 4 個用來硬接依賴的 `convenience init` 已移除；保留 1 個純 UI convenience initializer。
- [x] 全專案 `= NetworkService()` 結果為 1（僅 `AppComposition`）。
- [x] 除 `Data/` 外無 `NetworkServicing` / `URLSession` 使用端（G3）。
- [x] 專案不存在 `Service/`、`Model/` 角色資料夾，網路層位於 `Feature/Data/Network/`。
- [x] ViewModel / Presentation 不引用 Data 型別（`SessionStoring`、`UserProfileStoring`、`APIConfig`、Repository 實作）；搜尋紀錄改經 Domain 的 `SearchHistoryProviding`；`NetworkError` 依 5.5 例外。
- [x] Data 層無中文顯示文案；DTO fallback 不含 `未命名` 類字串。
- [x] `AppComposition` 不讀取 session 狀態；登入判斷與 season / episode credential 由 `AuthSessionProviding` 在使用時解析。
- [x] Domain UseCase 不接收 `@escaping` closure；輔助資料失敗改注入 `AuxiliaryLoadFailureReporting`。
- [x] Controller 不直接操作儲存或快取；圖片快取清除經 `ImageCacheClearing`，併入 `ClearLocalDataUseCase`。
- [x] Domain protocol 與 UseCase 一型別一檔；所有 feature 的 presentation model 位於 feature 根目錄的 `Presentation/`。
- [x] 專案不含未使用的佔位 `ViewController`。
- [x] 全專案無 `AccountServiceProtocol` / `fetchAccount`；會員資料只經 `AccountProfileProviding` 取得。
- [x] simulator Debug build 通過（`xcodebuild -scheme MyTMDB_App -destination 'generic/platform=iOS Simulator'`）。
- [x] 全專案無 `UseCase = Default...UseCase(...)` 形式的預設參數。
- [x] `DetailAccountMediaStateController` 已由 4 個 UseCase 取代業務編排，縮減為畫面狀態協調器。
- [ ] 未登入 / guest 路徑不會寫入收藏（以走查確認）。
- [ ] App Intent 使用獨立、短生命週期的 composition 入口，且 4 個公開 shortcut 均可正常觸發。
- [ ] 12.1 走查全數通過。

---

## 13. 風險與緩解

| 編號 | 風險 | 影響 | 緩解 |
|------|------|------|------|
| R1 | Phase 1 合併 Detail 時 movie / tv 行為差異被抹平 | 功能退化且不易察覺 | Detail 合併為選擇性項目；合併前依 9.4 逐項判定差異類別，不得整批套用 |
| R2 | 無自動化測試，重構迴歸只能靠人工 | Phase 1 涉及約 3,800 行變更，人工走查可能漏掉邊界情境 | 一組一個 commit 以便精準回退；每組合併後立即執行 12.1 走查；不同時進行兩組合併。此為本計畫已知的最大弱點，若日後改變測試策略應優先補上 Phase 1 合併範圍的覆蓋 |
| R3 | Mapper 吃掉 DTO 的 decode fallback 導致顯示文案改變 | UI 出現空字串 | 搬移前先列出所有含顯示語意的 fallback（如 `?? "未命名"`），明確移至 Presentation 而非刪除 |
| R4 | 移除 49 行 concrete 預設參數造成大範圍修改 | 單次 cutover diff 大、難以 review | 先提交不接管 runtime 的 protocol / composition 骨架；cutover 只做工廠注入與預設值移除，避免混入功能修改 |
| R5 | 新增檔案漏加入 target | 編譯期未報錯但執行期缺功能 | 專案採顯式檔案參照（見 3.1）；每次新增檔案後確認 target membership，或評估將各 feature 資料夾改為 `PBXFileSystemSynchronizedRootGroup` |
| R6 | Entity 與 DTO 雙軌並存期間認知負擔 | 開發者誤用 DTO | DTO 一律加 `DTO` 後綴；Phase 3 後以 access level 封閉 |
| R7 | 過度抽象：為每個 Repository 方法造一個 UseCase | 產生大量單行轉呼叫類別 | 套用 5.4 的判準：只有含條件、編排或降級策略者才建立 UseCase |
| R8 | 無編譯期層次邊界 | 資料夾不擋違規 import，Domain 可能悄悄依賴 Data 或 UIKit，DTO 也可能外洩至其他層 | 每次動到 Domain 或 Data 後執行 4.3 的五項機械檢查；新增 feature 時一併執行 |
| R9 | App Intents 依賴既有 service，遷移時斷裂 | Siri / Shortcuts 失效 | `Feature/AppIntents` 改為依賴 UseCase，並由獨立短生命週期 `AppComposition` 組裝；每 Phase 執行 12.1 的 Intents 走查項目 |
| R10 | 遷移期間 TMDB API 變更 | 同時處理重構與外部變更 | 每個 Phase 控制在可於短期內完結的範圍，不長期開分支 |
| R11 | Domain 的 throws 不具型 | 從 UseCase 簽章看不出可能拋出哪些非領域錯誤，呼叫端只能概括處理 | 已知取捨，理由見 5.5。收斂路徑為 typed throws，需同時提供 `TransportFailure` 與其文案映射，屬獨立工作 |
| R12 | 分層期間兩種架構並存 | 已分層與未分層的 feature 寫法不同，易誤用 | 分層以 feature 為單位一次做完，不留半分層狀態；`ReviewList` 作為模式範本供對照 |
| R13 | 規劃合併或分層順序時漏看型別耦合 | 拆成多個 commit 後無法各自建置，被迫回頭合併 | 動工前先確認各組**沒有共用型別**；有共用型別就先統一型別再分別處理（9.2 的教訓） |
| R14 | `SceneDelegate`、`MainTabBarController` 與 Router 同時決定相同導航 | 流程分支重複、返回行為不一致 | `SceneDelegate` 只處理 root；`MainTabBarController` 只處理 tab / deep-link 入口；Router 只執行 feature-local push / present，依 8.4 表格 review |
| R15 | `AppComposition` 被當成 Service Locator | 下層可任意取得 concrete 依賴，依賴關係重新隱藏 | 禁止 `.shared` 與 `resolve<T>()`；ViewModel / UseCase / Repository 不得接收 `AppComposition`；Router 只接收窄化 Scene Builder |
| R16 | composition 的 session callback 或 Router 與 Controller 形成引用環 | root 或畫面流程完成後物件持續存活 | `SceneDelegate` callback 使用 weak self；Router 對來源 Controller 與 app flow 介面維持 weak reference；非同步 Task 在 deinit 取消 |

---

## 14. 維護規則

- 新增 feature 時，依 4.2 的依賴規則配置檔案；不得在 Presentation 層 import Data。
- 新增業務規則時，先套用 5.6 判準：顯示文案進 Presentation、wire format 進 Data Mapper、條件與編排進 Domain。
- 新增 UseCase 前先確認它含條件、編排或降級策略；純集合運算改為 Entity 擴充。
- 新增依賴時，於 `AppComposition` 增加具名 `make...` factory；不得於 ViewModel 或 Controller 內組裝多層依賴。
- 新增 root 流程時由 `SceneDelegate` 決策；tab / deep-link 入口由 `MainTabBarController` 決策；單一 feature 的 push / present 由 Router 執行，不得重複建立相同目的地。
- 新增 Router destination 時，擴充該導航範圍的 Scene Builder protocol；不得讓 Router 直接接收 concrete `AppComposition`。
- 不得建立 `AppComposition.shared`、泛型 resolver 或字串 key DI API。
- 新增 Domain 型別時，確認未 conform `Decodable` / `Encodable`，且只 import Foundation。
- **每次動到 `Domain/` 或 `Data/` 後，執行 4.3 的五項機械檢查**，五項皆須無輸出。
- 新增或移動 Domain / Data 型別時，依 4.3 的共用判準決定位置：兩個以上 feature 使用放 `Feature/`，只剩一個 feature 使用則移回該 feature。
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
| 網路層 | `Feature/Data/Network/NetworkService.swift`、`Feature/Data/Network/APIConfig.swift`、`Feature/Data/Network/NetworkError.swift` |
| 跨層共用設定 | `Feature/Config/TMDBResourceURL.swift`、`Feature/Config/AppLocalization.swift` |
| 本機資料 Domain 介面 | `Feature/Domain/Repository/AuthSessionProviding.swift`、`Feature/SearchHistory/Domain/Repository/SearchHistoryProviding.swift`、`Main/MainMemberSetting/Domain/UseCase/RefreshAccountProfileUseCase.swift`、`Main/MainMemberSetting/Domain/UseCase/LogoutUseCase.swift`、`Main/MainMemberSetting/Domain/UseCase/ClearLocalDataUseCase.swift` |
| 輔助資料失敗回報 | `Feature/Domain/Error/AuxiliaryLoadFailureReporting.swift`、`MyTMDB_App/Composition/AppLoggerAuxiliaryFailureReporter.swift` |
| 本機儲存 | `Feature/Data/Storage/AppPreferencesStorage.swift`、`Feature/Data/Storage/SessionStore.swift`、`Feature/Data/Storage/UserProfileStore.swift`、`Main/MainMemberSetting/Data/Storage/SDWebImageCacheStore.swift`（實作 `Main/MainMemberSetting/Domain/Repository/ImageCacheClearing.swift`）、`Feature/SearchHistory/Data/Storage/SearchHistoryStore.swift` |
| G3 補齊的 Repository | `MainLogIn/Data/Repository/AuthenticationRepository.swift`、`Main/MainSearch/Data/Repository/MainSearchRepository.swift`、`MainTabBar/Data/Repository/AccountAvatarRepository.swift`（實作 `MainTabBar/Domain/Repository/AccountAvatarProviding.swift`） |
| MemberCenter Repository 實作 | `MemberCenter/Data/Repository/AccountContentRepository.swift`、`MemberCenter/Data/Repository/AccountListPosterEnricher.swift` |
| 跨 feature 共用的 Domain / Data | `Feature/Domain/Entity/`、`Feature/Domain/Repository/MediaGenreProviding.swift`、`Feature/Domain/Repository/AccountMediaStateProviding.swift`、`Feature/Domain/Repository/AccountSessionProviding.swift`、`Feature/Domain/Repository/AccountProfileProviding.swift`、`Feature/Domain/Repository/HomeContentProviding.swift`、`Feature/Data/DTO/`（含 `AccountModel.swift`、`AggregateCreditsDTO.swift`）、`Feature/Data/Mapper/`（含 `AccountDTO+Mapping.swift`、`AggregateCreditsDTO+Mapping.swift`）、`Feature/Data/Repository/`（含 `HomeContentRepository.swift`） |
| 跨 feature 共用的 presentation model | `Feature/Components/HomeContent/Presentation/HomeContentPresentationModels.swift`、`Feature/Components/MediaGrid/Presentation/MediaGridModels.swift` |
| 已完成的詳情編排 UseCase | `MovieDetail/Domain/UseCase/LoadMovieDetailUseCase.swift`、`TVDetail/Domain/UseCase/LoadTVDetailUseCase.swift`、`SeasonDetail/Domain/UseCase/LoadSeasonDetailUseCase.swift`、`EpisodeDetail/Domain/UseCase/LoadEpisodeDetailUseCase.swift`、`PersonDetail/Domain/UseCase/LoadPersonDetailUseCase.swift`、`PersonDetail/Domain/UseCase/LoadPersonCreditsUseCase.swift` |
| MemberCenter 已完成的分層 | `MemberCenter/Domain/`、`MemberCenter/Data/`、`MemberCenter/Presentation/`、`MemberCenter/List/Presentation/` |
| 跨 feature Account UseCase | `Feature/Domain/UseCase/LoadAccountMediaStateUseCase.swift`、`Feature/Domain/UseCase/ToggleFavoriteUseCase.swift`、`Feature/Domain/UseCase/SubmitRatingUseCase.swift`、`Feature/Domain/UseCase/DeleteRatingUseCase.swift` |
| Phase 3 App 入口 | `MyTMDB_App/Composition/AppComposition.swift`、`MyTMDB_App/SceneDelegate.swift`、`MainLogIn/Flow/AuthFlowHandler.swift`、`MainLogIn/Flow/LaunchSessionResolver.swift`、`MainTabBar/Controller/MainTabBarController.swift` |
| 已移除的舊流程組裝與 Service | `MainLogIn/Service/AppRootFactory.swift`、`MainLogIn/Service/AccountService.swift`、`MainLogIn/ViewModel/AccountViewModel.swift`、`MainLogIn/Service/TMDBAuthService.swift`、`Main/MainSearch/Service/MainSearchService.swift`、`Feature/AppIntents/Queries/AppIntentEntityLookupService.swift`、`MainTabBar/Service/MainTabBarAvatarService.swift` 與全部 Coordinator 型別 |
| Scene Builder 導入起點 | `Feature/Base/DetailBase/Router/DetailRouter.swift` 與各 feature 的 `Router/` |
| 已移除的依賴 convenience init | `MovieDetail/ViewModel/MovieDetailViewModel.swift`、`TVDetail/ViewModel/TVDetailViewModel.swift`、`SeasonDetail/ViewModel/SeasonDetailViewModel.swift`、`PersonDetail/ViewModel/PersonDetailViewModel.swift` |
| 保留、非 MediaKind 的媒體型別 | `PersonDetail/Domain/Entity/PersonCredits.swift`、`Main/MainSearch/Domain/Entity/MainSearchResult.swift`、`Feature/SearchHistory/Domain/Entity/SearchHistoryModels.swift` |
| 去重完成的參考樣板 | `PageSheet/Genre/Base/BaseGenrePageSheetViewController.swift` |
| 顯示語意 fallback 集中處 | `Feature/Formatter/BaseDisplayTextFormatter.swift`、`Feature/Components/ErrorMessage/Presentation/NetworkError+ErrorMessage.swift` |
| Tab avatar 繪製（View 層） | `MainTabBar/View/MainTabBarAvatarImageProvider.swift` |
| App Intents 相依面 | `Feature/AppIntents/Support/AppIntentFavoriteActionHandler.swift`、`Feature/AppIntents/Support/AppIntentSessionResolver.swift` |
| 相關文件 | `Docs/SDD-AppIntents-Siri-Apple-Intelligence.md` |

---

## 16. 修訂紀錄

| 版本 | 日期 | 說明 |
|------|------|------|
| 2.15 | 2026-09-26 | 對齊現況：3.1 量化現況與影響範圍改為 2026-09-26 HEAD 數值（原「現在」欄停留在 2026-09-14 的 `32a59d6`）；Phase 3 runtime 走查更新為部分完成；8.1 範例與 12.4 檢查項的 `SearchHistoryStoring` 改為現行的 `SearchHistoryProviding`；metadata 狀態改為規格／實作／驗證三欄 |
| 2.14 | 2026-09-25 | 冷啟動無 session 時改由 `LaunchSessionResolver` 透過既有 Authentication Repository 建立 guest、完成 Keychain 儲存後再由 `SceneDelegate` 明確建立首頁 Main Tab；既有 user／guest 沿用，App 內主動登出仍顯示 root 登入頁。`AppComposition` 新增具名 factory，不新增 Coordinator。Guest 建立端點修正為官方 GET；source 與靜態檢查通過，Build / Runtime NotRun |
| 2.13 | 2026-09-15 | 依 `SDD-Architecture-Unified-Interface-Naming.md` 同步 ViewModel output 與 Scene Builder 規則：14 個非同步 state ViewModel 統一 `bind(onStateChange:)`，2 個同步 query/action model 明確保留無 binding；Scene factory 回傳 `UIViewController`、callback 由參數注入，child input 使用窄化 `...Handling` protocol。同步套用 Swift 縮寫／ID、完整畫面 `loadInitialContent` 與 Router 動詞規則；Swift parser、Codable executable check 與五項 Clean Architecture 靜態邊界檢查通過，Xcode Build / Runtime NotRun |
| 2.12 | 2026-09-14 | 依 4.3 共用判準全面檢查 Domain / Data / Presentation 型別歸屬。(A) 依賴方向：刪除 Data 層 `StoredUserProfile.headerContent`（建立 MemberCenter 的 presentation 型別，無使用端）；共用 `DetailRouter.showCreditDetail(_: PersonDetailCreditItem)` 改為 `showMediaDetail(kind:id:)`，8.3 補共用 Router 參數規則。(B) 跨 feature 使用而升格至 `Feature/`：`Genre`、`ProductionCompany`、`AggregateCredits` 系列、`Account`、`SessionStore`、`UserProfileStore`、`AccountProfile`、`AccountAvatarURLFactory`（合併重複頭像網址邏輯）、`HomeCategory`、`HomeContentProviding`、`HomeContentRepository`、`HomeContentItem`。(C) 只剩單一 feature 使用而移回：`AccountAvatarProviding` / `AccountAvatarRepository` → MainTabBar；`ImageCacheClearing` / `SDWebImageCacheStore` → MainMemberSetting。4.3 補判準細則與調整表，機械檢查改以 `find` 涵蓋巢狀資料夾並新增第五項「Data 不得引用 Presentation 型別」，同步 11 節 Phase 2 程序、12.3、13 節 R8、14 節維護規則與 15 節路徑。simulator Debug clean build 無警告、五項機械檢查無輸出；runtime 走查未執行 |
| 2.11 | 2026-09-14 | (1) 刪除未使用的 `MyTMDB_App/ViewController.swift`（佔位畫面，直接依賴 `SessionStoring` 並自行處理登出）。(2) 新增 Domain `ImageCacheClearing` 與 Data `SDWebImageCacheStore`，`ClearLocalDataUseCase` 改為 `async` 並統一清除 session、會員快取、搜尋紀錄與圖片快取；`MainMemberSettingViewController` 不再直接呼叫 `SDImageCache`。4.2 補第三方套件位置規則。(3) `AccountSessionProviding`、`AccountProfileProviding` 由 `AccountMediaStateProviding.swift` 拆為獨立檔；`LocalAccountDataUseCases.swift` 拆為三個 UseCase 檔；`EisodeDetail/ViewModel/Presentation/` 移至 `EisodeDetail/Presentation/`。同步記錄先前未入文件的流程變更於 8.2：設定頁依帳號模式顯示訪客卡（登入 / 註冊）並隱藏帳號區塊與登出；`LoginEntryContext`（`.root` / `.inApp`）與 page sheet 登入頁；登入後以 `initialTab` 還原原 tab。更新 3.1、12.4 與 15 節路徑。simulator Debug clean build 無警告、4.3 機械檢查無輸出；runtime 走查未執行 |
| 2.10 | 2026-09-14 | 依 SDD 合規稽核修正：(1) `MainMemberSettingViewModel`、`MainSearchViewModel` 不再依賴 Data 儲存協定，新增 Domain `AuthSessionProviding`、`SearchHistoryProviding`，`AccountProfileProviding` 補 `cachedProfile()` / `clearCachedProfile()`，新增 `RefreshAccountProfileUseCase`、`LogoutUseCase`、`ClearLocalDataUseCase`；`SearchHistoryStore` 改用共用 `AppPreferencesStorage`（抽至 `Feature/Data/Storage/`）以符合 `Sendable`；`AuthSession` 升格至 `Feature/Domain/Entity/`。(2) 16 處 DTO 的 `未命名` 類 fallback 改為空字串，文案移至 Presentation 與 App Intent entity。(3) `APIConfig` 的外部資源網址抽為 `Feature/Config/TMDBResourceURL`，`AppLocalization` 移至 `Feature/Config/`，4.2 補跨層共用設定規則。(4) `NetworkError.errorDescription` 改為英文除錯描述，App Intent 收藏失敗訊息改用 `errorMessage`。小項：`AuthSession` 補 `nonisolated`；刪除只轉呼叫 Repository 的 `LoadAccountCollectionPageUseCase`；5 個詳情 UseCase 的 `@escaping` log closure 改為注入 `AuxiliaryLoadFailureReporting`；`AppComposition` 移除 session 讀取，season / episode credential 與登入判斷改於使用時由 `AuthSessionProviding` 解析（不再於建立畫面時快照）；移除 `HomeCategory` 未使用的 `Codable`。simulator Debug clean build 無警告、稽核檢查無輸出；runtime 走查未執行 |
| 2.9 | 2026-09-14 | 舊角色資料夾歸位：`Network/` 移至 `Feature/Data/Network/`；`SessionStore`、`UserProfileStore`、`SearchHistoryStore` 移至各自的 `Data/Storage/`；`Account` 移至 `MainLogIn/Data/DTO/`；`AuthSession`、`SearchHistoryModels` 移至 `Domain/Entity/`；`AuthFlowHandler` 移至 `MainLogIn/Flow/`；5 個 `Model/` 資料夾的 presentation model 移至同 feature 的 `Presentation/`。共 17 檔，只搬位置、不改型別與內容，`project.pbxproj` 以 `xcodeproj` gem 同步。2.3 非目標補上角色資料夾例外，4.3 樹狀圖與 4.3.1 補歸位表，記錄 `Codable` 本機儲存相容性例外與 `HomeCategory.Codable` 待清理。更新 3.1 量化現況、12.4 與 15 節路徑。simulator Debug clean build 無警告、4.3 機械檢查無輸出；runtime 走查未執行 |
| 2.8 | 2026-09-14 | G3 完成：`TMDBAuthService` 改為 `AuthenticationProviding` / `AuthenticationRepository`；`MainSearchService` 改為 MainSearch 的 Entity / DTO / Mapper / `MainSearchRepository` 與 `LoadMainSearchDiscoveryUseCase`，presentation model 移至 `Presentation/`；刪除 `AppIntentEntityLookupService`，App Intent entity 改由詳情 Repository 映射；`MainTabBarAvatarService` 拆為 `AccountAvatarRepository` 與 `MainTabBarAvatarImageProvider`（8.5）。行為差異：avatar 快取改以 HTTP 2xx 與 image MIME 判定，不再以 `UIImage` 解碼判定；搜尋結果空標題改在 Presentation 顯示「未命名」；年份改由 `CalendarDay` 取得，需完整 `yyyy-MM-dd`；`MainSearchMediaType.unknown` 移除，由 Mapper 過濾。12.1 build 項目勾選 |
| 2.7 | 2026-09-14 | 修復 2.6 cutover 後的建置中斷：`AccountService.swift` 已刪除但 `AppComposition` 等 6 處仍依賴 `AccountServiceProtocol`，且 `project.pbxproj` 殘留 `AccountService.swift` / `AccountViewModel.swift` 的失效參照。新增 Domain 窄介面 `AccountProfileProviding`，`AccountContentProviding` 改為繼承之，`AuthSessionValidator`、`AuthFlowHandler`、`AccountSessionRepository`、`AppIntentSessionResolver`、`MainTabBarAvatarService`、`MainMemberSettingViewModel` 改接此介面並由 `AppComposition.makeAccountContentRepository()` 提供。行為差異：`profile(sessionID:)` 會同步寫入 `UserProfileStoring`，因此 session 驗證與帳號解析也會刷新本機會員快取；tab avatar 取得資料時不再清除網址未變的頭像快取。更新 3.1 量化現況、5 節跨 feature UseCase 表的 Repository 名稱（`AccountProviding` / `SessionProviding` 改為實際的 `AccountSessionProviding` / `AccountMediaStateProviding`）、8.2 / 8.5、Phase 3 進度、12.4 與 15 節路徑。simulator Debug build 通過；runtime 走查未執行 |
| 2.6 | 2026-09-14 | 依決議取消 Coordinator：刪除 `AppCoordinator` / `AuthFlowCoordinator` 規劃與實作，改由 `SceneDelegate` 直接管理 root、`AuthFlowHandler` 回報 session 完成、`MainTabBarController` 管理 tab / deep-link；`AppComposition` 以具名 `make...` factory 接管完整物件圖，Router 改依賴窄化 Scene Builder。同步移除 concrete dependency 預設值、舊 `AppRootFactory` 與 `MediaKind.Codable`，並更新 Phase 3 驗收狀態。靜態 parser 與機械檢查通過；Xcode build / runtime 未執行 |
| 2.5 | 2026-09-13 | 新增尚未接管 runtime 的 `AppCoordinator` 基礎骨架，只建立對 `UIWindow` 與 `AppComposition` 的持有關係；未加入空的 `start()`、root 切換或 deep-link 方法，也未修改 `SceneDelegate` |
| 2.4 | 2026-09-13 | 開始 Phase 3 的被動骨架：新增 `MyTMDB_App/Composition/AppComposition.swift`，先集中 `NetworkServicing`、`SessionStoring`、`UserProfileStoring`、`SearchHistoryStoring` 四個共享基礎設施；尚未接管 `SceneDelegate`、畫面 factory 或導航流程，因此 runtime 行為不變 |
| 2.3 | 2026-09-13 | Phase 3 composition root 定名為 `AppComposition`，補上 `AppCoordinator` / `AuthFlowCoordinator` / `MainTabCoordinator` 的流程邊界、Router 的局部導航責任、窄化 Scene Builder 注入、child coordinator lifecycle 與防止 Service Locator 規則。依賴切換改採「被動骨架 + 單一 runtime cutover」，並同步更新驗收條件、風險、`MediaKind` 序列化清理與現況路徑 |
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
