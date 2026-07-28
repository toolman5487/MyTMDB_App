# SDD：Apple Intelligence / Siri / App Intents 整合

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document（軟體設計說明） |
| App | CineBase（`MyTMDB_App`） |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 18.4+（iPhone / iPad） |
| UI | UIKit + MVVM |
| 狀態 | Draft |
| 日期 | 2026-07-28 |

---

## 1. 目的

讓使用者可透過 **Siri、Shortcuts、Spotlight、Action Button** 操作 CineBase 的核心能力（以收藏為首波），並逐步支援 **螢幕感知（on-screen awareness）** 與可選的 **跨 App 內容傳遞（Transferable）**。

本文件定義：

- 技術選用與不做什麼
- 系統架構與模組邊界
- AppEntity / App Intent / 螢幕綁定設計
- 與現有 TMDB 收藏流程的整合方式
- 分階段實作與驗收標準

---

## 2. 背景與現況

### 2.1 現有能力

- 電影／影集詳情頁可 **加入／取消收藏**（TMDB Account Favorite API）
- 會員中心可瀏覽收藏電影／影集列表
- Session 存於 `SessionStore`（`UserDefaults`）
- 收藏本體在 **TMDB 雲端**，非本地 DB

關鍵路徑：

```text
UI (Detail VC)
  → ViewModel
    → DetailAccountMediaStateController
      → MemberCenterServicing.updateFavorite
        → NetworkService → POST /account/{id}/favorite
```

### 2.2 現況缺口

| 能力 | 狀態 |
|------|------|
| App Intents / App Shortcuts | 無 |
| AppEntity / App Schemas | 無 |
| NSUserActivity / Spotlight 綁定 | 無 |
| List Location / View Annotation | 無 |
| Transferable | 無 |
| Siri entitlement / Info.plist 說明 | 無 |

### 2.3 產品約束

- 收藏需 **TMDB user session**（guest / loggedOut 不可用）
- 需網路；離線操作應回傳可理解錯誤
- Siri 自然語言與螢幕感知 **目前系統仍不穩定**，不可作為唯一可靠入口

---

## 3. 範圍

### 3.1 In Scope（第一～二波）

1. AppEntity：`MovieEntity`、`TVSeriesEntity`
2. App Intent：打開收藏、加入／取消收藏、打開詳情
3. `AppShortcutsProvider`（固定觸發片語）
4. 詳情頁 `NSUserActivity` 綁定單一 entity
5. 列表頁 List Location（首波至少會員中心收藏列表；可延伸搜尋／首頁 grid）
6. Siri capability、必要 Info.plist key、錯誤與未登入處理

### 3.2 Out of Scope（本 SDD 不強制）

- 硬套 Photos／Audio／Reminders 等不匹配的 App Schema domain
- 逐 cell 大量 View↔Entity annotation（UICollectionView reuse 場景）
- Watchlist UI 完整產品化（Service 已有 API，Intent 可列為可選延伸）
- Widget / Control Center
- 本地收藏 DB 取代 TMDB

### 3.3 可選延伸（第三波）

- `Transferable` 跨 App 傳遞 Movie／TV entity
- 若 Apple 日後提供更貼合影音收藏的 Schema，再遷移既有 Intent
- Person entity、評分 Intent、片單 Intent

---

## 4. 設計原則

1. **Intent 不綁 UIKit VC／`@MainActor` Detail controller**  
   業務寫入走 `MemberCenterServicing` + `SessionStore` + `AccountServiceProtocol`。
2. **可靠路徑優先於炫技路徑**  
   App Shortcuts 固定片語 > 自然語言 Schema > 螢幕感知。
3. **依畫面複雜度選綁定技術**  
   - 單 entity 詳情 → `NSUserActivity`  
   - 大量動態列表 → **List Location**  
   - 少數靜態 view → 個別 annotation（本 App 少用）
