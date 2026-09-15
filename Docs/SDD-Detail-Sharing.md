# SDD: CineBase 詳情頁分享功能

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | Swift 6.0，`SWIFT_STRICT_CONCURRENCY = complete` |
| 既有架構 | UIKit + MVVM + Clean Architecture + Router + `AppComposition` |
| 功能範圍 | Movie、TV、Season、Episode 詳情頁分享 |
| 狀態 | Implementation Done；Static Verification Passed；Build、Runtime NotRun |
| 日期 | 2026-09-15 |

---

## 1. 目的

本文件定義 CineBase 詳情頁的分享功能，讓使用者能從電影、影集、季度與單集詳情頁，透過 iOS 系統分享面板分享對應的 TMDB 公開網頁。

本功能需符合下列原則：

- 四種詳情頁提供一致的分享入口與互動。
- 分享內容在未安裝 CineBase 的裝置上仍可使用。
- 分享 presentation 由 Router 負責，ViewModel 不依賴 UIKit。
- URL 組裝集中管理，不在各 ViewController 複製字串。
- 不因分享功能新增不必要的 UseCase、Repository、Service 或 Coordinator。
- 不改變現有收藏、評分、評論、載入與導航行為。

本文件遵循：

- `SDD-Clean-Architecture-Migration.md` 的分層與依賴方向。
- `SDD-Unified-Interface-Naming.md` 的 Swift API、縮寫與 Router 命名規則。

若文件與實際 SDK API 有差異，實作需以 iOS 26 SDK 的編譯結果為準，並回寫本文件，不得以未記錄的替代設計直接落地。

---

## 2. 目標與非目標

### 2.1 目標

- Movie、TV、Season、Episode 詳情頁皆顯示系統分享按鈕。
- 點擊按鈕後顯示 `UIActivityViewController`。
- 分享正確且可公開開啟的 TMDB HTTPS URL。
- iPhone 使用系統 modal presentation；iPad 正確錨定來源按鈕。
- Loading、Loaded、Failed 狀態皆維持可預期行為。
- 使用既有 `DetailRouter` 集中管理系統分享 presentation。
- Season `0`（Specials）可正常分享。
- 無效識別值不得組成或分享錯誤 URL。

### 2.2 非目標

- 不分享 `cinebase://` App Intent URL。
- 不在本階段建立 Universal Links 或 Associated Domains。
- 不分享海報、劇照、影片或其他二進位內容。
- 不下載分享用圖片，不新增網路請求。
- 不自訂 `UIActivityItemSource`、Link Presentation metadata 或分享預覽圖。
- 不自訂可用或排除的 Activity 類型。
- 不追蹤分享渠道，不新增 Analytics。
- 不要求登入，不讀取會員或 Session 資料。
- 不新增 Share Service、Share Repository 或 Share UseCase。
- 不修改底部收藏／評分／評論 Action Bar。
- 不新增第三方套件、SPM package、Xcode target 或測試 target。
- 不修改 `Package.resolved` 或 `project.pbxproj`。
- 不處理既有 `EisodeDetail/` 資料夾拼字。

---

## 3. 現況盤點

### 3.1 詳情頁輸入

| 畫面 | 現有定位資料 | 現況 |
|------|--------------|------|
| `MovieDetailViewController` | `movieID` | Controller 已持有 |
| `TVDetailViewController` | `seriesID` | Controller 已持有 |
| `SeasonDetailViewController` | `seriesID`、`seasonNumber` | Controller 已持有 |
| `EpisodeDetailViewController` | `EpisodeDetailInput` | 目前只有 ViewModel 持有，Controller 尚未持有 |

`EpisodeDetailInput` 已包含：

```swift
struct EpisodeDetailInput {
    let seriesID: Int
    let seasonNumber: Int
    let episodeNumber: Int
}
```

Episode 實作時應由 `AppComposition` 將既有的同一份 `EpisodeDetailInput` 同時注入 ViewModel 與 ViewController。不得讓 ViewController 反向讀取 ViewModel 的 private input，也不得為了分享將 UIKit 關注點放入 ViewModel。

### 3.2 既有 Router

- Movie、TV、Season 使用 feature-specific Router，再轉發共用操作給 `DetailRouter`。
- Episode 直接以 `DetailRouting` 持有 `DetailRouter`。
- `DetailRouter` 已集中管理詳情頁共用的 push、present、page sheet 與全螢幕導航。
- `BaseRouter` 已具備安全尋找 top presenter 的 presentation 流程。

