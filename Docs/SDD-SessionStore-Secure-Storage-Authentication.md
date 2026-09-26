# SDD: CineBase 安全本機儲存與驗證生命週期

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| 文件 ID | `SDD-SESSION-STORE-SECURE-STORAGE-AUTHENTICATION` |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | Swift 6.0，`SWIFT_STRICT_CONCURRENCY = complete` |
| 既有架構 | UIKit + MVVM + Clean Architecture + Router + `AppComposition` |
| 目標 | 保護 TMDB Session、補齊遠端撤銷、降低憑證與個資落盤風險、補齊 Privacy Manifest |
| 規格狀態 | `Accepted` |
| 實作狀態 | `Partial`（P0 Phase 1–3 與預設訪客 bootstrap Done；Phase 5 Partial；Phase 4、6 Deferred） |
| 驗證狀態 | Build `Passed`（2026-09-26，iOS Simulator Debug）；Runtime `Partial`（訪客冷啟動、Keychain 無法存取時 fail closed 已確認，16.3 其餘情境 NotRun）；Archive `NotRun` |
| 最後更新 | 2026-09-26 |

---

## 1. 目的

本文件定義 CineBase 本機持久化與 TMDB 驗證流程的安全修正方案。核心問題不是「是否有本機儲存」，而是不同敏感度的資料目前都使用 `UserDefaults`，且登出只刪除本機 Session，未撤銷 TMDB 遠端 Session。

本文件要解決下列問題：

- TMDB Session ID 被當作一般偏好資料儲存在 `UserDefaults`。
- 產品尚未上線，因此不保留開發期 `UserDefaults` Session 相容層；user／guest Session 統一由 Keychain 儲存。
- 登出未呼叫 TMDB `DELETE /authentication/session`，無法保證遠端 Session 失效。
- App 直接接收 TMDB 帳號密碼，增加憑證接觸面。
- TMDB application credential 以 literal value 放在已追蹤的 `Info.plist`，並以 URL query 傳送。
- 會員 Profile、頭像二進位資料與搜尋紀錄存於 `UserDefaults`，不符合資料最小化與儲存角色。
- 專案直接使用 `UserDefaults`，但目前沒有 App-owned `PrivacyInfo.xcprivacy`。

本文件是安全與隱私邊界的增量規格，不取代 `SDD-CleanArchitecture-Migration.md` 與 `SDD-Architecture-Unified-Interface-Naming.md`。

---

## 2. 安全結論與優先級

| 優先級 | 問題 | 判定 | 修正方向 |
|--------|------|------|----------|
| P0 | Session ID 儲存在 `UserDefaults` | 高風險；TMDB 要求視同密碼 | 上線前直接切換至 Keychain，不保留舊 Session migration |
| P0 | 登出只清本機、不撤銷遠端 Session | 中高風險；外洩 Session 仍可能有效 | 遠端撤銷成功後再清本機；失敗可重試 |
| P1 | App 直接接收帳號密碼 | 中風險；密碼雖未持久化，但 App 仍接觸憑證 | `ASWebAuthenticationSession` + TMDB 網頁授權 |
| P1 | API credential 位於 tracked `Info.plist` 且放入 query | 中風險；可被 Git 或 App binary 取得 | build setting 注入 + Bearer header；必要時 Backend proxy |
| P2 | Profile、頭像與搜尋紀錄位於 `UserDefaults` | 隱私與資料治理風險 | Protected file / cache；移除重複頭像 Data |
| P0 | 缺少 `PrivacyInfo.xcprivacy` | App Store 合規風險 | 宣告 UserDefaults Required Reason API |

P0 必須先完成；P1、P2 不得阻塞 P0 上線，但不得因此被標記為已完成。

### 2.1 實作狀態（2026-09-26 更新）

| Phase | 狀態 | 證據／限制 |
|------|------|------------|
| Phase 1 — Keychain clean cutover | Source Implemented / Static Verified | user／guest Session 僅存 Keychain；versioned envelope、installation ID、throwing call chain已套用；未保留開發期 UserDefaults Session migration；Swift parser 通過 |
| Phase 2 — Remote logout | Source Implemented / Static Verified | TMDB delete Session、remote-first、retry、local-only 二次確認與 loading 已套用；Swift parser 通過 |
| Phase 3 — Privacy Manifest | Source Implemented / Static Verified | `MyTMDB_App/PrivacyInfo.xcprivacy` 已新增且 `plutil -lint` 通過；位於 file-system synchronized target root；2026-09-26 確認 Simulator Debug app bundle 內含此檔；archive 尚未驗證 |
| Phase 4 — Web authentication | Deferred / NotImplemented | 涉及產品登入流程與 callback 設定，未在 P0 自動切換 |
| Phase 5 — Credential hygiene | Partial / Deferred | authenticated request no-store 已套用；literal credential、Bearer header、build setting 與 credential rotation 未執行 |
| Phase 6 — Protected files | Deferred / NotImplemented | Profile、頭像與 Search History 仍維持原儲存方式 |

