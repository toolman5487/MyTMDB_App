# SDD: CineBase 預設訪客模式與首頁冷啟動

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| 文件 ID | `SDD-LAUNCH-SESSION-DEFAULT-GUEST-HOME` |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | Swift 6.0，Strict Concurrency |
| 既有架構 | UIKit + MVVM + Clean Architecture + `AppComposition` |
| 主要模組 | `SceneDelegate`、`MainLogIn`、`MainTabBar`、`SessionStore` |
| 規格狀態 | `Accepted` |
| 實作狀態 | `Partial`（Source implemented、Static Passed；Build／Runtime NotRun） |
| 日期 | 2026-09-25 |

---

## 1. 目的

調整 App 冷啟動流程：當本機沒有可使用的會員或訪客 session 時，自動向 TMDB 建立訪客 session，安全儲存成功後直接顯示 Main Tab 的首頁。

正常首次使用流程改為：

```text
LaunchScreen
    ↓
RootLoadingViewController
    ↓
讀取並驗證既有 Session
    ↓ 無 Session
建立 TMDB Guest Session
    ↓ 儲存成功
MainTabBarController
    ↓
Home
```

登入頁不再是全新安裝或無 session 冷啟動時的預設入口；使用者仍可從設定頁登入或註冊正式會員。

---

## 2. 決策摘要

| 決策 | 結論 |
|------|------|
| 預設身分 | 沒有已儲存 session 時建立 TMDB 訪客 session |
| 預設頁面 | `MainTabKind.home` |
| 既有會員 | 驗證成功後維持會員身分並進首頁 |
| 既有訪客 | 沿用已儲存訪客 session 並進首頁 |
| 建立時機 | 僅在冷啟動解析結果為 `.loggedOut` 時 |
| API | 沿用 `AuthenticationProviding.createGuestSession()`；實作改與 TMDB 官方規格一致使用 `GET /authentication/guest_session/new` |
| 儲存 | 沿用 `SessionStoring`／Keychain；必須先完成儲存才可切換 root |
| 流程責任 | 新增非 UIKit 的 `LaunchSessionResolver`，由 `SceneDelegate` 啟動、`AppComposition` 組裝 |
| 啟動畫面 | 沿用 `RootLoadingViewController`，更新文案以涵蓋 session 檢查與訪客建立 |
| 建立失敗 | 留在 Loading root，提供「重試」與「前往登入」 |
| 安全儲存失敗 | 不進首頁、不使用未持久化 session；顯示安全儲存錯誤並提供重試 |
| 主動登出 | 當下仍顯示既有 root 登入頁；不立即自動建立訪客 |
| 測試範圍 | 不新增測試 Target、Scheme、測試檔案或第三方套件 |

---

## 3. 目標與非目標

### 3.1 目標

- 全新安裝第一次開啟 App 時，自動以訪客模式進入首頁。
- 本機 session 為 `.loggedOut` 時，冷啟動自動建立訪客 session。
- 既有 `.guest` session 不重複建立新的訪客 session。
- 既有 `.user` session 仍先完成目前的會員 session 驗證。
- 會員 session 回傳 401／403 而被清除時，同一次冷啟動改建立訪客 session 並進首頁。
- 訪客 session 必須先寫入既有 Keychain `SessionStore`，才建立 Main Tab root。
- 冷啟動永遠明確指定 `.home`，不依賴 Tab 陣列排序的隱含預設值。
- 保留 App Intent／deep link 的 pending destination：完成 root 建立後再繼續既有路由。
- 保留介面語言、搜尋紀錄及其他非帳號偏好。
- 所有新增非同步型別符合 Swift 6 `Sendable` 與 MainActor 邊界。
- 新增與修改的啟動錯誤文案同步提供英文、繁體中文及日文。

### 3.2 非目標

- 不移除登入、註冊或手動「訪客模式」頁面。
- 不改變設定頁登入入口與 in-app 登入 sheet。
- 不讓訪客取得會員專屬的收藏、Watchlist 或帳號資料能力。
- 不把 `SceneDelegate` 改寫成 Coordinator。
- 不讓 ViewModel 持有 `UIViewController`、`UIWindow` 或執行 root navigation。
- 不把 Keychain session 改存到 `UserDefaults`。
- 不新增匿名的 `.loggedOut` Main Tab 模式；進入 Main Tab 前必須有 `.guest` 或 `.user`。
- 不在每次進入前景或每次切換 Tab 時建立訪客 session。
- 不因這次需求重構所有登入 ViewModel／Controller／Router。
- 不新增測試 Target、測試 Scheme、測試檔案或第三方套件。
- 不修改第 12 節以外的 Swift 原始碼、字串目錄或 Xcode 專案設定。