4. **App Schema 能對才對，不能硬套**  
   Schema 本質仍是 App Intent；無匹配 domain 時用自訂 Intent。
5. **遵守專案 Swift 6 / MVVM／Sendable 規範**  
   非 UI 邏輯避免無必要 `MainActor`；依賴以 protocol 注入。

---

## 5. 技術選用決策

| 技術 | 決策 | 理由 |
|------|------|------|
| **AppEntity** | **採用（核心）** | 結構化表示 Movie／TV；供 Intent 參數、Spotlight、螢幕感知 |
| **App Intent** | **採用（核心）** | 暴露動作給 Siri／Shortcuts／Spotlight |
| **App Schemas** | **觀望／不硬套** | Apple 已定義多種 schema（如 Reminders、Mail、Photos、Audio）；目前無貼合「TMDB 電影收藏」的 domain |
| **App Shortcuts** | **採用** | 提供穩定觸發片語與發現性 |
| **NSUserActivity** | **採用（詳情頁）** | 適合「畫面只有一個 entity」；支援「這是什麼？」類查詢 |
| **個別 View↔Entity 綁定** | **原則不用於 grid** | 數百 cell + reuse 成本高、位置會變 |
| **List Location** | **採用（列表頁）** | 一次宣告整份 list；Siri 需要時再向 App 查細節／執行動作 |
| **Transferable** | **第三波可選** | 跨 App 傳遞 entity；非收藏操作必要條件 |
| **舊版 SiriKit Intent Definition** | **不採用** | 以 App Intents 為唯一整合路徑 |

### 5.1 三種畫面複雜度對應（本專案落地）

| 複雜度 | 做法 | CineBase 對應畫面 |
|--------|------|-------------------|
| (1) 單 entity | `NSUserActivity` 綁定 App + entity | `MovieDetailViewController`、`TVDetailViewController` |
| (2) 少數 view 個別綁定 | 每 view 綁 entity identifier | 暫不優先（無合適靜態多 entity 主畫面） |
| (3) 大量動態資料 | **List Location** | 會員中心收藏列表、搜尋結果、首頁／分類 grid |

> 注意：螢幕感知與「更新第 N 筆」類體驗目前系統可能不穩定；實作後需人工驗證，失敗時仍應保證 Shortcuts Intent 可用。

---

## 6. 高層架構

```text
┌─────────────────────────────────────────────────────────────┐
│  System Surfaces                                            │
│  Siri / Shortcuts / Spotlight / Action Button / (未來跨 App) │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│  Feature/AppIntents/                                        │
│  - Entities (MovieEntity, TVSeriesEntity)                   │
│  - Intents (Open*, UpdateFavorite*, …)                      │
│  - Queries / Entity resolution                              │
│  - AppShortcutsProvider                                     │
│  - OnScreen (NSUserActivity helpers, List Location adapters)│
│  - Transferable (optional)                                  │
└───────────────────────────┬─────────────────────────────────┘
                            │ depends on
┌───────────────────────────▼─────────────────────────────────┐
│  Existing Domain Layer（不改業務語意，僅必要擴充 DI）         │
│  - MemberCenterServicing                                    │
│  - SessionStoring / AuthSession                             │
│  - AccountServiceProtocol                                   │
│  - MovieSearchServicing / TVSearchServicing（解析片名）       │
│  - DetailRouter / MemberCenter 導航入口（開畫面 Intent）      │
└─────────────────────────────────────────────────────────────┘
```

### 6.1 依賴規則

- `AppIntents` 模組可依賴 Service / Model / Session
- Service **不可** 反向依賴 App Intents
- 開畫面類 Intent 透過薄薄的 `@MainActor` Navigator／Deep Link helper 進入既有 Router，避免 Intent 直接操作複雜 VC 生命週期細節

---

## 7. 資料設計：AppEntity

### 7.1 MovieEntity

