# SDD: CineBase Slim ViewModel 責任邊界優化

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| 文件 ID | `SDD-VIEW-MODEL-SLIM-OPTIMIZATION` |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | Swift 6.0，`SWIFT_STRICT_CONCURRENCY = complete` |
| 既有架構 | UIKit + MVVM + Clean Architecture + Presentation Builder + Router + `AppComposition` |
| 目標 | 以責任、依賴方向與變更原因縮減 ViewModel，而非以檔案行數判定 |
| 實作範圍 | Scope A Presentation Builder 抽離、Scope B 分頁狀態整併（已實作）；Scope D 文件整併（待實作）；Scope C 單元測試（取消） |
| 狀態 | v2.6；Scope A、B Implemented（Source）並已提交，Static Passed，Build／Runtime NotRun；v2.5–v2.6 依賴方向修正尚未提交；Scope C Cancelled；Scope D NotStarted |
| 日期 | 2026-09-22 |

---

## 文件結構

- **Part I 準則（第 1–3 節）**：長期有效的判準與責任邊界。Scope D 完成後併入 `SDD-CleanArchitecture-Migration.md`。
- **Part II 實作（第 4 節起）**：各 scope 的盤點、設計、驗收與狀態。全部完成後歸檔。

本文件只補充既有規格，不重述其內容：

- 分層、依賴方向與 UseCase 建立判準以 `SDD-CleanArchitecture-Migration.md` 為準。
- ViewModel 輸出契約與命名以 `SDD-Architecture-Unified-Interface-Naming.md` 為準。

---

# Part I 準則

## 1. 目的

「Slim」指 ViewModel **責任集中、邊界清楚**，不是小於特定行數，也不是新增一套 ViewModel framework。要解決的問題：

- 畫面狀態協調與大量 Presentation mapping 集中在同一型別，形成多個彼此獨立的變更原因。
- 同一段狀態流程在多個 ViewModel 各自複製，單一需求必須同步修改多處，且副本會逐漸走樣。
- 把「ViewModel 變短」誤解成「每個 Repository 方法都包成 UseCase」，形成沒有業務價值的轉呼叫層。

## 2. 判準

### 2.1 不設行數與依賴數門檻

- 不設定 ViewModel 150、200 或其他行數上限，也不以行數作為 CI、lint、code review 或驗收失敗條件。
- 行數只能決定 review 的**先後順序**，不得用來**產生**候選名單（v1.0 的做法已修正，見 4.1）。
- 依賴數量只是耦合訊號。持有多個窄化 UseCase 可以合法；只持有一個萬能 facade 仍可能是不良設計。

### 2.2 需要優化的訊號

單一 ViewModel：

1. 有兩個以上彼此獨立的變更原因，例如 API 流程、Presentation mapping、localization 組裝與導航同時存在。
2. 直接依賴 Data concrete type、UIKit、Router、`AppComposition` 或 Service Locator。
3. 編排多個 Repository、定義降級策略或承載可跨畫面重用的業務規則。
4. 包含可由相同輸入穩定產生相同輸出的純 Presentation mapping。
5. 難以在不建立 ViewController 的情況下驗證 state transition 或 mapping。

跨 ViewModel（v2.0 新增）：

6. **變更頻率**：同一 ViewModel 因不相關需求反覆修改。以 git 紀錄量化（指令見 4.2），判讀前排除全專案重構造成的雜訊。
7. **跨畫面重複**：同一段狀態流程或 mapping 在多個 ViewModel 各自實作，使單一需求必須同步修改多處，或副本之間已出現行為差異。

上述為設計判斷，不是計分制；符合單一項目不代表必須拆分。

### 2.3 不為縮短 ViewModel 濫增抽象

- UseCase 只在含條件判斷、跨 Repository 編排或降級策略時建立，不建立單純轉呼叫 Repository 的 UseCase（沿用 Clean Architecture SDD）。
- 純集合轉換、去重、選取或 Presentation mapping 放在 Entity extension、Presentation Model 或 Presentation Builder。
- 跨畫面共用邏輯優先以**值型別與純函式**表達。不建立 `BaseViewModel`、ViewModel protocol、泛型 Paginator 或泛型 state machine framework。

## 3. 責任邊界

### 3.1 資料與導航流

```text
UI event
   |
   v
ViewController -------> Router -------> Scene Builder -------> AppComposition
   |
   v
@MainActor ViewModel
   |  - state transition
   |  - task result / cancellation guard
   |  - cache needed by the screen
   |  - UI intent coordination
   |
   +------> Presentation Builder
   |          Domain value + localization -> Presentation value
   |
   +------> Shared presentation value (e.g. MediaGridPaginationState)
   |          page metadata + pure checks
   |
   +------> UseCase
   |          conditions / multi-repository orchestration / fallback policy
   |
   +------> Repository protocol
              simple single-source query when no UseCase value exists
```