---

## 4. 現況盤點

### 4.1 變更前冷啟動流程

變更前（HEAD `49ed8e6`）`SceneDelegate.scene(_:willConnectTo:options:)`：

1. 建立 `UIWindow` 與 `AppComposition`。
2. 將 `RootLoadingViewController` 設為 root。
3. 呼叫 `AuthSessionValidator.validatedStoredSession()`。
4. 依 `AuthSession` 切換 root：
   - `.loggedOut`：`LoginViewController`
   - `.guest`／`.user`：`MainTabBarController`

因此變更前全新安裝時，`SessionStore.load()` 回傳 `.loggedOut`，使用者會先看到登入頁，而不是首頁。本規格實作後改由 `LaunchSessionResolver` 處理，見第 5 節。

### 4.2 現行 Session 儲存

`SessionStore` 已具備本需求需要的安全儲存能力：

- `.guest`／`.user` 寫入 Keychain。
- Keychain accessibility 使用 `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`。
- 以 installation ID 避免 App 重裝後沿用舊 Keychain session。
- 寫入後重新讀取並比對資料，確認儲存成功。
- 沒有資料、重裝 installation ID 不一致或儲存 `.loggedOut` 時回傳 `.loggedOut`。

本需求不新增另一套訪客旗標，也不直接操作 Keychain。

### 4.3 現行訪客建立

現有手動訪客流程為：

```text
LoginViewModel.continueAsGuest()
    → AuthenticationProviding.createGuestSession()
    → LoginState.guestSuccess
    → AuthFlowHandler.finishGuestLogin(sessionID:)
    → SessionStore.save(.guest)
    → SceneDelegate.replaceRoot(for:)
```

上述 UI 流程不適合直接放進冷啟動：冷啟動不應建立或驅動 `LoginViewController`，也不應讓 `SceneDelegate` 重做 Repository 細節。

### 4.4 Main Tab 預設頁面

`MainTabBarViewModel` 的 item 順序目前是首頁、搜尋、電影、影集、設定。當 `MainTabBarController.initialTab` 為 `nil` 時，UIKit 目前會停在 index `0`，也就是首頁。

本規格仍要求冷啟動明確傳入 `.home`，避免日後 Tab 順序調整改變啟動頁面。

### 4.5 TMDB Guest Session 限制

TMDB 官方目前將訪客 session 定義為權限受限的 session，建立端點為：

```http
GET /3/authentication/guest_session/new
```

官方文件亦說明，訪客 session 在簽發後 60 分鐘內未使用可能被自動刪除：