分享屬於系統畫面的 App 內 presentation，因此應加入 `DetailRouting`／`DetailRouter`，不由 ViewController 直接呼叫 `present(...)`。

### 3.3 既有 URL 設定

`TMDBResourceURL` 已集中管理：

- TMDB website base URL。
- TMDB image URL。
- Gravatar URL。
- TMDB signup URL。

分享 URL 應延伸同一型別，不新增第二個 TMDB 網址常數或 `ShareURLFactory`。

### 3.4 分享按鈕位置

Movie、TV、Episode 使用的底部 Action Bar 承載帳號相關操作；Season 沒有底部 Action Bar。若將分享加入底部元件，會造成四種畫面互動不一致，並讓 Episode 的按鈕配置與版面寬度產生額外變更。

因此四種詳情頁統一使用 Navigation Bar trailing share button，不修改 `DetailBottomActionBarView`。

---

## 4. 使用者體驗規格

### 4.1 入口

- 位置：詳情頁 Navigation Bar 右側。
- 圖示：系統 Share／Action 圖示，語意為 `square.and.arrow.up`。
- 外觀：沿用 Navigation Bar 與專案既有 tint color，不建立自訂分享 icon。
- Movie、TV、Season、Episode 使用相同圖示與互動。

Apple Human Interface Guidelines 建議使用標準 Share 按鈕開啟 Activity View，避免以自訂圖示表達相同功能。

### 4.2 可用狀態

分享 URL 只依賴初始化時已知的識別值，因此不需要等待 API 載入完成：

| 畫面狀態 | 分享按鈕 |
|----------|----------|
| Idle | 有效 input 時可用 |
| Loading | 有效 input 時可用 |
| Loaded | 有效 input 時可用 |
| Failed | 有效 input 時可用 |
| 無效 input | 不顯示或 disabled；不得開啟空白分享頁 |

實作統一採「有效時 enabled、無效時 disabled」，讓 Navigation Bar 結構保持穩定，不因狀態切換增減按鈕。

### 4.3 點擊行為

1. ViewController 依畫面定位資料向 `TMDBResourceURL` 取得 URL。
2. URL 建立失敗時直接返回，不顯示 Activity View。
3. URL 建立成功時，交由 Router 顯示 `UIActivityViewController`。
4. Activity items 第一階段只包含一個 `URL`。
5. 使用者完成、取消或 Activity 失敗後，不修改任何 ViewModel state。
6. 同一時間若已存在其他 presented ViewController，沿用 `BaseRouter` 的 top presenter 行為。

### 4.4 iPhone 與 iPad

- iPhone：使用系統預設 modal 行為。
- iPad：必須以觸發分享的 `UIBarButtonItem` 設定 popover source item／bar button item。
- 不得以任意畫面中央座標作為 Navigation Bar 分享按鈕的 popover anchor。
- 若 SDK API 名稱有版本差異，以 iOS 26 SDK 可編譯且能錨定 `UIBarButtonItem` 的 API 為準。

---

## 5. 分享 URL 規格

### 5.1 Canonical URL

| 類型 | URL |
|------|-----|
| Movie | `https://www.themoviedb.org/movie/{movieID}` |
| TV | `https://www.themoviedb.org/tv/{seriesID}` |
| Season | `https://www.themoviedb.org/tv/{seriesID}/season/{seasonNumber}` |
| Episode | `https://www.themoviedb.org/tv/{seriesID}/season/{seasonNumber}/episode/{episodeNumber}` |

URL 不加入：

- title slug。
- language query。
- API key。
- Session ID。
- account ID。
- tracking query。

不使用 title slug 可避免顯示名稱、翻譯或名稱變更影響分享網址。TMDB 仍可依資源 ID 導向正確頁面。

### 5.2 驗證規則

| 值 | 有效條件 |
|----|----------|
| `movieID` | `> 0` |
| `seriesID` | `> 0` |
| `seasonNumber` | `>= 0` |
| `episodeNumber` | `> 0` |

`seasonNumber == 0` 代表 Specials，屬有效值。

### 5.3 `TMDBResourceURL` 目標介面

```swift
nonisolated enum TMDBResourceURL {

    static func movie(id: Int) -> URL?

    static func tvSeries(id: Int) -> URL?

    static func season(
        seriesID: Int,
        seasonNumber: Int
    ) -> URL?

    static func episode(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) -> URL?
}
```

命名依 `SDD-Unified-Interface-Naming.md`：