2026-09-26 更新：iOS Simulator Debug build 通過。Runtime 只確認兩件事：冷啟動以訪客身分直接進入首頁；以未簽章建置啟動（App 無 Keychain 存取權）時 fail closed，停在啟動畫面並顯示「無法讀取登入狀態」與「重試」。16.3 其餘情境、實機驗證與 Archive 均 NotRun，本狀態不代表 Archive Validated 或 App Store Ready。

---

## 3. 目標與非目標

### 3.1 目標

- Session ID 只存在記憶體、Keychain 與必要的 HTTPS request 中。
- Keychain item 不同步至 iCloud、不遷移至其他裝置，且支援 App Intent 在裝置首次解鎖後讀取。
- user／guest Session 不得寫入或回退至 `UserDefaults`；產品上線前直接以 Keychain 作為唯一憑證來源。
- Keychain 讀寫失敗必須以明確 Error 表達，不得誤判為正常登出。
- 登出具備遠端撤銷與本機清除的明確順序，不顯示「已安全登出」的假成功。
- 使用者可在遠端撤銷失敗時重試，或經第二次明確確認後只清除此裝置資料。
- 密碼、request token、Session ID、API credential 與含敏感 query 的 URL 永不寫入 log。
- 保留 `AppComposition` 作為唯一 composition root，所有 concrete storage 經 protocol 注入。
- 保留 Swift 6 `Sendable`、Strict Concurrency 與 `@MainActor` UI 邊界。
- 保留既有登入狀態、搜尋紀錄與會員資料的可解碼相容性。

### 3.2 非目標

- 不新增 Core Data、SwiftData、Realm 或其他本地資料庫。
- 不新增第三方 Keychain、DI、Networking 或加密套件。
- 不自行設計加密演算法；敏感小資料使用 Apple Keychain，檔案依賴 iOS Data Protection。
- 不新增 Coordinator、Service Locator、泛型 DI container 或 `AppComposition.shared`。
- 不改寫 UIKit 為 SwiftUI。
- 不變更收藏、評分、Watchlist 等 TMDB 業務行為。
- 不加入 certificate pinning；此需求若成立需另案處理憑證輪替與失效策略。
- 不建立 Unit Test target、測試或 CI 流程。
- 不修改第三方套件、SwiftPM 或 `Package.resolved`。
- 不在本文件執行 API key 旋轉、Git history rewrite 或後端建置。
- 不新增與本安全需求無關的 Accessibility、UI 樣式或動畫調整。

---

## 4. 實作前基線盤點

### 4.1 本機持久化

| 資料 | 現況 | Key / 位置 | 清除行為 |
|------|------|------------|----------|
| 使用者／訪客 Session | `AuthSession` JSON 存於 `UserDefaults` | `AuthSession` | 登出與無效 Session 時清除 |
| 舊版 Session | String / Bool 存於 `UserDefaults` | `TMDBSessionID`、`TMDBGuestSessionID`、`TMDBIsGuest` | 成功遷移後清除 |
| 會員 Profile | `StoredUserProfile` JSON 存於 `UserDefaults` | `StoredUserProfile` | 登出或手動清快取時清除 |
| 會員頭像 | `avatarImageData` 內嵌於 Profile JSON | 同上 | 隨 Profile 清除 |
| 搜尋紀錄 | `[SearchHistoryEntry]` JSON 存於 `UserDefaults` | `SearchHistory.v1` | 手動清除；一般登出保留 |
| 遠端圖片 | SDWebImage memory + disk cache | SDWebImage 自管 | 手動清圖片快取或清除所有本機資料 |

所有自有 `UserDefaults` 存取經 `AppPreferencesStorage` 與 `Mutex` 序列化。這處理的是並行一致性，不等同敏感資料加密。

### 4.2 驗證與網路

- `AuthSession.user(sessionID:)` 與 `.guest(sessionID:)` 直接包含 Session ID。
- `NetworkService` 使用 `https://api.themoviedb.org/3`，未發現 ATS 任意放行。
- application API key 由 tracked `Info.plist` 讀取，並加入每個 request 的 `api_key` query item。
- 帳號密碼只存在登入 UI / ViewModel 記憶體與 HTTPS request body，未發現持久化或直接 log。
- Session ID 以 `session_id` / `guest_session_id` query item 傳給 TMDB。
- `URLSessionConfiguration.default` 可能使用共享 cache；目前未針對含 Session query 的 request 禁止磁碟快取。
- `LogoutUseCase` 目前只執行 `clearSession()` 與 `clearCachedProfile()`。
- `APIConfig.Authentication.session` 已存在，可供遠端刪除 Session 使用。

### 4.3 正面基線

- TMDB API 使用 HTTPS。
- 未發現 Session ID、密碼、request token 或 API key 被直接寫入 `Logger`。
- 密碼輸入框使用 secure text entry。
- `AppComposition` 已集中注入 `SessionStoring`、`UserProfileStoring` 與 `SearchHistoryProviding`。
- 已有「清除圖片快取」、「清除搜尋紀錄」及「清除所有本機資料」入口。