導航流與資料流維持分離。Presentation Builder 與共用 Presentation 值型別不得執行 I/O、保存狀態或導航。

Presentation 側（ViewModel、Builder、Presentation Model、共用值型別）不依賴 View 層或 import UIKit 的檔案所宣告的型別；共用的純判斷放在 Presentation 側，由 View 引用（v2.5 起，現況見 4.5）。

### 3.2 各角色責任

**ViewModel（`@MainActor`）**

- 持有 `ViewState` 的唯一寫入權，提供 `bind(onStateChange:)` 或既有同步 query/action API。
- 協調 UI intent，負責 loading、refreshing、loaded、empty、failed 等狀態轉換。
- 防止重複送出、取消後停止更新，並檢查分頁過期結果。
- 保存只對目前畫面有意義的 transient selection、cache 與 pagination metadata。
- 將 Domain error 轉為既有 `ErrorMessage`。

**Presentation Builder**

- Domain 值到 Presentation Model 的純轉換。
- 組裝 sections、rows、headers、menu options 與顯示文字選擇。
- 去重、選取標記與 append mapping。
- 不持有 mutable state、不保存 callback、不存取 Repository。

**共用 Presentation 值型別**

- 承接可跨畫面重用的畫面狀態欄位與純判斷，例如分頁頁碼、loading 旗標與觸發門檻。
- 不包含 `Task`、async 流程或過期結果檢查。

**UseCase**

- 承接多 Repository／Provider 編排、業務條件、跨資料來源一致性與降級策略。
- 不承接 spinner、pagination threshold、localized 文案、SF Symbol、section 排列、`ViewState`、`ErrorMessage` 或純轉呼叫。

**ViewController**

- 建立與取消由畫面生命週期驅動的 `Task`。
- 負責 UIKit binding、Diffable Data Source、layout 與 animation，將 navigation intent 交給 Router。
- 分頁觸發前可做輕量門檻預檢以避免建立多餘 `Task`；權威判斷仍在 ViewModel。

### 3.3 Builder 規則

- 預設採無狀態 `nonisolated enum` 的 static function；輸入與輸出為 `Sendable` 值型別，不回傳 UIKit 型別。
- 相同輸入必須產生相同輸出。唯一例外是 MainSearch daily trending 的 `.shuffled()`（`makeDailyTrendingContent` 與 `MainSearchDailyTrendingContent.appending`），屬產品要求的隨機排序；因不建立 test target（第 7 節），不為它注入 `RandomNumberGenerator`。之後新增隨機行為時，須比照此例外明列於本節。
- 預設寫入 feature 既有的 Presentation Models 檔；檔案因 Builder 過大而難以瀏覽時，可獨立為 `<Feature>PresentationBuilder.swift`。專案只有 `MyTMDB_App/` 資料夾是 synchronized group，其他資料夾的新 Swift 檔都要同步更新 `project.pbxproj`。2026-09-22 已授權本 SDD 範圍內為 app target 增減 Swift 檔而修改 `project.pbxproj`，不含新增任何 target。
- `AppComposition` 不為 Builder 新增 property、factory、`.shared` 或 Resolver。

---

# Part II 實作

## 4. 目標選擇與盤點

### 4.1 v1.0 選擇方式的修正

v1.0 雖宣告行數不是判準，候選名單仍取自行數最大的五個型別；排除 `DetailAccountMediaStateController` 與 `LoginViewModel` 後，剩下的即是 Scope A 的三個目標。結果：

- `MainMemberSettingViewModel` 550 → 178 行，約 370 行靜態 section 設定移出，收益明確。
- `MainSearchViewModel` 327 → 298 行、`MainMediaListViewModel` 268 → 239 行，各只移出約 30 行，收益有限。
- 逐一檢視單一 ViewModel 的方式看不到跨畫面重複，因此漏掉分頁狀態流程（4.3）。

v2.0 起先依 2.2 第 6、7 點做跨 ViewModel 盤點；行數只決定 review 順序。

### 4.2 變更頻率

```bash
git log --format= --name-only -- '*ViewModel.swift' '*StateController.swift' \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -12
```

2026-09-22 結果前段：`MovieDetailViewModel` 28、`TVDetailViewModel` 18、`SeasonDetailViewModel` 13、`MainSearchViewModel` 12；`MainMediaListViewModel` 不在前 12 名。

數字包含 Clean Architecture 遷移、命名統一與多語系等全專案修改，判讀前應排除這類 commit。Detail 系列已採用 SectionBuilder，本版不因頻率單獨開 scope。

### 4.3 跨畫面重複：分頁狀態流程

Scope B 實作前（2026-09-22）的盤點：6 個 ViewModel、7 條分頁流程各自實作相同的狀態機：判斷可否載入 → 標記 loading → await → 取消與過期檢查 → append 或還原 loading。