| 屬性 | 型別 | 說明 |
|------|------|------|
| `id` | `Int`（EntityIdentifier） | TMDB movie id |
| `title` | `String` | 顯示標題 |
| `originalTitle` | `String?` | 原始片名（可選） |
| `overview` | `String?` | 簡介（螢幕／Siri 回答用） |
| `posterPath` | `String?` | 海報 path（組 URL 用） |
| `releaseYear` | `String?` | 年份輔助消歧 |

建議：

- 實作 `AppEntity`
- 實作 query（至少 `EntityStringQuery` 或專案搜尋 API 包裝）
- 若要語意檢索／Spotlight：評估 `IndexedEntity`（第二波）

### 7.2 TVSeriesEntity

對齊 MovieEntity 欄位語意（`name`／`firstAirYear` 等），id 為 TMDB tv id。

### 7.3 App Schema 對應策略

```text
IF 存在語意匹配的系統 Schema
  THEN 以 @AssistantIntent / schema 採用該契約
ELSE
  使用自訂 AppIntent + 清楚 title/description/參數
  並透過 AppShortcuts 提供可發現觸發片語
```

本專案首波預設走 **ELSE**。  
不要為了「接 Schema」而把電影映射成 Photo Asset 或 Audio Track。

---

## 8. Intent 設計

### 8.1 首波 Intent 清單

| Intent | 類型 | 參數 | 前置條件 | 結果 |
|--------|------|------|----------|------|
| `OpenFavoriteMoviesIntent` | Open | 無 | 建議已登入 | 開啟收藏電影列表 |
| `OpenFavoriteTVIntent` | Open | 無 | 建議已登入 | 開啟收藏影集列表 |
| `AddMovieToFavoritesIntent` | Action | `MovieEntity` | user session | 設 `favorite=true` |
| `RemoveMovieFromFavoritesIntent` | Action | `MovieEntity` | user session | 設 `favorite=false` |
| `AddTVSeriesToFavoritesIntent` | Action | `TVSeriesEntity` | user session | 設 `favorite=true` |
| `RemoveTVSeriesFromFavoritesIntent` | Action | `TVSeriesEntity` | user session | 設 `favorite=false` |
| `OpenMovieDetailIntent` | Open | `MovieEntity` | 無 | 開啟電影詳情 |
| `OpenTVSeriesDetailIntent` | Open | `TVSeriesEntity` | 無 | 開啟影集詳情 |

可合併設計：以單一 `UpdateFavoriteIntent` + `favorite: Bool` + `mediaType`，但對外 Shortcuts 顯示名稱需清楚（建議對使用者暴露「加入／移除」兩個捷徑）。

### 8.2 執行流程（收藏寫入）

```text
1. 讀取 SessionStore.load()
2. 若非 .user → 回傳「需要登入」對話結果，必要時 opensIntent 導向登入
3. AccountService.fetchAccount(sessionId) 取得 accountId
4. MemberCenterService.updateFavorite(accountId, sessionId, request)
5. 依 response.success 回傳成功／失敗 dialog
```

重用既有型別：

- `MemberCenterFavoriteStatusRequest`
- `MemberCenterAccountMediaType`（`.movie` / `.tv`）
- `MemberCenterFavoriteStatusResponse`

**禁止** 從 Intent 呼叫 `DetailAccountMediaStateController.toggleFavorite`（該類綁 UI 狀態機與 `@MainActor`）。

### 8.3 開畫面流程

```text
1. Intent.perform
2. 透過 App 內 Deep Link / IntentNavigator 解析 destination
3. 切到對應 Tab（會員中心／詳情 push）
4. 以既有 MemberCenterRouter / DetailRouter 呈現
```

建議 destination 枚舉（內部用）：

```text
AppIntentDestination
  - favoriteMovies
  - favoriteTV
  - movieDetail(id)
  - tvDetail(id)
  - login
```