- 方法名稱已指出實體時使用 `id`，例如 `movie(id:)`、`tvSeries(id:)`。
- Season／Episode 同時需要多個識別值，因此使用具名 `seriesID`。
- Swift identifier 使用 `URL`、`ID`、`TV`，不使用 `Url`、`Id`、`Tv`。

`TMDBResourceURL` 僅負責建立公開資源 URL，不包含 presentation 或 Activity View 邏輯。

---

## 6. 架構與責任分工

### 6.1 資料流

```text
使用者點擊 Navigation Bar Share
    ↓
Detail ViewController 組合畫面定位參數
    ↓
TMDBResourceURL 驗證並建立公開 HTTPS URL
    ↓
Feature Router 轉發（Movie／TV／Season）
或 DetailRouter 直接處理（Episode）
    ↓
DetailRouter 建立 UIActivityViewController
    ↓
BaseRouter 顯示系統分享面板
```

### 6.2 ViewController

負責：

- 建立 Navigation Bar share button。
- 保存該畫面既有的不可變定位 input。
- 在點擊時取得對應 URL。
- 將 URL 與 source item 傳給 Router。

不負責：

- 直接 `present(UIActivityViewController)`。
- 下載或加工分享資料。
- 修改 ViewModel state。
- 判斷登入狀態。

### 6.3 Router

`DetailRouting` 增加：

```swift
func showShareSheet(
    for url: URL,
    sourceItem: UIBarButtonItem
)
```

方法使用 `show`，因為它是 App 內 presentation；不用 `open`，`open` 保留給 Safari 或外部 URL。

`DetailRouter` 負責：

- 建立 `UIActivityViewController(activityItems: [url], applicationActivities: nil)`。
- 設定 iPad popover anchor。
- 透過既有 `show(_:using:)` presentation 流程顯示。

Movie、TV、Season 的 `...Routing` protocol 與 Router implementation 增加相同的 `showShareSheet(for:sourceItem:)`，並轉發給 `DetailRouter`。Episode 已依賴 `DetailRouting`，不新增只含轉發功能的 `EpisodeDetailRouter`。

### 6.4 ViewModel

ViewModel 不變更。

理由：

- 分享 URL 不依賴非同步內容。
- 分享不產生 Domain state。
- `UIActivityViewController` 是 UIKit presentation concern。
- 將分享加入 ViewModel 會造成 UIKit 或 URL presentation 責任反向滲入 Presentation state。

### 6.5 UseCase、Repository、Service

不新增。

建立固定 URL 與顯示系統面板沒有業務編排、跨 Repository 操作或降級策略，不符合專案建立 UseCase 的判準。增加 Share UseCase／Service 只會形成轉呼叫抽象。

### 6.6 AppComposition

Movie、TV、Season factory 不變。

Episode factory 將既有 input 同時傳給 Controller：

```swift
return EpisodeDetailViewController(
    input: input,
    viewModel: viewModel,
    sceneBuilder: self
)
```

Controller initializer 目標形式：

```swift
init(
    input: EpisodeDetailInput,
    viewModel: EpisodeDetailViewModel,
    sceneBuilder: DetailSceneBuilding
)
```

這是 immutable value 的注入，不新增依賴容器或 factory protocol。

---

## 7. UI API 目標形狀

四個 ViewController 各自保留對應 URL 參數差異，共用一致的按鈕與 Router 呼叫語意。

概念範例：

```swift
private lazy var shareBarButtonItem = UIBarButtonItem(
    image: UIImage(systemName: "square.and.arrow.up"),
    primaryAction: UIAction { [weak self] _ in
        self?.handleShareButtonTapped()
    }
)

private func configureShareButton() {
    navigationItem.rightBarButtonItem = shareBarButtonItem
    shareBarButtonItem.isEnabled = shareURL != nil
}

private func handleShareButtonTapped() {
    guard let shareURL else { return }
    router.showShareSheet(for: shareURL, sourceItem: shareBarButtonItem)
}
```

此範例只定義 API 形狀。實作時可將 URL 計算屬性命名為 `shareURL`，但不得在多個 Controller 中複製 base URL 或 path 字串。

若 Navigation Bar 未來同時存在其他 trailing item，實作需以 `rightBarButtonItems` 合併，不得覆蓋既有功能。目前四個目標詳情頁沒有既有 trailing item。

---

## 8. 檔案影響範圍