---

## 5. 威脅模型

### 5.1 需保護的資產

| 資產 | 敏感度 | 外洩影響 |
|------|--------|----------|
| 使用者 Session ID | 高 | 可代表使用者讀寫評分、收藏與 Watchlist，直到 Session 失效 |
| 使用者密碼 | 極高 | TMDB 帳號接管風險 |
| Request token | 高但短期 | 可干擾／接管進行中的授權流程 |
| Application API credential | 中 | 額度濫用、credential 被停用、來源追蹤 |
| Profile / 頭像 | 中 | 個人資料與隱私曝露 |
| 搜尋紀錄 | 中 | 使用偏好與可能的敏感關鍵字曝露 |

### 5.2 納入考量的攻擊面

- App container、未受保護的偏好檔或裝置備份被讀取。
- 遺失、遭除錯或越獄的裝置。
- Repository、Build Artifact 或 App binary 被取得。
- URL、network diagnostic、proxy、cache 或 crash report 意外保存 query credential。
- 遠端登出失敗但 UI 顯示成功。
- Keychain 寫入失敗或 payload 損壞時，App 不得建立或恢復登入狀態。

### 5.3 接受的限制

- 已完全遭控制的 runtime 仍可讀取使用中的 Session；Keychain 無法防止進程內攻擊。
- 任何放入 client binary 的 application credential 都可被擷取。沒有 Backend proxy 時，只能降低誤提交與 URL 暴露，不能宣稱為真正秘密。
- 本案不保護 TMDB 伺服器端或第三方 SDK 自身的安全缺陷。

---

## 6. 目標架構

```text
AppComposition
  |
  +-- SessionStore : SessionStoring / AuthSessionProviding
  |     |
  |     +-- SessionCredentialStoring
  |     |     +-- KeychainSessionCredentialStore (Security.framework)
  |     |
  |     +-- AppPreferencesStorage
  |           +-- non-secret installation ID only
  |
  +-- AuthenticationRepository
  |     +-- create / validate / delete TMDB Session
  |
  +-- DefaultLogoutUseCase
  |     +-- remote revoke -> local Keychain clear -> Profile clear
  |
  +-- UserProfileStore
  |     +-- protected cache file
  |
  +-- SearchHistoryStore
        +-- protected local JSON file
```

### 6.1 依賴規則

- Domain 宣告 `AuthSessionProviding`、登出結果與可顯示的抽象錯誤，不 import `Security`。
- Data 實作 Keychain、protected file、DTO 與 TMDB request。
- ViewModel 只呼叫 UseCase，不直接呼叫 `SecItem...`、`UserDefaults`、`FileManager` 或 `SDImageCache.shared`。
- Controller / Router 只負責顯示確認、錯誤與導覽。
- `AppComposition` 建立並注入唯一的 concrete storage graph。

### 6.2 不建立的抽象

- 不建立全專案泛型 `SecureStorage<T>`。
- 不建立通用 Repository base class。
- 不以 Property Wrapper 隱藏 Keychain I/O 與 Error。
- `SessionCredentialStoring` 只服務 Session，不擴張成任意字串／任意 Codable 儲存容器。

---

## 7. P0：Session Keychain 統一儲存

### 7.1 Keychain 規格

| 項目 | 規格 |
|------|------|
| Keychain class | `kSecClassGenericPassword` |
| Service | `co.willyhsu.CineBase.auth-session` |
| Account | `tmdb-session` |
| Access group | 不指定；限本 App |
| Synchronizable | `false`；不經 iCloud Keychain 同步 |
| Accessibility | `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` |
| Payload | versioned JSON envelope，不直接儲存裸字串 |
| 寫入方式 | item 存在時 update，不存在時 add；每次檢查 `OSStatus` |
| 登出 | `SecItemDelete`；`errSecItemNotFound` 視為成功 |

選用 `AfterFirstUnlockThisDeviceOnly` 是為了兼顧 App Intent／背景入口，並避免憑證透過備份遷移到其他裝置。若未來確認所有入口只在解鎖狀態工作，可另案收緊為 `WhenUnlockedThisDeviceOnly`。

### 7.2 Payload

```swift
nonisolated struct StoredAuthSessionEnvelope: Codable, Sendable, Equatable {
    let version: Int
    let installationID: UUID
    let session: AuthSession
}
```

- 初版 `version = 1`。
- user 與 guest 共用同一個 versioned envelope，不建立兩套 storage。
- `.loggedOut` 不寫入 Keychain；無 item 即代表沒有登入狀態。
- `installationID` 為 App-local 隨機 UUID，只存在 `UserDefaults`，不得送出裝置、不得加入 analytics。
- Keychain envelope 的 installation ID 與目前安裝不一致時，視為卸載後殘留資料並刪除，避免重新安裝後自動恢復舊 Session。