對齊既有 `MemberCenterDestination` 時優先複用，避免平行語意。

### 8.4 App Shortcuts（示例片語）

以繁中為主（實作時再微調，避免過度承諾同義句）：

- 「用 CineBase 打開我的收藏電影」
- 「用 CineBase 打開我的收藏影集」
- 「用 CineBase 收藏這部電影」（需 entity 解析或螢幕上下文）
- 「用 CineBase 打開電影詳情」

未登入時 Shortcuts 仍應可發現，執行時給明確失敗原因。

---

## 9. 螢幕感知設計

### 9.1 詳情頁：NSUserActivity

適用：`MovieDetailViewController`、`TVDetailViewController`。

作法：

1. 詳情載入成功後建立／更新 `NSUserActivity`
2. 將對應 `MovieEntity`／`TVSeriesEntity` 與 activity 關聯（依當前系統 API）
3. `viewController.userActivity = activity`；於消失／切換時失效或更新

預期體驗（系統允許時）：

- 使用者看著詳情頁問「這是什麼？」
- Siri 能回答標題、類型（電影／影集）等 entity 資訊

### 9.2 列表頁：List Location

適用：

- `MemberCenterListViewController`（收藏／待看等）
- 之後：搜尋結果、首頁 section grid

作法概念：

1. 將目前可見／已載入的 list 資料以系統定義的 List Location 機制宣告給 Siri
2. Siri 需要細節或執行動作時，再 callback 向 App 查詢第 N 筆／某 identifier
3. App 回傳對應 entity 或執行 UpdateFavorite 等 Intent

實作注意：

- 必須處理分頁：List Location 的「第 2 筆」應對齊 **目前提供給系統的那份 snapshot**，文件中明確定義索引基準（可見區 vs 已載入全量）
- cell reuse **不** 用個別 view annotation 硬扛
- 接受系統回應文案可能暫時不穩；App 側仍須正確執行業務

### 9.3 個別 View Annotation

本專案 **預設不做** 全 grid 逐 cell 綁定。  
僅在未來出現少量固定 view（例如英雄區 1～3 個精選）時再評估。

---

## 10. Transferable（第三波）

目標：讓其他 App／系統流程可接收 CineBase 的 Movie／TV 內容表示。

建議：

- `MovieEntity`／`TVSeriesEntity` 提供 `Transferable` 表示（至少純文字片名 + TMDB URL；可再加 JSON）
- 與分享列／跨 App「用這個 entity 做事」場景對齊

非首波 blocker。

---

## 11. 認證、錯誤與對話回饋

| 情境 | 行為 |
|------|------|
| `.loggedOut` / `.guest` | 不可寫入收藏；回傳需登入；可提供開啟登入 Intent／畫面 |
| 網路錯誤 | 回傳短暫失敗訊息，不靜默失敗 |
| TMDB `success == false` | 顯示 `statusMessage` |
| 找不到片名／entity | 請使用者改說完整片名或先開啟詳情頁再操作 |
| media id ≤ 0 | 參數無效錯誤 |

錯誤文案風格對齊既有：

- 「需要登入」／「請登入 TMDB 帳號後再使用收藏功能。」
- 「收藏失敗」＋伺服器訊息

---

## 12. 專案檔案與設定變更

### 12.1 建議目錄

```text
Feature/AppIntents/
  Entities/
    MovieEntity.swift
    TVSeriesEntity.swift
  Intents/
    OpenFavoriteMoviesIntent.swift
    OpenFavoriteTVIntent.swift
    UpdateMovieFavoriteIntent.swift
    UpdateTVSeriesFavoriteIntent.swift
    OpenMovieDetailIntent.swift
    OpenTVSeriesDetailIntent.swift
  Queries/
    MovieEntityQuery.swift
    TVSeriesEntityQuery.swift
  Shortcuts/
    CineBaseAppShortcuts.swift
  Navigation/
    AppIntentNavigator.swift
  OnScreen/
    DetailUserActivityFactory.swift
    MemberCenterListLocationSupport.swift
  Support/
    AppIntentSessionResolver.swift   // Session + accountId
    AppIntentDependencyContainer.swift
```