| 畫面 | 分頁狀態位置 | 觸發門檻 | Task 持有者 | await 後取消／過期檢查 |
|------|--------------|----------|-------------|------------------------|
| MainSearch（每日熱門、搜尋結果） | Content | Controller 預檢與 ViewModel 皆用 `MediaGridLayoutMetrics`（4） | `MediaGridPaginationTaskController` | 有 |
| MainMediaList | Content | 同上 | `MediaGridPaginationTaskController` | 有 |
| MemberCenterList | Content | Controller 自訂常數 4、ViewModel 寫死 `4` | Controller 自有 `Task` | 有 |
| HomeSectionList | ViewModel 私有變數 | 同 MainMediaList | `MediaGridPaginationTaskController` | 有 |
| SearchResults | ViewModel 私有變數與 Content | 同 MainMediaList | `MediaGridPaginationTaskController` | 有 |
| ReviewList | ViewModel 私有變數 | 僅 Controller，自訂常數 3 | `MediaGridPaginationTaskController` | **無** |

重複與走樣：

- 5 份私有 `shouldLoadNextPage` helper、5 份 `updatingLoadingNextPage`；7 個 Presentation 型別各自攜帶頁碼、總頁數與 `isLoadingNextPage` 等分頁欄位。
- ReviewList 已走樣：對外命名改用 `page`／`hasNextPage`；`loadNextPage()` 在 await 後不檢查取消與過期結果，重新載入期間回來的舊頁可能被 append。
- 門檻值分散四處：`MediaGridLayoutMetrics`（4）、MemberCenterList Controller 常數（4）與 ViewModel 字面值（4）、ReviewList Controller 常數（3）。ReviewList 的 3 是否刻意需產品確認。
- 單一需求（例如分頁失敗改為顯示錯誤或重試）需要同步修改 6 個 ViewModel。

判定：符合 2.2 第 7 點，開 Scope B。

### 4.4 維持現狀

- `DetailAccountMediaStateController`：聚焦跨 Detail 畫面的收藏／評分 UI state、樂觀更新回復與錯誤文案，Domain 編排已位於 UseCase。favorite 與 rating 需要獨立生命週期或獨立重用時再另案拆分。
- `LoginViewModel`：credential validation、authentication state 與錯誤 recovery 同屬登入畫面責任。
- `HomeSectionListViewModel`、`SearchResultsViewModel`、`ReviewListViewModel` 的單一 `makeContent`：屬單一畫面內聚 mapping，不另抽 Builder；分頁部分納入 Scope B。
- 其他 ViewModel：無跨層違規（無 UIKit／SwiftUI import、無 Router／`AppComposition`／ViewController／Service Locator 參照、無 concrete Data 型別建立）。

### 4.5 Presentation 對 UIKit 檔案的依賴

依 3.1 的依賴方向規則掃描（指令見 10.3）。v2.5 盤點出三處 Presentation 引用 UIKit 檔案宣告的型別，v2.5–v2.6 已全部處理，掃描結果為空：

| 型別 | 原因 | 處理 |
|------|------|------|
| `MediaGridLayoutMetrics`（v2.5） | 分頁門檻常數與公式放在 View 層的版面常數型別 | 移入 `MediaGridPaginationState`，Controller 預檢改呼叫後者 |
| `BaseDisplayTextFormatter`（v2.6，Presentation 側 169 處引用） | 純文字格式化與兩個以 `UIFont`、`UIColor`、`UIImage` 組 `NSAttributedString` 的 `titleAttributedText` 同檔，整檔 import UIKit | 兩個函式逐行移至新檔 `Feature/Formatter/BaseDisplayTextFormatter+AttributedText.swift`（UIKit extension，呼叫端全在 View），本體改為只 import Foundation |
| `AppSortMenuOption`（v2.6，1 處引用） | 純 protocol 放在 UIKit 工廠檔 `AppFactory.swift` 末端 | 移至 `MediaGridModels.swift`，放在唯一 conform 的 `MediaSortOrder` 旁並標 `nonisolated`；`AppFactory` 的泛型選單改為 View 引用 Presentation |

## 5. Scope A：Presentation Builder 抽離（已實作）

在各 feature 既有 Presentation Models 檔新增 Builder，ViewModel 改由 Builder 取得內容，對 Controller 的 API 不變。v1.1 實作時未新增檔案、未修改 `project.pbxproj`；v2.3 另將 MainMemberSetting 的 Builder 拆為獨立檔（見下方備註）。