### 7.3 Protocol 與錯誤

`SessionStoring` 與 `AuthSessionProviding` 改成可回報錯誤：

```swift
nonisolated protocol AuthSessionProviding: Sendable {
    func currentSession() throws -> AuthSession
    func clearSession() throws
}

nonisolated protocol SessionStoring: AuthSessionProviding {
    func load() throws -> AuthSession
    func save(_ session: AuthSession) throws
    func clear() throws
}
```

Domain-facing error 不得暴露 Session 內容：

```swift
nonisolated enum AuthSessionError: Error, Sendable, Equatable {
    case secureStorageUnavailable
    case invalidStoredSession
}
```

Data 層可以保留 `OSStatus` 供診斷，但 log 僅可記錄 operation 與 status code，不得記錄 query、payload、Session ID、service/account 以外的敏感值。

### 7.4 讀寫演算法

啟動時依下列順序執行：

1. 取得或建立 App-local `installationID`。
2. 讀取 Keychain。
3. Keychain item 存在且 envelope 可解碼、installation ID 相符：直接回傳 user／guest Session。
4. Keychain item 存在但內容損壞：fail closed，回報 `.invalidStoredSession`。
5. Keychain item 不存在：Store 回傳 `.loggedOut`；不得讀取 `AuthSession` 或三個開發期 legacy key。
6. 冷啟動的 `LaunchSessionResolver` 收到 `.loggedOut` 時，以 TMDB Guest Session API 建立 `.guest`。
7. 寫入 `.guest` 或 `.user`：寫入 Keychain 後 read-back 驗證；失敗不得切換至 Main root。
8. 寫入 `.loggedOut` 或登出：刪除 Keychain item。

產品尚未上線，因此不提供 `UserDefaults` Session migration。開發環境中既有的 `AuthSession`、`TMDBSessionID`、`TMDBGuestSessionID`、`TMDBIsGuest` 不再讀取；冷啟動會建立新的 guest，會員需從 App 內登入入口重新登入。

### 7.5 呼叫端行為

- `AuthSessionValidator`：正常無 item才是 `.loggedOut`；儲存不可用不得偽裝為正常登出。
- `LaunchSessionResolver`：只在冷啟動 `.loggedOut` 分支建立 guest；Keychain 寫入與 read-back 成功後才回傳可進入 Main root 的 session。
- 啟動讀取失敗：停留在 root loading/error 狀態並提供重試；不得進入受保護頁面。
- 登入儲存失敗：不切換到 Main root，顯示「無法安全儲存登入狀態，請重試」。
- Detail / MemberCenter：讀取失敗時採 fail closed，帳號操作不可用，顯示既有可重試錯誤。
- App Intent：Keychain 不可用時回傳明確失敗，不導覽至需要使用者 Session 的目的地。

---

## 8. P0：遠端 Session 撤銷與登出語意

### 8.1 Repository API

`AuthenticationProviding` 新增：

```swift
func deleteUserSession(sessionID: String) async throws
```

Data 實作：

- Endpoint：`DELETE /authentication/session`。
- Request body：`{"session_id": "..."}`，使用專用 Encodable DTO。
- 不將 Session ID 放入 log。
- HTTP 401 / 404 視為遠端已無有效 Session，可繼續清本機。
- cancellation 必須保留為 `CancellationError`，不得映射成一般登出失敗。

### 8.2 LogoutUseCase

`LogoutUseCase` 改為 `async throws`，順序固定：

```text
讀取目前 Session
  |
  +-- loggedOut / guest -> 清本機 Session -> 清 Profile
  |
  +-- user -> DELETE remote Session
               |
               +-- success / already invalid
               |      -> 清 Keychain -> 清 Profile -> complete
               |
               +-- network / server failure
                      -> 保留 Keychain 與 Profile -> retryable failure
```

- 一般「登出」不得在遠端撤銷失敗時直接顯示成功。
- UI 顯示「無法連線至 TMDB，尚未完成登出」，提供重試與取消。
- 若使用者選擇「只在此裝置登出」，必須經第二次明確確認，再清 Keychain 與 Profile；結果標記為 local-only，不宣稱遠端 Session 已撤銷。
- Profile 只能在本機 Session 清除成功後清除，避免半完成狀態。

### 8.3 清除所有本機資料

`ClearLocalDataUseCase` 不得把遠端撤銷錯誤吞掉：

1. 先走標準 LogoutUseCase。
2. 成功後清搜尋紀錄與 SDWebImage memory/disk cache。
3. 遠端撤銷失敗時，UI 提供「重試」與「只清除此裝置」；後者需再次確認。
4. local-only 路徑仍需嘗試清 Keychain、Profile、搜尋紀錄與圖片快取，並回報每一類別的清除結果。

---

## 9. P1：TMDB 網頁授權

### 9.1 目標流程