| 檔案 | 變更 |
|------|------|
| `Feature/Config/TMDBResourceURL.swift` | 新增四種公開資源 URL builder |
| `Feature/Base/DetailBase/Router/DetailRouter.swift` | 新增共用分享介面與系統分享 presentation |
| `MovieDetail/Router/MovieDetailRouter.swift` | protocol 與 implementation 轉發分享 |
| `TVDetail/Router/TVDetailRouter.swift` | protocol 與 implementation 轉發分享 |
| `SeasonDetail/Router/SeasonDetailRouter.swift` | protocol 與 implementation 轉發分享 |
| `MovieDetail/Controller/MovieDetailViewController.swift` | 新增分享按鈕與 Movie URL |
| `TVDetail/Controller/TVDetailViewController.swift` | 新增分享按鈕與 TV URL |
| `SeasonDetail/Controller/SeasonDetailViewController.swift` | 新增分享按鈕與 Season URL |
| `EisodeDetail/Controller/EpisodeDetailViewController.swift` | 保存 input，新增分享按鈕與 Episode URL |
| `MyTMDB_App/Composition/AppComposition.swift` | 將既有 Episode input 注入 Controller |

不新增檔案，因此不應產生 `project.pbxproj` target membership 變更。

---

## 9. 實作順序

### Phase 1 — URL builder

1. 在 `TMDBResourceURL` 新增 Movie、TV、Season、Episode URL builder。
2. 套用 5.2 的識別值驗證。
3. 確認 URL 不含 API key、session、slug 或 tracking query。

### Phase 2 — 共用 Router presentation

1. 在 `DetailRouting` 新增 `showShareSheet(for:sourceItem:)`。
2. 在 `DetailRouter` 建立 `UIActivityViewController`。
3. 設定 iPad popover source item。
4. 在 Movie、TV、Season Router protocol／implementation 加入轉發。

### Phase 3 — 四個分享入口

1. Movie ViewController 加入分享按鈕。
2. TV ViewController 加入分享按鈕。
3. Season ViewController 加入分享按鈕。
4. Episode ViewController 接收 `EpisodeDetailInput` 並加入分享按鈕。
5. `AppComposition` 傳入既有 Episode input。

### Phase 4 — 驗證

1. 執行 source diff 與命名檢查。
2. 執行 Swift parser／編譯檢查。
3. 經明確授權後執行 Xcode Build。
4. 經明確授權後執行 Simulator／實機 runtime 驗收。

---

## 10. 驗收規格

### 10.1 功能矩陣

| Case | 預期結果 |
|------|----------|
| Movie `movieID = 550` | 分享 `https://www.themoviedb.org/movie/550` |
| TV `seriesID = 1399` | 分享 `https://www.themoviedb.org/tv/1399` |
| Season `seriesID = 1399, seasonNumber = 1` | 分享 `https://www.themoviedb.org/tv/1399/season/1` |
| Specials `seriesID = 1399, seasonNumber = 0` | 分享 `https://www.themoviedb.org/tv/1399/season/0` |
| Episode `1399 / 1 / 1` | 分享 `https://www.themoviedb.org/tv/1399/season/1/episode/1` |
| 任一主要 ID `<= 0` | 按鈕 disabled，不顯示分享面板 |
| Season `< 0` | 按鈕 disabled，不顯示分享面板 |
| Episode `<= 0` | 按鈕 disabled，不顯示分享面板 |

### 10.2 UI 驗收

- 四種詳情頁 Navigation Bar 右側皆顯示相同分享圖示。
- 點擊後顯示系統 Activity View。
- Copy activity 得到與 10.1 相同的完整 URL。
- 取消分享後仍停留在原詳情頁。
- 重複開啟與關閉不會卡住或重複 present。
- Loading 與 Failed 畫面仍能分享有效 URL。
- 原有 favorite、rating、review、video、image preview 與頁面導航不退化。

### 10.3 裝置驗收

- iPhone portrait：Activity View 正常顯示與關閉。
- iPhone landscape：Activity View 正常顯示與關閉。
- iPad regular width：popover 指向 Navigation Bar 分享按鈕且不崩潰。
- iPad 分割畫面：popover anchor 仍正確。

### 10.4 帳號狀態

下列狀態結果必須相同：

- Logged out。
- Guest session。
- User session。

分享不得觸發登入頁或帳號 API。

---

## 11. 靜態檢查與驗證邊界

### 11.1 Source 檢查

```bash
rg -n "UIActivityViewController|showShareSheet|shareBarButtonItem" \
  Feature MovieDetail TVDetail SeasonDetail EisodeDetail

rg -n "cinebase://|api_key|session_id" \
  Feature/Config/TMDBResourceURL.swift

rg -n "import UIKit" \
  MovieDetail/ViewModel TVDetail/ViewModel SeasonDetail/ViewModel EisodeDetail/ViewModel

git diff --check
```