| Feature | Builder 介面 | ViewModel 保留 |
|---------|--------------|----------------|
| MainMemberSetting | `MainMemberSettingPresentationBuilder.makeContent(session:profile:appVersion:buildNumber:apiLanguageParameter:localization:)` → `MainMemberSettingContent`（`navigationTitle`、`sections`、`profileSummary`、`guestPrompt`） | 同步 query/action API、session／profile 讀取、refresh／logout／clear action |
| MainSearch | `MainSearchPresentationBuilder.makeDailyTrendingContent(discovery:recentSearchEntries:localization:)`、`makeSearchContent(keyword:page:localization:)` | daily trending cache、state transition、history intent、兩條分頁流程 |
| MainMediaList | `MainMediaListPresentationBuilder.makeContent(genres:selectedGenre:page:selectedSortOption:localization:)`、`makePreviewContent(genres:selectedGenre:selectedSortOption:)` | genre／sort intent、refresh state、分頁流程；`LoadMediaListUseCase` 契約不變 |

實作備註：

- ViewModel 只從 `Bundle` 讀出 `CFBundleShortVersionString`、`CFBundleVersion` 原始值；`"version (build)"` 組合與 `common.value.unknown` fallback 屬顯示文字選擇，由 Builder 承接。v1.0 概念介面為單一 `appVersionText`。
- `MainMemberSettingViewModel` 以 `private lazy var content` 保存 Builder 輸出；init 仍呼叫 `reloadContent()`，session 讀取時機不變，Builder 只執行一次。
- 保留 unique ID 去重、daily trending `.shuffled()`、append 語意與所有取消／過期結果防護。
- `MainSearchContent.appending(...)`、`selectingFilter(...)` 等 immutable transition 留在 Presentation Model。
- v2.3 依 3.3 將 `MainMemberSettingPresentationBuilder` 移至獨立檔 `Main/MainMemberSetting/Presentation/MainMemberSettingPresentationBuilder.swift` 並加入 app target；`MainMemberSettingContent` 仍與其他 Presentation Model 同檔。MainSearch、MainMediaList 的 Builder 各約 50–60 行，維持在原檔。

## 6. Scope B：分頁狀態整併

### 6.1 設計

在既有 `Feature/Components/MediaGrid/Presentation/MediaGridModels.swift` 新增共用值型別。命名沿用 `MediaGridLayoutMetrics`、`MediaGridPaginationTaskController` 的元件前綴。

介面（v2.5 依實作更新）：

```swift
nonisolated struct MediaGridPaginationState: Sendable, Equatable {
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    init(currentPage: Int, totalPages: Int, totalResults: Int, isLoadingNextPage: Bool = false)
    init<Element>(page: Page<Element>)

    var canLoadNextPage: Bool { get }
    var nextPage: Int { get }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MediaGridPaginationState

    static func shouldLoadNextPage(currentIndex: Int, itemCount: Int) -> Bool

    func shouldLoadNextPage<Item: Identifiable>(
        currentItemID: Item.ID,
        items: [Item]
    ) -> Bool
}
```

實例方法 `shouldLoadNextPage` 合併現行三個條件：`canLoadNextPage`、非 loading 中、目前項目已達門檻。門檻常數（倒數第 4 項）與計算公式由 static `shouldLoadNextPage(currentIndex:itemCount:)` 持有；v2.5 前兩者位於 View 層的 `MediaGridLayoutMetrics`，造成 Presentation 依賴 View，已移入本型別，Controller 的預檢也改呼叫此 static 函式。v2.0 概念介面的 `threshold` 參數沒有實作：唯一使用不同門檻的 ReviewList 由 Controller 判斷門檻，ViewModel 端不需要。

設計規則：

- **Content 攜帶狀態的流程**（MainSearch ×2、MainMediaList、MemberCenterList）：Content 以 `pagination` 屬性取代四個分頁欄位。
- 有分頁更新函式的型別（上述 4 個與 `SearchContent`）將 `pagination` 宣告為 `private(set) var`，`updatingLoadingNextPage` 以「複製後修改」實作，不再重列所有欄位；其餘欄位維持 `let`。只作快照的 `HomeSectionListContent`、`ReviewListPresentation` 維持 `let pagination`。
- 只在 Controller 仍讀取的型別保留 `canLoadNextPage`、`isLoadingNextPage` computed forwarding（`MainSearchDailyTrendingContent`、`MainSearchContent`、`SearchContent`、`ReviewListPresentation`），B-1、B-2 不修改 Controller 讀取點；其他型別不留未使用的 forwarding。
- **ViewModel 私有狀態的流程**（HomeSectionList、SearchResults、ReviewList）：以單一 `private var pagination: MediaGridPaginationState` 取代 `currentPage`、`totalPages`、`totalResults`（ReviewList 另含 `isLoadingNextPage`）。
- 各畫面初始值依現況傳入（HomeSectionList `currentPage` 為 1，SearchResults 與 ReviewList 為 0），不統一成單一初始值，避免改變 `canLoadNextPage` 的結果。
- 過期結果檢查仍由 ViewModel 負責：頁碼比對改讀 `pagination.currentPage`；keyword、genre、sort、destination 等身分比對維持各 feature 自行判斷。
- 非同步流程、`Task` 與取消檢查不移入共用型別；不建立泛型 Paginator class 或 protocol（2.3）。

### 6.2 分階段