```text
取得 request token
  -> 以 ASWebAuthenticationSession 開啟 TMDB 授權頁
  -> 使用 cinebase callback 回 App
  -> 驗證 callback 與原 request token
  -> 建立 TMDB user Session
  -> 寫入 Keychain
  -> 載入 Profile
  -> 切換 Main root
```

### 9.2 邊界

- `ASWebAuthenticationSession` 屬 App/UI 邊界，由 `AppComposition` 注入登入流程。
- Domain UseCase 只編排「取得 token、等待授權、建立 Session」，不 import `AuthenticationServices` 或 UIKit。
- request token 只保留於記憶體，不寫入 `UserDefaults`、Keychain 或 log。
- callback 必須驗證 scheme、host/path、request token 與授權結果。
- 使用者取消映射為 cancellation，不顯示帳密錯誤。
- 冷啟動預設 Guest 與登入頁手動 Guest 均沿用同一 Authentication Repository；Guest Session 只存 Keychain。

### 9.3 舊登入移除

網頁授權 runtime 驗證通過後：

- 移除 `username`、`password` ViewModel 狀態。
- 移除 `TokenValidationRequestDTO` 與 `validate_with_login` 呼叫。
- 移除 App 內的密碼輸入 UI。
- 不在同一 Phase 保留兩套 user login 作為長期 fallback。

若產品決定暫時保留帳密登入，必須明確標記 Phase 9 為 Deferred；不得因已使用 HTTPS 就宣稱憑證接觸風險已消除。

---

## 10. P1：Application Credential 與 Request URL

### 10.1 Git 與 Build 設定

- tracked `Info.plist` 不得含 literal API key / read access token。
- `Info.plist` 僅保留 build setting placeholder，例如 `$(TMDB_READ_ACCESS_TOKEN)`。
- 提供不含秘密的 `Secrets.xcconfig.example`。
- 實際 `Secrets.xcconfig` 加入 `.gitignore`，不得由 SDD、log 或 commit 帶出內容。
- CI / Archive 以受保護的 build setting 注入。
- 既有 credential 在新設定驗證後，由擁有者於 TMDB 後台旋轉。
- Git history rewrite 為破壞性操作，不在一般實作流程自動執行；若 Repository 曾公開，另行取得明確授權後處理。

本 Phase 會涉及 build configuration / `project.pbxproj`，實作前必須取得明確授權；不得因撰寫本 SDD 而修改專案設定。

### 10.2 傳輸方式

- 優先使用 TMDB Read Access Token 與 `Authorization: Bearer ...` header。
- 移除 `NetworkService.makeURL` 自動加入 `api_key` query 的行為。
- 不記錄 Authorization header 或完整 request URL。
- Bearer header 只能降低 URL、cache 與診斷工具暴露，不能把 client credential 變成真正秘密。
- 若產品要求 application credential 不可由 client 取得，唯一合格方案是 Backend proxy；不在本案實作。

### 10.3 Authenticated request cache policy

當 request 含 `session_id` 或 `guest_session_id`：

- 使用 `.reloadIgnoringLocalCacheData`。
- Request 加入 `Cache-Control: no-store`。
- 不把完整 URL 寫入 cache key、logger、analytics 或 error message。
- 一般公開電影／影集 GET request 可維持既有 cache 行為。

---

## 11. P2：Profile、頭像與搜尋紀錄

### 11.1 User Profile

- `UserProfileStore` 改存 protected cache file，不再寫 `UserDefaults`。
- 建議位置：Library/Caches/CineBase/Profile/profile-v1.json。
- 檔案使用 iOS Data Protection；資料可由 TMDB 重建，因此不納入備份。
- `avatarImageData` 不再內嵌於 Profile JSON，交由 SDWebImage disk cache 或專用 protected cache file 管理。
- `StoredUserProfile` 保留舊 `avatarImageData` optional decode 一個相容週期，讀取後不再寫回該欄位。
- 登出與清 Profile cache 都必須刪除檔案與對應頭像 cache。

### 11.2 Search History

- `SearchHistoryStore` 改存 protected JSON file，不引入資料庫。
- 建議位置：Library/Application Support/CineBase/Search/search-history-v1.json。
- 標記不納入備份；搜尋紀錄只屬此裝置。
- 保留既有每個 scope 最多 15 筆、去重、排序與移動語意。
- 一般登出是否保留搜尋紀錄維持現況；「清除所有本機資料」必須刪除。

### 11.3 File migration 共通規則

1. 先讀新檔案。
2. 新檔案不存在時才讀 legacy `UserDefaults`。
3. atomic write 成功並 read-back 驗證後才刪除 legacy key。
4. Profile cache 損壞可刪除並重新下載；搜尋紀錄損壞可隔離後回到空陣列。
5. Error log 只記錄資料類型與錯誤分類，不記錄 profile 內容或搜尋關鍵字。

---

## 12. Privacy Manifest

新增 App-owned `PrivacyInfo.xcprivacy` 並確認加入 app target Resources。

只要 runtime 仍會以 `UserDefaults` 儲存 installation ID、Profile、Search History 或其他 app-local metadata，需至少宣告：