預期：

- 分享 presentation 只出現在 Router／Controller UI 邊界。
- ViewModel 不新增 UIKit import。
- 分享 URL 不包含 custom scheme、API key 或 session。
- diff 無 whitespace error。

### 11.2 Build

Build 必須獨立回報，不得以 `swiftc -parse`、`plutil -lint` 或靜態搜尋取代。

建議命令：

```bash
xcodebuild \
  -project MyTMDB_App.xcodeproj \
  -scheme MyTMDB_App \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath /tmp/MyTMDB_AppShareDerivedData \
  build
```

Build 前後需確認未修改：

- `MyTMDB_App.xcodeproj/project.pbxproj`
- `Package.resolved`
- 第三方套件版本

### 11.3 Runtime

Build 成功不等於分享功能已完成。10.2、10.3、10.4 必須以 Simulator 或實機操作驗證後，才能將 Runtime 狀態標為 Passed。

---

## 12. 風險與處理

| 風險 | 影響 | 處理方式 |
|------|------|----------|
| iPad 未設定 popover anchor | 點擊分享可能崩潰 | `DetailRouter` 必須使用觸發的 `UIBarButtonItem` 作為 source item |
| Episode Controller 缺少定位 input | 無法建立正確 URL | 由 `AppComposition` 注入既有 `EpisodeDetailInput` |
| 將分享放進 ViewModel | UIKit 責任跨層 | ViewModel 不變更，presentation 留在 Router |
| 使用 `cinebase://` | 未安裝 App 的接收方無法開啟 | MVP 只分享 TMDB HTTPS URL |
| 分享 title／poster | 增加非同步狀態與預覽不確定性 | 第一階段只傳 `URL` |
| Season `0` 被當作無效 | Specials 無法分享 | 驗證明確使用 `seasonNumber >= 0` |
| 覆蓋既有右側按鈕 | 其他功能消失 | 設定前檢查現有 trailing items，必要時合併 |
| 新增 Router 抽象過度 | 維護成本上升 | 共用 `DetailRouter`，Episode 不新增轉發 Router |
| 誤動 Xcode 專案檔 | 工作樹或 target membership 退化 | 僅修改既有 Swift 檔，不修改 `project.pbxproj` |

---

## 13. 完成定義

只有同時滿足下列條件，功能才能標為完成：

- 四種詳情頁皆有一致的 Navigation Bar 分享按鈕。
- 四種 URL 與輸入驗證符合第 5 節。
- 分享 payload 僅包含公開 HTTPS URL。
- `DetailRouter` 集中管理 `UIActivityViewController`。
- Episode input 經 `AppComposition` 注入 Controller。
- ViewModel、UseCase、Repository、Service 無不必要變更。
- Source 檢查通過。
- Xcode Build 通過並獨立記錄結果。
- iPhone 與 iPad runtime 驗收通過並獨立記錄結果。
- `project.pbxproj`、SPM 與既有功能沒有非預期變更。

---

## 14. 實作狀態

截至 2026-09-15：

- Design：Ready。
- Source Implementation：Done（依第 8 節檔案範圍，未新增檔案，未修改 `project.pbxproj`）。
- Static Verification：Passed（11.1 source 檢查、`git diff --check`、`swiftc -parse`；`TMDBResourceURL` 以獨立腳本驗證 10.1 全部 URL 與無效輸入回傳 `nil`）。
- Xcode Build：NotRun。
- Runtime／UI：NotRun。
- Simulator／Device：NotRun。

本文件建立不代表功能已實作或通過驗收。每個狀態只能在取得對應證據後更新。

---

## 15. 參考資料

- [Apple Human Interface Guidelines — Activity views](https://developer.apple.com/design/human-interface-guidelines/activity-views)
- [Apple Human Interface Guidelines — Collaboration and sharing](https://developer.apple.com/design/human-interface-guidelines/collaboration-and-sharing)
- [Apple Developer Documentation — UIActivityViewController](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller)
- [TMDB Movie URL example](https://www.themoviedb.org/movie/550)
- [TMDB TV URL example](https://www.themoviedb.org/tv/1399)
- [TMDB Season URL example](https://www.themoviedb.org/tv/1399-game-of-thrones/season/1)
- [TMDB Episode URL example](https://www.themoviedb.org/tv/1399-game-of-thrones/season/1/episode/1)