| Phase | 範圍 | 行為 |
|-------|------|------|
| B-1 | 新增 `MediaGridPaginationState`；遷移 Content 攜帶狀態的 4 條流程（MainSearch ×2、MainMediaList、MemberCenterList） | 不變；不修改 Controller |
| B-2 | 遷移 ViewModel 私有狀態的 HomeSectionList、SearchResults | 不變；不修改 Controller |
| B-3 | 對齊已走樣流程：ReviewList 改用共用狀態與 `currentPage`／`canLoadNextPage` 命名，ViewModel 補 `Task.isCancelled` 與過期結果檢查；MemberCenterList 改用 `MediaGridPaginationTaskController` 與 `MediaGridLayoutMetrics` | **有行為修正**：ReviewList 不再 append 過期頁。需修改 2 個 Controller |

ReviewList 的門檻維持 3，除非產品決定統一為 4。

原規劃 B-3 獨立 commit；2026-09-22 開發者決定與 Scope A、B-1、B-2 合併為單一 commit（見第 13 節），回退方式見第 11 節。

### 6.3 檔案影響

- B-1：`MediaGridModels.swift`；MainSearch、MainMediaList、MemberCenterList 的 Presentation Models 與 ViewModel。
- B-2：HomeSectionList、Search 的 Presentation Models 與 ViewModel。
- B-3：ReviewList 的 Presentation Models、ViewModel 與 Controller；`MemberCenterListViewController`。
- 不修改：`project.pbxproj`、Router、Scene Builder、`AppComposition`、Repository、UseCase。

## 7. Scope C：單元測試（取消）

2026-09-22 決議：授權修改 `project.pbxproj`，但不建立 test target。沒有 test target 就無法執行 unit test，因此 Scope C 取消，v2.0 規劃的 Swift Testing、fake 與測試清單都不實作。

影響：

- 驗證維持 Static、Build、Runtime 三個層級（10.3）；10.2 全部以 Runtime 走查為證據。
- `SDD-CleanArchitecture-Migration.md` §2.3「不建立自動化測試，不新增測試 target」維持有效，不需修訂。
- 原本為測試設計的隨機來源注入沒有使用者，不實作；`.shuffled()` 改列為 3.3 的明列例外。
- Builder 與 `MediaGridPaginationState` 仍維持純函式與 `Sendable` 值型別，日後若改變決議，可直接補上測試。

## 8. Scope D：文件整併

- Part I（第 1–3 節）併入 `SDD-CleanArchitecture-Migration.md` 新章節「ViewModel 責任邊界」；本文件只保留 Part II，並標記 Archived。
- 各 SDD 不重述其他 SDD 的規則，改以章節引用。例如「不引入 Combine」只保留在 Clean Architecture SDD §2.3。
- 新 SDD 以一至兩頁為原則，採 ADR 形式記錄決策、理由與影響；盤點數字標註日期或附上產生指令，避免過時。
- 執行時機：Scope B 完成後，避免 Part I 在實作期間兩處同步修改。

## 9. 非目標

- 不設行數或依賴數門檻。
- 不建立 `BaseViewModel`、ViewModel protocol、泛型 Paginator 或泛型 state machine framework。
- 不導入 Coordinator、Interactor、Redux、TCA、Combine、RxSwift 或第三方 DI（沿用 Clean Architecture SDD §2.3）。
- 不把 UI state、Task 取消或過期結果檢查移入 Domain；UseCase 不回傳 UIKit 型別或 Presentation Model。
- 不改變 TMDB endpoint、分頁參數、搜尋結果順序、`.shuffled()` 行為、快取策略或錯誤文案。Scope B-3 的 ReviewList 過期頁修正是唯一明列的行為變更。
- 不修改畫面、Accessibility、spacing、動畫或互動方式。
- 不新增 SPM package、test target 或其他 Xcode target。
- 不修改第三方套件與 `Package.resolved`。

## 10. 驗收

### 10.1 架構驗收

| ID | 驗收條件 | Scope |
|----|----------|-------|
| SV-01 | 文件、lint 與 code review 不包含 ViewModel 行數硬性限制 | 全部 |
| SV-02 | ViewModel 維持 `@MainActor`，不 import UIKit、Data module path 或第三方 UI 套件 | 全部 |
| SV-03 | Builder 為無狀態純轉換，不執行 I/O、不持有 callback、不修改全域狀態；隨機排序只允許 3.3 明列的例外 | A |
| SV-04 | Builder 與共用值型別的輸入輸出為 `Sendable` 值，不回傳 UIKit 型別 | A、B |
| SV-05 | UI state、Task 取消檢查與分頁過期結果檢查留在 ViewModel／Controller | 全部 |
| SV-06 | 不新增純 Repository pass-through UseCase | 全部 |
| SV-07 | ViewModel 不持有 Router、ViewController、`AppComposition` 或 Service Locator | 全部 |
| SV-08 | concrete dependency 仍只由 `AppComposition` 建立 | 全部 |
| SV-09 | 不新增任何 Xcode target（含 test target）；`project.pbxproj` 只為 app target 增減 Swift 檔；不修改 SPM 與第三方套件 | 全部 |
| SV-10 | 分頁共用邏輯為值型別與純函式，不含 `Task`、async 流程或泛型 Paginator | B |
| SV-11 | 7 條分頁流程皆在 await 後檢查取消與過期結果 | B |