```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>CA92.1</string>
        </array>
    </dict>
</array>
```

- `CA92.1` 僅涵蓋本 App 自己可存取的 app-local defaults。
- `installationID` 不得送出裝置或用於 tracking / fingerprinting。
- `NSPrivacyCollectedDataTypes` 不在未完成產品資料流盤點前猜測填寫；需另行核對 App Store Connect privacy labels、TMDB 傳輸內容與所有第三方 SDK manifest。
- 新增 Resource 與修改 `project.pbxproj` 必須取得明確授權並驗證 target membership。

---

## 13. Log 與錯誤處理規則

### 13.1 絕對禁止寫入 log

- TMDB username / password。
- request token。
- user / guest Session ID。
- application API key / read access token。
- Authorization header。
- 含 `api_key`、`session_id`、`guest_session_id`、token 或 callback query 的完整 URL。
- Profile payload、頭像 Data、搜尋關鍵字。

### 13.2 允許的診斷資訊

- operation 名稱，例如 `keychain.read`、`session.revoke`。
- `OSStatus`、HTTP status code、錯誤分類。
- 是否發生 migration，但不包含被遷移資料。
- 使用者可理解且不含底層秘密的錯誤文案。

### 13.3 使用者文案

| 情境 | 文案方向 |
|------|----------|
| Keychain 寫入失敗 | 無法安全儲存登入狀態，請重試 |
| Keychain 暫時不可用 | 無法讀取登入狀態，請解鎖裝置後重試 |
| 遠端撤銷失敗 | 尚未完成登出，請檢查網路後重試 |
| local-only 確認 | 只會清除此裝置資料，TMDB Session 可能仍有效 |
| 網頁授權取消 | 已取消登入，不視為帳號或密碼錯誤 |

---

## 14. 分階段實作計畫

### Phase 0 — 文件與基線

- 凍結 `AuthSession` 現行 Codable payload，確認產品尚無正式版 migration 義務。
- 記錄所有 session/profile/search storage call site。
- 確認當前工作區 staged / unstaged 狀態。
- 不修改 SwiftPM、套件或現有 UI。

完成條件：本文件核准，所有實作 Phase 尚為 NotStarted。

### Phase 1 — Keychain clean cutover（P0）

- 建立窄化 `SessionCredentialStoring` 與 Security.framework 實作。
- `SessionStore` 改為 throwing API 與 Keychain source of truth。
- 實作 versioned envelope 與 installation ID；不建立 UserDefaults Session migration。
- 更新 `AuthSessionValidator`、`AuthFlowHandler`、Account Session、Detail、Setting、App Intent 呼叫端。
- Keychain failure 採 fail closed 並提供重試。

完成條件：user／guest Session 只讀寫 Keychain；任何 UserDefaults Session key 都不再被讀取或寫入。

### Phase 2 — Remote logout（P0）

- `AuthenticationProviding` 新增 delete Session。
- `LogoutUseCase` 改為 async remote-first flow。
- Setting ViewModel / Controller 處理 loading、retry、local-only confirmation。
- `ClearLocalDataUseCase` 回報完整清除結果。

完成條件：標準登出成功後舊 Session 無法再呼叫受保護 TMDB API。

### Phase 3 — Privacy Manifest（P0）

- 新增 `PrivacyInfo.xcprivacy`。
- 宣告 app-local UserDefaults reason `CA92.1`。
- 確認 Resource membership 與 archive privacy report。

完成條件：最終 app bundle 含正確 manifest，且宣告與實際 API 使用一致。

### Phase 4 — Web authentication（P1）

- 導入 `ASWebAuthenticationSession` 授權流程。
- 驗證 callback 與 request token。
- runtime 驗證通過後移除帳密 UI 與 password DTO。

完成條件：user login 全程不由 App 收集 TMDB 密碼。

### Phase 5 — Application credential hygiene（P1）

- 取得修改 build configuration 的明確授權。
- 移除 tracked literal，改用受保護 build setting。
- 改用 Bearer header 並移除 `api_key` query。
- credential 由擁有者於 TMDB 後台旋轉。
- 對 authenticated request 禁止 cache。

完成條件：Git 與 request URL 不含 application credential；Release build 不含 placeholder。

### Phase 6 — Profile / Search protected files（P2）

- Profile 與 SearchHistory 分別遷移至 protected file。
- 移除 Profile JSON 的 avatar Data 寫入。
- 完成 atomic migration 與清除流程。

完成條件：`UserDefaults` 只剩 installation ID 與非憑證 app-local metadata。

---

## 15. 預計檔案影響