- [Create Guest Session](https://developer.themoviedb.org/reference/authentication-create-guest-session)
- [Guest Sessions](https://developer.themoviedb.org/docs/authentication-guest-sessions)

現有 `AuthenticationRepository.createGuestSession()` 使用 `POST`，與官方端點方法不一致；本功能依賴自動建立成功，因此實作時一併更正為既有 `NetworkServicing.get`。

現有 `AuthSessionValidator` 對 `.guest` 直接通過，且 `AuthSession` 未保存訪客到期資訊。為避免本需求擴張成所有訪客 API 的生命週期重構，v1 沿用既有已儲存訪客行為；失效訪客的自動續期另列於第 14 節風險，不納入本次實作。

---

## 5. 目標流程

### 5.1 冷啟動主流程

```text
SceneDelegate
    │
    ├─ 建立 RootLoadingViewController
    │
    └─ LaunchSessionResolver.resolve()
          │
          ├─ AuthSessionValidator.validatedStoredSession()
          │    ├─ .user  ───────────────┐
          │    ├─ .guest ───────────────┤
          │    └─ .loggedOut            │
          │          │                   │
          │          └─ createGuestSession()
          │                 │
          │                 └─ SessionStore.save(.guest)
          │                                     │
          └─────────────────────────────────────┘
                                                ↓
                                 MainTabBarController(.home)
```

### 5.2 狀態決策表

| 啟動時狀態 | 驗證／處理 | 結果 |
|------------|-------------|------|
| Keychain 無 session | 建立並儲存新訪客 session | 訪客模式首頁 |
| installation ID 不一致 | 既有 Store 清除舊 session，再建立訪客 session | 訪客模式首頁 |
| 已儲存 `.guest` | 不重複呼叫建立 API | 原訪客模式首頁 |
| 已儲存 `.user` 且驗證成功 | 沿用會員 session | 會員模式首頁 |
| 已儲存 `.user` 且回傳 401／403 | 清除失效會員資料，再建立訪客 session | 訪客模式首頁 |
| 會員驗證遇暫時性網路錯誤 | 沿用目前 `AuthSessionValidator` 策略保留會員 | 會員模式首頁 |
| Keychain 讀取失敗 | 不建立訪客，避免覆蓋未知 session | 留在 Loading 並顯示安全儲存錯誤 |
| 訪客建立失敗 | 不建立 Main Tab | 留在 Loading，提供重試／前往登入 |
| 訪客建立成功但 Keychain 寫入失敗 | 不使用未持久化訪客 session | 留在 Loading 並顯示安全儲存錯誤 |

### 5.3 非冷啟動的 `.loggedOut`

使用者在 App 內主動登出或清除帳號資料時，既有 `onSessionChanged(.loggedOut)` 仍直接呼叫 `replaceRoot(for:)` 並顯示 root 登入頁。

理由：

- 使用者剛主動選擇登出時，立即重新建立訪客並跳回首頁會遮蔽其操作結果。
- 本需求是「進入 App 時的預設模式」，不是改寫所有 `.loggedOut` 導航語意。
- App 下次冷啟動時，才由 `LaunchSessionResolver` 自動建立訪客 session。

---

## 6. 架構設計

### 6.1 責任分配

| 元件 | 責任 |
|------|------|
| `SceneDelegate` | 啟動 Task、切換 root、顯示啟動錯誤、完成後處理 pending App Intent |
| `AppComposition` | 建立並注入 `LaunchSessionResolver` 的依賴 |
| `LaunchSessionResolver` | 決定沿用既有 session 或建立新訪客 session；不 import UIKit |
| `AuthSessionValidator` | 沿用既有 session 讀取、會員驗證與無效資料清理責任 |
| `AuthenticationProviding` | 建立 TMDB 訪客 session |
| `AuthenticationRepository` | 以正確 HTTP method 呼叫 TMDB 並 decode DTO |
| `SessionStoring` | 將成功建立的 `.guest` session 安全持久化 |
| `RootLoadingViewController` | 顯示啟動中的 loading UI，不執行流程邏輯 |
| `MainTabBarController` | 以指定 `.home` 建立初始 Tab |

### 6.2 新增 `LaunchSessionResolver`

建議路徑：

```text
MainLogIn/Flow/LaunchSessionResolver.swift
```

介面草案：

```swift
nonisolated struct LaunchSessionResolver: Sendable {
    private let sessionValidator: AuthSessionValidator
    private let authentication: AuthenticationProviding
    private let sessionStore: SessionStoring
    private let userProfileStore: UserProfileStoring

    func resolve() async throws -> AuthSession
}
```

`resolve()` 規則：

1. 呼叫 `sessionValidator.validatedStoredSession()`。
2. `.user` 或 `.guest`：直接回傳，不建立新訪客。
3. `.loggedOut`：呼叫 `authentication.createGuestSession()`。
4. 檢查 Task cancellation 與非空 session ID。
5. 建立 `AuthSession.guest(sessionID:)`。
6. 呼叫 `sessionStore.save(_:)`。
7. 清除殘留 `userProfileStore` 快取。
8. 回傳已持久化的 `.guest`。

不得在 Resolver 內：

- 建立或操作 ViewController。
- 直接切換 `UIWindow.rootViewController`。
- 顯示 `UIAlertController`。
- 捕捉所有錯誤後轉成字串。
- 在儲存成功前回傳 guest session。

### 6.3 不擴張 `AuthSessionValidator`

`AuthSessionValidator` 的既有責任是驗證「已儲存的 session」。建立新 session 是另一個 application flow，因此不將 `AuthenticationProviding` 塞入 Validator。

這可維持：

- Validator 可單獨使用於既有 session 驗證。
- Guest 建立只發生在冷啟動 Resolver 的 `.loggedOut` 分支。
- 不會因其他呼叫 Validator 的位置意外產生遠端 guest session。

### 6.4 `AppComposition` Factory

新增：

```swift
func makeLaunchSessionResolver() -> LaunchSessionResolver
```

Factory 注入：

- `makeSessionValidator()`
- `AuthenticationRepository(network: network)`
- 既有 `sessionStore`
- 既有 `userProfileStore`

不得在 `SceneDelegate` 直接 new Repository 或 Store。

### 6.5 `SceneDelegate` 邊界

將啟動用命名由「只驗證 session」調整為「解析啟動 session」：

```text
sessionValidationTask     → launchSessionTask
validateStoredSession()   → resolveLaunchSession()
```

成功時使用獨立初始 root 方法，例如：

```swift
showInitialRoot(for: resolvedSession)
```

此方法對 `.guest`／`.user` 明確呼叫：

```swift
composition.makeMainTabBarController(
    session: resolvedSession,
    initialTab: .home
)
```

既有 `replaceRoot(for:)` 保留給登入完成、登出與介面語言切換，避免破壞「保留目前 Tab」的既有行為。

---

## 7. API 與資料設計

### 7.1 HTTP 方法

`AuthenticationRepository.createGuestSession()` 應由：

```swift
network.post(path: APIConfig.Authentication.guestSessionNew, body: nil)
```

改為：

```swift
network.get(path: APIConfig.Authentication.guestSessionNew)
```

不新增 endpoint、不在 `SceneDelegate` 組 URL、不繞過既有 `NetworkServicing`。

### 7.2 DTO

v1 沿用：

```swift
nonisolated struct GuestSessionDTO: Decodable, Sendable {
    let guestSessionID: String
    let success: Bool
}
```

Repository 必須同時確認：

- `success == true`
- `guestSessionID` 非空

任一條件不成立時回傳明確錯誤，不得儲存空 session ID。

### 7.3 儲存順序

```text
遠端建立成功
    ↓
Task cancellation check
    ↓
SessionStore.save(.guest)
    ↓
清除舊 UserProfile 快取
    ↓
回傳 Session
    ↓
SceneDelegate 建立 Main Tab
```

不採用「先進首頁，背景再儲存」，避免 App 被中止後下次又產生新 session，或 UI 已進訪客模式但 Store 仍為 `.loggedOut`。

---

## 8. UI 與文案

### 8.1 Loading

現行文案「正在檢查登入狀態」不足以涵蓋訪客建立。建議改為較中性的啟動文案：

| Key | English | 繁體中文 | 日本語 |
|-----|---------|----------|--------|
| `root_loading.launch.title` | Preparing CineBase | 正在準備 CineBase | CineBase を準備しています |

保留現有 loading 動畫，不新增進度條、不顯示假的百分比。

### 8.2 訪客建立失敗

建議新增：

| Key | English | 繁體中文 | 日本語 |
|-----|---------|----------|--------|
| `guest_launch.failure.title` | Unable to Start Guest Mode | 無法啟動訪客模式 | ゲストモードを開始できません |
| `guest_launch.failure.message` | Check your connection and try again, or sign in instead. | 請檢查網路後重試，或改為登入會員。 | 通信状況を確認して再試行するか、ログインしてください。 |
| `common.action.sign_in`（既有共用 key） | Sign In | 登入 | ログイン |

Actions：

- 「重試」：重新執行 `resolveLaunchSession()`。
- 「前往登入」：建立 `makeLoginNavigationController(context: .root)`。

### 8.3 安全儲存失敗

沿用現有 `session_validation.failure.*` 安全儲存訊息與「重試」動作。此情況不提供直接進首頁，也不把遠端建立成功但未保存的 ID 當作有效 session。

---

## 9. 錯誤處理

| 錯誤來源 | UI 分類 | 行為 |
|----------|---------|------|
| `AuthSessionError.secureStorageUnavailable` | 安全儲存錯誤 | 留在 Loading，僅允許重試 |
| `AuthSessionError.invalidStoredSession` | 安全儲存資料異常 | 留在 Loading，避免未授權覆寫；記錄安全 log |
| `NetworkError`／`URLError`（建立 guest） | 訪客建立失敗 | 留在 Loading，重試或前往登入 |
| API `success == false` | 訪客建立失敗 | 不儲存、不進 Main Tab |
| 空 `guest_session_id` | 無效 API 回應 | 不儲存、不進 Main Tab |
| Task cancellation | 非使用者錯誤 | 不顯示 alert、不切換 root |

Log 規則：

- 不記錄 `guest_session_id`、`session_id`、完整 URL query 或 API credential。
- 安全儲存錯誤使用 `AppLogger.security`。
- 訪客建立錯誤使用 `AppLogger.authentication`。
- Log 只記錄分類與必要 status code。

---

## 10. Concurrency 與生命週期

- `LaunchSessionResolver` 為 `nonisolated`、`Sendable`，依賴均透過 protocol 注入。
- `SceneDelegate` 的 UI 更新留在 MainActor。
- 同一時間只允許一個 `launchSessionTask`。
- 使用者點擊重試前先取消前一個 Task。
- `sceneDidDisconnect(_:)` 取消 `launchSessionTask`。
- 遠端成功後、Keychain 寫入前執行 cancellation check。
- Task 取消後不得顯示錯誤 alert 或切換 root。
- 重試時若上一輪已成功保存 guest、但尚未切換 root，下一輪應由 Store 讀到該 guest，不再建立第二個 session。

---

## 11. App Intent 與導航

冷啟動含 URL／App Intent 時維持既有順序：

1. 暫存 `pendingIntentDestination`。
2. 完成 session resolution。
3. 建立 Main Tab，初始為首頁。
4. 呼叫 `routePendingIntentDestinationIfNeeded()`。
5. 由既有 `AppIntentNavigator` 決定切換 Tab、push 詳情或要求會員登入。

不得在訪客建立完成前處理 pending destination，避免 Navigator 面對 Loading root。

---

## 12. 預計異動檔案

| 檔案 | 預計異動 |
|------|----------|
| `MainLogIn/Flow/LaunchSessionResolver.swift` | 新增冷啟動 session orchestration |
| `MyTMDB_App/Composition/AppComposition.swift` | 新增 Resolver factory；更新 Loading 文案 key |
| `MyTMDB_App/SceneDelegate.swift` | 啟動流程改呼叫 Resolver；成功後明確進 `.home`；分類錯誤與重試 |
| `MainLogIn/Data/Repository/AuthenticationRepository.swift` | Guest 建立改用 GET；拒絕空 ID |
| `MyTMDB_App/Localizable.xcstrings` | 新增／更新三語 Loading 與錯誤文案 |
| `MyTMDB_App.xcodeproj/project.pbxproj` | 將新增 Swift 檔加入既有 App Target；不建立新 Target |
| `Docs/SDD-CleanArchitecture-Migration.md` | 已更新 cold-launch current-state 描述 |
| `Docs/SDD-SessionStore-Secure-Storage-Authentication.md` | 已補充自動 guest bootstrap 流程 |

---

## 13. 驗收條件

### 13.1 功能驗收

- [ ] 全新安裝且網路正常：Loading 後直接顯示首頁。
- [ ] 全新安裝不會先閃現 Login root。
- [ ] 首次建立的 session 為 `.guest`，且已保存到既有 Keychain Store。
- [ ] 關閉再開啟 App：沿用已儲存 guest，不再次呼叫 guest 建立 API。
- [ ] 已登入會員冷啟動：維持會員身分並顯示首頁。
- [ ] 會員 session 401／403：清除會員資料、建立 guest、顯示首頁。
- [ ] Guest 建立 API 失敗：不進首頁，顯示重試與登入選項。
- [ ] Keychain 讀寫失敗：不進首頁，不使用未保存 session。
- [ ] 重試成功後只切換一次 root。
- [ ] 冷啟動 App Intent：Main root 建立後正確導向目的地。
- [ ] 使用者主動登出：當下仍顯示登入頁，不立即跳回首頁。
- [ ] 訪客可從設定頁開啟登入／註冊流程。

### 13.2 架構驗收

- [x] `SceneDelegate` 不直接建立 `AuthenticationRepository`。
- [x] `LaunchSessionResolver` 不 import UIKit。
- [x] `RootLoadingViewController` 不執行 API 或 Storage 邏輯。
- [x] 所有依賴由 `AppComposition` 注入。
- [x] `AuthSessionValidator` 不新增建立 session 的責任。
- [x] Main Tab 初始值明確傳入 `.home`。
- [x] 沒有新增 Test Target、Test Scheme 或第三方套件。
- [x] 沒有 log session ID 或敏感 query。

### 13.3 三語驗收

- [x] Loading 文案有英文、繁體中文、日文。
- [x] Guest 建立失敗 alert 有英文、繁體中文、日文。
- [x] Retry／Sign In action 沿用或新增完整三語字串。

---

## 14. 已知風險與後續議題

### 14.1 已儲存 Guest Session 失效

TMDB 官方文件描述 guest session 的清理條件，但目前資料模型沒有保存有效期限，Validator 也不遠端驗證 guest。v1 不在每次冷啟動重建 guest，避免使用者的 guest rating 狀態被無條件切斷，也避免每次啟動多打一個 API。

後續若實際觀察到 401／403，另案設計：

- 保存 API 回傳的 expiry metadata 並提供 Codable migration；或
- 在 guest-only request 收到 401／403 時集中更新 guest 並重試一次。

不得在各個 Repository 分散複製 renewal 邏輯。

### 14.2 離線首次啟動

全新安裝沒有 guest session 時，建立 guest 必須連線 TMDB。v1 不偽造本機 guest ID，也不讓 `.loggedOut` 進入 Main Tab，因此離線首次啟動會停留在 Loading 錯誤狀態，使用者可重試或前往登入。

若未來產品要求完全離線瀏覽，需要新增明確的 anonymous/read-only session model，不能以空字串假裝 guest；此需求不屬於本 SDD。

---

## 15. 實作階段

### Phase 1：啟動 Session Resolver

- 新增 `LaunchSessionResolver`。
- 新增 `AppComposition.makeLaunchSessionResolver()`。
- 保持 `AuthSessionValidator` 單一責任。

### Phase 2：Scene Root Cutover

- `SceneDelegate` 改用 Resolver。
- 冷啟動成功明確指定 `.home`。
- 保留非冷啟動 `replaceRoot(for:)` 行為。
- 保留 pending App Intent 路由順序。

### Phase 3：API 與錯誤 UI

- Guest 建立改用官方 GET 方法。
- 驗證非空 guest ID。
- 加入訪客啟動失敗分流與三語文案。
- 更新 Loading 文案。

### Phase 4：文件與驗證

- 更新相關 current-state SDD。
- 執行第 16 節靜態檢查。
- 由開發者執行 Simulator／實機情境驗收。

---

## 16. 驗證計畫

依專案規範，本功能不新增測試 Target。實作完成後執行：

### 16.1 靜態檢查

```bash
git diff --check
plutil -lint MyTMDB_App.xcodeproj/project.pbxproj
rg -n "createGuestSession|makeLaunchSessionResolver|resolveLaunchSession|initialTab: \.home" .
rg -n "guest_session_id|session_id" MyTMDB_App MainLogIn Feature
```

另以專案既有工具驗證：

- `Localizable.xcstrings` JSON／catalog 格式。
- 英文、繁體中文、日文 key 完整性。
- 新檔 App Target membership。
- 所有 `createGuestSession()` 呼叫端仍可編譯。
- Swift 6 cancellation 與 actor isolation 警告。

### 16.2 Build 邊界

本 SDD 建立階段不執行 Build。後續實作完成後，只有在使用者明確要求，或確認不需長時間下載套件／啟動模擬器時才執行 `xcodebuild`。

若未執行，交付時必須明確標記：

```text
Source: Done / NotDone
Static: Passed / Failed / NotRun
Build: Passed / Failed / NotRun
Runtime: Passed / Failed / NotRun
```

### 16.3 手動驗收資料準備

手動驗收需至少覆蓋：

1. 刪除 App 後全新安裝。
2. 已有 guest session 再次啟動。
3. 已有有效 user session 再次啟動。
4. 模擬 user session 401／403。
5. 首次啟動時關閉網路。
6. Guest 建立成功後模擬 Keychain 寫入失敗。
7. 冷啟動同時帶入 App Intent URL。
8. 訪客從設定頁登入會員。
9. 會員主動登出。

### 16.4 本次驗證結果（2026-09-25）

```text
Source: Done
Static: Passed
Build: NotRun
Runtime: NotRun
```

已通過：

- `git diff --check`
- `plutil -lint MyTMDB_App.xcodeproj/project.pbxproj`
- `jq empty MyTMDB_App/Localizable.xcstrings`
- `xcrun xcstringstool compile`
- 修改 Swift 檔案的 `xcrun swiftc -parse`
- 新增 `LaunchSessionResolver.swift` 的 App Target membership 檢查

未執行：

- Xcode Build
- Simulator／實機冷啟動情境
- Keychain failure injection
- 三語畫面人工 Copy Review

---

## 17. 完成定義

只有同時符合以下條件，才能將本文件狀態改為 `Implemented`：

- 冷啟動無 session 時自動建立並保存 guest。
- 成功後直接進 Main Tab 首頁。
- 既有 guest／user 不被不必要地取代。
- API method 與 TMDB 官方規格一致。
- 失敗時不進入不一致的 Main Tab 狀態。
- 主動登出語意未被改寫。
- 三語文案與 Target membership 完成。
- 靜態檢查通過。
- Build／Runtime 的實際執行狀態已如實記錄。