### 10.2 行為驗收矩陣

| Scope | 情境 | 預期 |
|-------|------|------|
| A | MainMemberSetting member | profile、account、data、preferences、about、logout 區段與重構前一致 |
| A | MainMemberSetting guest／logged out | guest、data、preferences、about 區段一致；不顯示 account／logout |
| A | MainMemberSetting refresh／clear／logout | 呼叫相同 protocol／UseCase，成功與失敗處理不變 |
| A | MainSearch 首次 daily trending | recent search、popular people、trending mapping 一致；三類皆空時進入 `.dailyTrendingEmpty` |
| A | MainSearch 搜尋與 filter | 空白 keyword 回復 daily trending；有效 keyword 呈現 results／empty／failed；filter 不重新發 request |
| A | MainMediaList 初始載入 | 依 preferred genre 或第一個 genre 建立內容；無 genre 時呈現 `.empty` |
| A | MainMediaList genre／sort | 先顯示 refreshing preview，再載入第一頁；選取狀態正確 |
| A、B | 所有分頁畫面 | 不重複載入；成功 append；失敗解除 loading flag 並保留既有內容 |
| B | 快速切換 keyword／genre／sort 或重新載入 | 舊頁結果不覆蓋新狀態，包含 ReviewList |
| B | ReviewList 觸發時機 | 維持倒數第 3 項觸發，除非產品另行決定 |

### 10.3 驗證層級

| 層級 | 內容 |
|------|------|
| Static | ViewModel 邊界 grep、`git diff --check`、`swiftc -parse`，以及以 DerivedData 既有套件模組執行的全模組 `swiftc -typecheck`；只證明 source rule、語法與型別，不代表 Build |
| Build | 獨立 DerivedData 的 simulator Debug build |
| Runtime | Simulator 或實機走查 10.2，並觀察快速切換與離開畫面後的 Task 行為 |

```bash
find . -path ./build -prune -o \( -name "*ViewModel.swift" -o -name "*StateController.swift" \) -print \
  | xargs grep -nE "import UIKit|import SwiftUI|AppComposition|ViewController|Router"

git diff --check
```

Presentation 對 UIKit 檔案的依賴（3.1）。以 bash 執行，zsh 不會拆分目錄清單；v2.6 起輸出必須為空：

```bash
PRES_DIRS=$(find . -type d \( -name Presentation -o -name ViewModel \) -not -path './build/*')
UIKIT_TYPES=$(grep -rl --exclude-dir=build '^import UIKit' --include='*.swift' . \
  | xargs grep -hoE "^(nonisolated )?(final )?(struct|enum|class|protocol) [A-Z][A-Za-z0-9]+" \
  | awk '{print $NF}' | sort -u | paste -sd'|' -)
grep -rhowE "$UIKIT_TYPES" --include='*.swift' $PRES_DIRS | sort | uniq -c
```

各層級分別記錄 Passed、Failed 或 NotRun，不得互相替代；未實際操作 Simulator 或實機時，Runtime 必須記為 NotRun。

## 11. 風險

| 風險 | 處理方式 |
|------|----------|
| 為縮短檔案建立大量 wrapper | 依 2.2、2.3 判準；共用邏輯限於值型別與純函式 |
| 分頁整併演變成泛型框架 | SV-10；只抽欄位與純判斷，流程留在各 ViewModel |
| 分頁遷移改變觸發時機或初始值 | 初始值與門檻依現況傳入；B-1、B-2 不修改 Controller |
| ReviewList 過期頁修正影響既有行為 | 行為變更只在 `ReviewListViewModel.loadNextPage()` 的取消與過期檢查。B-3 未獨立 commit，需回退時只移除這兩段檢查與 `isCurrentRequest(mediaID:page:)`，不 revert 整個 commit；Runtime 驗證重新載入與快速捲動 |
| 非同步結果覆蓋新狀態 | 保留既有 cancellation 與身分比對；SV-11 |
| 新增檔案漏 target membership | 預設寫入既有檔案；新增 Swift 檔時同步加入 app target，並以全模組 typecheck 或 Build 確認 |
| 沒有 unit test，mapping 回歸只能靠人工發現 | Builder 維持純函式；10.2 Runtime 走查涵蓋 mapping 與 state transition 項目 |
| 文件與程式碼脫節 | Scope D；盤點數字附日期或產生指令 |

## 12. 完成定義