| 檔案／區域 | 變更 |
|------------|------|
| `Feature/Domain/Repository/AuthSessionProviding.swift` | throwing session API |
| `Feature/Domain/Error/` | 新增不含秘密的 Session domain error |
| `Feature/Data/Storage/SessionStore.swift` | Keychain-only Session source of truth、installation binding |
| `Feature/Data/Storage/` | 新增窄化 Keychain concrete implementation |
| `MainLogIn/Flow/AuthFlowHandler.swift` | 處理 load/save failure；網頁授權完成後存 Keychain |
| `MainLogIn/Domain/Repository/AuthenticationProviding.swift` | delete Session；後續 web auth boundary |
| `MainLogIn/Data/Repository/AuthenticationRepository.swift` | TMDB delete / web auth request |
| `MainLogIn/Data/DTO/AuthenticationDTO.swift` | delete DTO；後續移除 password DTO |
| `Main/MainMemberSetting/Domain/UseCase/LogoutUseCase.swift` | async remote-first logout |
| `Main/MainMemberSetting/Domain/UseCase/ClearLocalDataUseCase.swift` | 完整結果與 local-only flow |
| `Main/MainMemberSetting/ViewModel` / `Controller` / `Router` | loading、retry、確認與結果 UI |
| `Feature/Data/Network/NetworkService.swift` | Bearer header、敏感 request no-store |
| `Feature/Data/Network/APIConfig.swift` | 移除直接 API key query 依賴 |
| `Feature/Data/Storage/UserProfileStore.swift` | protected cache file；不再內嵌 avatar Data |
| `Feature/SearchHistory/Data/Storage/SearchHistoryStore.swift` | protected JSON file |
| `MyTMDB_App/Composition/AppComposition.swift` | 組裝新 storage / authorization dependencies |
| `MyTMDB_App/SceneDelegate.swift` | startup secure-storage failure / retry flow |
| `MyTMDB_App/Info.plist` | credential placeholder，不含 literal secret |
| `PrivacyInfo.xcprivacy` | Required Reason API 宣告 |
| `.gitignore` / `Secrets.xcconfig.example` | secret build setting hygiene |
| `MyTMDB_App.xcodeproj/project.pbxproj` | 僅在明確授權後加入新 source/resource membership 與 build config |

新 Swift source、Privacy Manifest 與 build configuration 必須同步確認 disk file、PBX file reference、group、BuildFile 與 Sources/Resources membership；`plutil -lint project.pbxproj` 只能證明 plist syntax，不能證明 target membership 或可執行。

---

## 16. 驗收標準

### 16.1 靜態檢查

- `SessionStore` 不再將 user / guest Session 寫入 `UserDefaults`。
- 全專案不再讀寫 `UserDefaults` 的 `AuthSession`、`TMDBSessionID`、`TMDBGuestSessionID`、`TMDBIsGuest`。
- 全專案無 `sessionID`、password、request token、API credential 的 logger interpolation。
- tracked `Info.plist` 不含 literal credential。
- `NetworkService` 不再加入 `api_key` query。
- 含 `session_id` / `guest_session_id` 的 request 明確禁止 cache。
- `PrivacyInfo.xcprivacy` plist syntax 正確，且包含 `NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1`。
- Domain / Presentation 不 import `Security`。
- ViewModel 不 import UIKit。
- Swift parser 與 `git diff --check` 通過。

### 16.2 Build 驗證

只有在使用者明確授權後執行：

- Xcode Simulator Debug build。
- 確認沒有觸發不必要的 SwiftPM / `Package.resolved` 變更。
- 確認新增 Swift、xcprivacy、xcconfig target membership。
- 產出 Archive 後檢查最終 app bundle 的 `PrivacyInfo.xcprivacy` 與 credential placeholder。

未執行前只能標示 Static Verified，不得標示 Build Passed 或 App Store Ready。

### 16.3 Runtime 驗證矩陣

| 編號 | 情境 | 預期 |
|------|------|------|
| R1 | Fresh install | 無 Keychain Session，自動建立 guest、寫入 Keychain 後進入首頁 |
| R2 | User login | user Session 只寫入 Keychain，UserDefaults 無 Session |
| R3 | Guest login | guest Session 只寫入 Keychain，UserDefaults 無 Session |
| R4 | 開發期 UserDefaults Session 殘留 | 不讀取舊 key，自動建立新的 Keychain guest session |
| R5 | Keychain 寫入失敗 | 不進受保護頁面並可重試 |
| R6 | Keychain payload 損壞 | fail closed，不回退到 stale defaults |
| R7 | App 重新啟動 | Keychain Session 正常恢復 |
| R8 | App 卸載再安裝 | installation ID 不符，舊 Keychain Session 不自動登入；清除後建立新 guest |
| R9 | User logout 成功 | 遠端撤銷後本機 Session/Profile 清除 |
| R10 | User logout 離線 | 不顯示成功，Session 保留並可重試 |
| R11 | local-only logout | 經第二次確認後清本機，UI 明示遠端可能仍有效 |
| R12 | Clear all local data | Session/Profile/Search/Image cache 依結果完整清除 |
| R13 | App Intent（首次解鎖後） | 可讀 Keychain；失敗時不洩漏 Session |
| R14 | Web login 取消 | 回到可操作登入頁，不視為帳密錯誤 |
| R15 | Web login callback 不符 | 拒絕建立 Session |
| R16 | Profile legacy migration | 新檔可讀後才刪 `StoredUserProfile` |
| R17 | Search legacy migration | 排序、去重、scope 與 15 筆上限不變 |
| R18 | Release archive | 無 literal credential；manifest 存在且可產生 privacy report |