### 12.2 Xcode / Info 設定

- 新增 App 的 Siri capability（entitlements）
- `Info.plist`：視需求加入 Siri／App Intents 相關使用說明 key
- 將新 Swift 檔加入 app target
- 確認 deployment target 維持 **18.4+**

### 12.3 既有檔案可能的最小改動

| 檔案／區域 | 改動性質 |
|------------|----------|
| `MovieDetailViewController` | 載入成功後掛 `NSUserActivity` |
| `TVDetailViewController` | 同上 |
| `MemberCenterListViewController` | 接入 List Location |
| `SceneDelegate`／App 啟動 | 註冊 Intent 導航入口（若需要） |
| DI／組裝處 | 提供 Intent 可用的 service 實例 |

避免為了 Intent 重構整條 Detail MVVM；只做必要掛鉤。

---

## 13. 與現有程式碼對照

| 用途 | 既有位置 |
|------|----------|
| 更新收藏 | `MemberCenter/Service/MemberCenterService.swift` → `updateFavorite` |
| 收藏 request／response | `MemberCenter/Model/MemberCenterAccountModels.swift` |
| UI toggle（勿直接給 Intent） | `Feature/Base/DetailBase/ViewModel/DetailAccountMediaStateController.swift` |
| Session | `MainLogIn/Service/SessionStore.swift`、`MainLogIn/Model/AuthSession.swift` |
| Account id | `MainLogIn/Service/AccountService.swift` |
| 收藏列表 destination | `MemberCenterDestination.favoriteMovies` / `.favoriteTV` |
| 列表導航 | `MemberCenter/Router/MemberCenterRouter.swift` |
| 詳情導航 | `Feature/Base/DetailBase/Router/DetailRouter.swift` |
| 電影搜尋（entity 解析） | `MovieSearch/Service/MovieSearchService.swift` |
| 影集搜尋 | `TVSearch/Service/TVSearchService.swift` |

---

## 14. 分階段實作計畫

### Phase 1 — 可靠操作面（必須）

1. `AppIntentSessionResolver`（session + accountId）
2. Movie／TV `AppEntity` + 基礎 Query（可用搜尋 API）
3. 收藏寫入／移除 Intent
4. 打開收藏列表、打開詳情 Intent
5. `AppShortcutsProvider`
6. Entitlements / Info.plist
7. 單元測試：Intent perform（登入／未登入／API 成功失敗）

**完成定義：** 可在 Shortcuts App 手動執行「打開收藏」「加入收藏」，且行為與 App 內一致。

### Phase 2 — 螢幕感知

1. 詳情頁 `NSUserActivity` + entity 綁定
2. 會員中心列表 List Location
3. 手動驗證：「這是什麼？」、「收藏畫面上第 N 部」類語句（記錄系統不穩定性）

**完成定義：** 至少詳情頁能被系統識別為對應 entity；列表索引行為有文件化基準。

### Phase 3 — 強化與跨 App（可選）

1. Spotlight / `IndexedEntity`
2. `Transferable`
3. Watchlist Intent（若產品要做）
4. Schema 遷移評估（僅在出現匹配 domain 時）

---

## 15. 測試策略

| 層級 | 內容 |
|------|------|
| Unit | `AppIntentSessionResolver`；favorite Intent 對 mock `MemberCenterServicing` |
| Intent isolation | 若 SDK／系統提供 AppIntentsTesting，優先用其在無 Siri 情況下驗證 |
| Shortcuts 手動 | 安裝後於捷徑 App 跑每條 shortcut |
| Siri 手動 | 固定片語；另測螢幕感知（標記 flaky） |
| Regression | App 內詳情頁收藏按鈕行為不變 |