每個 scope 分別判定，下列條件全部成立才可標記完成：

- source change 完成，或明確記錄經核准縮減的範圍。
- 10.1 中對應該 scope 的項目通過。
- 10.2 中對應該 scope 的情境完成驗證並記錄證據；Static、Build、Runtime 各自標記實際結果。
- 沒有修改未授權的 Xcode project、SPM 或第三方套件。

## 13. 實作狀態

| 項目 | 狀態 | 備註 |
|------|------|------|
| Scope A Phase 0 Baseline | Done | 實作前 working tree 僅有本文件；只修改 6 個既有 Swift 檔 |
| Scope A Phase 1 MainMemberSetting | Implemented（Source） | ViewModel 550 → 178 行 |
| Scope A Phase 2 MainSearch | Implemented（Source） | ViewModel 327 → 298 行 |
| Scope A Phase 3 MainMediaList | Implemented（Source） | ViewModel 268 → 239 行 |
| Scope A Phase 4 Re-audit | Done（v2.0 重做） | 依 2.2 第 6、7 點重新盤點，結果見 4.2–4.4；分頁重複開 Scope B |
| Scope A Static | Passed | ViewModel 邊界 grep 無輸出；`git diff --check` 無輸出；diff 未新增 `// MARK: -` 以外的註解；6 個檔案 `swiftc -parse -swift-version 6` 通過；v2.1 全模組 typecheck 一併通過 |
| Scope A Build | NotRun | 待開發者執行 |
| Scope A Runtime | NotRun | 待開發者走查 10.2 的 Scope A 項目 |
| Scope A Builder 拆檔（v2.3） | Implemented（Source） | 逐行搬移、內容未改；`MainMemberSettingModels.swift` 682 → 217 行，新檔 473 行。`project.pbxproj` 新增 4 筆（PBXBuildFile、PBXFileReference、Presentation group、app target Sources）；`plutil -lint` 通過，解析後確認路徑對應實體檔且屬於 `MyTMDB_App` target；全模組 typecheck 0 error、0 warning |
| Scope B-1 | Implemented（Source） | 新增 `MediaGridPaginationState`；MainSearch ×2、MainMediaList、MemberCenterList 改用 `pagination`；移除 3 份私有 `shouldLoadNextPage` 與 MemberCenterList ViewModel 寫死的 `4`；未修改 Controller |
| Scope B-2 | Implemented（Source） | HomeSectionList、SearchResults 以 `pagination` 取代私有頁碼變數，移除 2 份私有 helper；HomeSectionList 觸發判斷改用 `content.items`（與重新篩選的 `displayedSummaries` 同內容同順序），不再每次呼叫 `FilterMediaByGenreUseCase`；未修改 Controller |
| Scope B-3 | Implemented（Source） | ReviewList 改用共用狀態與 `canLoadNextPage` 命名（Presentation 與 Controller），`loadNextPage()` 補取消與過期檢查：過期或已取消的回應不再 append，也不再記錄 warning；門檻維持 Controller 的 3。MemberCenterList Controller 改用 `MediaGridPaginationTaskController` 與 `MediaGridLayoutMetrics`。`ReviewListViewModel.loadInitialContent(mediaID:)` 同樣未檢查取消，不在 B-3 範圍，未修改。已與其他變更合併提交，見「提交」列 |
| Scope B Static | Passed | 全模組 `swiftc -typecheck`（Swift 6、`-strict-concurrency=complete`、iOS 26 simulator SDK、DerivedData 既有套件模組）0 error、0 warning；ViewModel 邊界 grep 無輸出；`git diff --check` 無輸出；diff 未新增 `// MARK: -` 以外的註解；SV-10、SV-11 source 檢查符合 |
| Scope B Build | NotRun | 待開發者執行 |
| Scope B Runtime | NotRun | 待開發者走查 10.2 的 Scope B 項目，特別是 ReviewList 分頁途中重新載入 |
| Scope C 單元測試 | Cancelled | 2026-09-22 決議不建立 test target，見第 7 節 |
| Scope D 文件整併 | NotStarted | 待 Scope B 完成 Build 與 Runtime 驗證 |
| 提交 | Done | Scope A、B（含 B-3）、Builder 拆檔、註解整理與本文件於 2026-09-22 合併為單一 commit「refactor: 依 SDD 精簡 ViewModel 並整併分頁狀態」；依開發者決定不拆分 B-3 |
| 依賴方向修正（v2.5） | Implemented（Source） | `MediaGridPaginationState` 持有分頁門檻常數與公式；`MediaGridLayoutMetrics` 移除 `paginationThreshold` 與 `shouldLoadNextPage`；5 個 Controller 預檢改呼叫 `MediaGridPaginationState.shouldLoadNextPage(currentIndex:itemCount:)`，門檻值與行為不變。全模組 typecheck 0 error、0 warning；10.3 依賴掃描當時剩 4.5 的兩處，已於 v2.6 處理。尚未提交 |
| 依賴方向修正（v2.6） | Implemented（Source） | `BaseDisplayTextFormatter` 的兩個 `titleAttributedText` 逐行移至新檔 `BaseDisplayTextFormatter+AttributedText.swift`（與 HEAD 比對一致），本體改為只 import Foundation；`AppSortMenuOption` 自 `AppFactory.swift` 移至 `MediaGridModels.swift` 並標 `nonisolated`。`project.pbxproj` 新增 4 筆（PBXBuildFile、PBXFileReference、Formatter group、app target Sources），解析後確認路徑與 target 正確。全模組 typecheck 0 error、0 warning；10.3 依賴掃描為空；Clean Architecture 五項檢查無輸出。尚未提交 |