Simulator 驗證不等同實機 Keychain、Data Protection、卸載重裝與鎖定狀態證據。R8、R13 與最終安全結論至少需要實機驗證。

---

## 17. 風險與回退

| 風險 | 影響 | 緩解／回退 |
|------|------|------------|
| K1 開發期 UserDefaults Session 不再相容 | 開發裝置需重新登入 | 產品尚未上線，採 clean cutover 並明確接受重新登入 |
| K2 Keychain error 被當成 loggedOut | 假登出、可能覆寫狀態 | throwing API + fail closed + retry UI |
| K3 Keychain 殘留跨 reinstall | 未預期自動登入 | installation ID 綁定與 mismatch delete |
| K4 Remote revoke 失敗仍顯示成功 | 外洩 Session 保持有效 | remote-first；local-only 二次確認 |
| K5 Remote revoke 成功但本機 delete 失敗 | UI 與 storage 不一致 | 顯示本機清除失敗；下次驗證 401/403 後重試清除 |
| K6 Web callback 被偽造 | 建立非預期 Session | 比對 callback、request token、授權結果 |
| K7 Secrets.xcconfig 未設定 | Build / 啟動失敗 | example + Release gate；禁止 fallback 到 committed secret |
| K8 Protected file migration 失敗 | Profile / Search 資料遺失 | atomic write + read-back；成功前保留 UserDefaults |
| K9 新檔漏 target membership | Build 或 archive 缺檔 | disk / pbxproj / build phase 三方檢查 |
| K10 誤稱 client credential 已保密 | 錯誤安全假設 | 文件明示 client binary 可擷取；高保密需求使用 Backend |

回退時不得把 Session 明文寫回 `UserDefaults`。若必須回退功能，保留 Keychain reader，只回退上層流程；未來正式版 schema 變更需另寫 Keychain envelope migration。

---

## 18. 完成定義

只有同時符合以下條件，才能將本 SDD 標記為 Implemented：

- Phase 1、2、3 已完成且驗收通過。
- 所有 P0 static checks、Build 與必要 runtime case 有實際證據。
- Session 不再寫入 `UserDefaults`。
- 標準登出會撤銷遠端 Session，失敗不會顯示假成功。
- Privacy Manifest 已進入最終 app bundle。
- 沒有新的 secret、credential 或敏感 URL 出現在 Git、log 或文件。
- P1 / P2 未完成項目明確標記 Deferred，不得以 P0 完成代稱整份 SDD 全部完成。

---

## 19. 官方參考

- [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain-services)
- [Apple Restricting Keychain Item Accessibility](https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility)
- [Apple UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)
- [Apple Privacy Manifest Files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Apple Describing Use of Required Reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Apple TN3183: Adding Required Reason API Entries](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest)
- [TMDB Session ID Authentication](https://developer.themoviedb.org/reference/authentication-how-do-i-generate-a-session-id)
- [TMDB Create Guest Session](https://developer.themoviedb.org/reference/authentication-create-guest-session)
- [TMDB Delete Session](https://developer.themoviedb.org/reference/authentication-delete-session)
- [TMDB Application Authentication](https://developer.themoviedb.org/docs/authentication-application)
- [TMDB Create Session with Login](https://developer.themoviedb.org/reference/authentication-create-session-from-login)

---

## 20. 修訂紀錄

| 版本 | 日期 | 內容 |
|------|------|------|
| 1.4 | 2026-09-26 | 對齊現況：Build 更新為 Passed，確認 Debug app bundle 內含 Privacy Manifest；Runtime 更新為 Partial；metadata 狀態改為規格／實作／驗證三欄 |
| 1.3 Default Guest Bootstrap | 2026-09-25 | 冷啟動無 Keychain session 時，由 `LaunchSessionResolver` 建立 TMDB guest 並在 read-back 驗證成功後進首頁；安全儲存錯誤仍 fail closed。Guest 建立端點修正為 GET；Source / Static Verified，Build / Runtime NotRun |
| 1.2 Prelaunch Keychain Cutover | 2026-09-18 | 產品尚未上線，移除所有 UserDefaults Session migration；user／guest Session 統一只存 Keychain，installation ID 保留為非憑證 reinstall marker |
| 1.1 P0 Source Implemented | 2026-09-18 | 完成 Phase 1–3 source、authenticated request no-store 與靜態檢查；Build、Archive、Runtime NotRun；P1、P2 Deferred |
| 1.0 Draft | 2026-09-18 | 依現行 source audit 建立 Keychain、遠端登出、網頁授權、credential hygiene、protected file 與 Privacy Manifest 分階段規格；Implementation / Build / Runtime 均 NotRun |