測試必須覆蓋：

- user / guest / loggedOut
- API throw
- `success == false`
- 開畫面在冷啟動／已在前景

---

## 16. 風險與緩解

| 風險 | 影響 | 緩解 |
|------|------|------|
| Siri 自然語／螢幕感知不穩 | 體驗不一致 | Shortcuts 為正式承諾；螢幕感知標為實驗增強 |
| 無匹配 App Schema | 自然句覆蓋較窄 | 自訂 Intent + 清楚片語；持續追蹤 WWDC schema |
| Entity 片名歧義 | 收錯片 | Query 回傳多候選／要求消歧；或要求先開詳情再操作 |
| 列表索引與分頁不一致 | 「第 2 筆」錯位 | 明確 snapshot 規則；優先對「目前宣告給系統的項目」 |
| Intent 誤用 MainActor UI 狀態機 | 競態／難測 | 強制走 Service；code review checklist |
| 未登入使用者失望 | 負評 | Shortcut 說明 + 執行時導向登入 |

---

## 17. 非目標與明確不做

- 不實作舊 SiriKit `Intents.intentdefinition` 為主路徑
- 不把收藏改成僅本地儲存
- 不對 UICollectionView 全量逐 cell annotation
- 不宣稱支援所有自然語言同義句
- 不在無匹配情況下濫用 Photos／Audio／Reminders Schema

---

## 18. 驗收標準（Acceptance Criteria）

### Phase 1

- [ ] 已登入使用者可透過 Shortcuts 打開收藏電影／影集列表
- [ ] 已登入使用者可透過 Intent 將指定 movie／tv 設為收藏或取消
- [ ] 未登入／訪客執行收藏 Intent 得到明確需登入結果
- [ ] 開啟詳情 Intent 可導向正確 `movieID`／`seriesID`
- [ ] App 內原有收藏按鈕行為無回歸
- [ ] 程式符合 Swift 6 concurrency／既有分層；Intent 未直接依賴 Detail VC 狀態機

### Phase 2

- [ ] 電影／影集詳情頁註冊有效的 entity 關聯 user activity
- [ ] 收藏列表提供 List Location 支援，且索引規則有文件／註解
- [ ] 以實機記錄至少一輪螢幕感知測試結果（含已知系統限制）

### Phase 3（若做）

- [ ] Transferable 可匯出可讀的電影／影集表示
- [ ] （可選）Spotlight 可找到近期瀏覽／收藏相關 entity

---

## 19. 給實作代理（Codex / Agent）的執行摘要

請依本 SDD 實作 **Phase 1**，完成後再進 Phase 2。

實作時請：

1. 新增 `Feature/AppIntents/`，不要把 Intent 塞進 ViewController
2. 收藏寫入只呼叫 `MemberCenterServicing.updateFavorite`
3. 用 `SessionStore` + `AccountService` 解析 `accountId`／`sessionId`
4. 開畫面走集中式 `AppIntentNavigator`，複用既有 Router／`MemberCenterDestination`
5. 詳情頁再加 `NSUserActivity`；列表用 List Location，勿逐 cell annotation
6. 不硬套不相關 App Schema
7. 遵守專案 Swift 6 / MVVM / protocol DI / 少用 force unwrap 等既有規範
8. 為 Intent 核心路徑補測試（mock service）

---

## 20. 參考

- 專案 README：`README.md`
- Apple：App Intents、Apple Intelligence / Siri AI、App Schema domains
- WWDC：Get to know App Intents；Build intelligent Siri experiences with App Schemas；Make your app available to Siri
- 現有收藏實作：`MemberCenterService`、`DetailAccountMediaStateController`

---

## 修訂紀錄

| 版本 | 日期 | 說明 |
|------|------|------|
| 0.1 | 2026-07-28 | 初稿：技術選用、架構、Phase 計畫與驗收 |