## 14. 參考文件

- `Docs/SDD-CleanArchitecture-Migration.md`
- `Docs/SDD-Architecture-Unified-Interface-Naming.md`
- Swift API Design Guidelines: <https://swift.org/documentation/api-design-guidelines/>
- Swift 6 Concurrency Migration Guide: <https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/>

---

## 15. 修訂紀錄

| 版本 | 日期 | 內容 |
|------|------|------|
| v1.0 Draft | 2026-09-22 | 建立責任導向 Slim ViewModel 規格；明確排除 150／200 行硬性上限，規劃 MainMemberSetting、MainSearch、MainMediaList 三階段優化 |
| v1.1 | 2026-09-22 | 完成 Phase 0–4 source 實作與靜態再盤點：三個 feature 的 Presentation mapping 移入既有 Presentation Models 檔內的 `nonisolated enum` Builder，ViewModel 保留 state、cache、intent、取消與分頁防護；6.1 介面改為傳入 `appVersion`／`buildNumber` 原始值。Static Verification Passed；Build／Runtime NotRun |
| v2.0 | 2026-09-22 | 依 review 重構：分為 Part I 準則與 Part II 實作；2.2 新增變更頻率與跨畫面重複判準，修正 v1.0 以行數產生候選的做法；新增 Scope B 分頁狀態整併（6 個 ViewModel、7 條流程，含 ReviewList 缺少過期檢查的走樣）、Scope C 單元測試（Swift Testing、隨機來源注入）、Scope D 文件整併；精簡與其他 SDD 重複的規則。僅修改文件，Scope B–D 尚未實作 |
| v2.1 | 2026-09-22 | 完成 Scope B source 實作（B-1–B-3）：新增 `MediaGridPaginationState`，7 條分頁流程改用共用狀態與觸發判斷；ReviewList 補取消與過期檢查並改用 `canLoadNextPage`，MemberCenterList Controller 對齊共用 Task 與門檻。6.1 移除未使用的 `threshold` 參數，forwarding 只保留在 Controller 讀取的型別。全模組 typecheck 通過；Build／Runtime NotRun |
| v2.2 | 2026-09-22 | 依決議取消 Scope C：授權修改 `project.pbxproj`，但不建立 test target。3.3 將 `.shuffled()` 列為 Builder 純度的明列例外，並記錄為 app target 增減 Swift 檔的工程檔授權；移除 Test 驗證層級、測試相關風險與參考；SV-03、SV-09、非目標同步更新。僅修改文件 |
| v2.3 | 2026-09-22 | 依 3.3 與工程檔授權，將 `MainMemberSettingPresentationBuilder` 移至獨立檔並加入 app target（`project.pbxproj` 新增 4 筆，未新增 target）；內容逐行搬移未修改。全模組 typecheck 通過；Build／Runtime NotRun |
| v2.4 | 2026-09-22 | 依實際提交修正：Scope A、B（含 B-3）與註解整理合併為單一 commit，更新 6.2、11 的 B-3 獨立 commit 描述與回退方式；第 5 節區分 v1.1 與 v2.3 的檔案變動；第 13 節新增提交紀錄。僅修改文件 |
| v2.5 | 2026-09-22 | 修正依賴方向：分頁門檻常數與公式自 View 層 `MediaGridLayoutMetrics` 移入 `MediaGridPaginationState`，Controller 預檢改呼叫後者。3.1 新增「Presentation 不依賴 View 層或 UIKit 檔案型別」規則，10.3 新增對應掃描指令，4.5 記錄尚餘的 `BaseDisplayTextFormatter`、`AppSortMenuOption` 兩處。全模組 typecheck 通過；Build／Runtime NotRun |
| v2.6 | 2026-09-22 | 處理 4.5 其餘兩處：`BaseDisplayTextFormatter` 的 attributed text 函式拆至 UIKit extension 新檔，本體只 import Foundation；`AppSortMenuOption` 移至 Presentation 側 `MediaGridModels.swift`。`project.pbxproj` 為新檔新增 4 筆，未新增 target。10.3 依賴掃描改為必須為空；全模組 typecheck 通過；Build／Runtime NotRun |
