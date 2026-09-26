# SDD: CineBase Tab Bar 重點擊捲回內容頂部

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| 文件 ID | `SDD-MAIN-TAB-BAR-RESELECTION-SCROLL-TO-TOP` |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| UI 架構 | UIKit + `UITabBarController` + `UINavigationController` + `UICollectionView` |
| 主要模組 | `MainTabBar`、`ScrollTrackingBaseViewController` |
| 規格狀態 | `Accepted` |
| 實作狀態 | `Done`（Base inset-aware scroll API 與 Tab reselect 捲回頂部） |
| 驗證狀態 | Build `Passed`（2026-09-26，iOS Simulator Debug）；Runtime `NotRun`（第 9.3 節 matrix 尚未執行） |
| 最後更新 | 2026-09-26 |

> 本版取代先前「重點擊 Tab 後 pop 到 navigation root」的錯誤解讀。正確需求是保留目前頁面與 navigation stack，只把目前畫面的垂直內容捲回頂部。檔案路徑沿用既有 SDD 連結。

---

## 1. 目的

當使用者再次點擊目前已選取的 Tab Bar item 時，將該 Tab 目前可見畫面的主要垂直內容，以 UIKit 原生 `UIScrollView.setContentOffset(_:animated:)` 捲回內容頂部。

「回到頂部」的定義：

- 回到目前 scroll view 的 top boundary，也就是 `-adjustedContentInset.top`。
- 保留目前 navigation stack，不 pop、不替換 ViewController。
- 不重新載入資料、不重建畫面、不重設搜尋或篩選狀態。

---

## 2. 目標與非目標

### 2.1 目標

- 首頁、搜尋、電影、影集、設定五個 Main Tab 使用一致行為。
- 只在使用者再次點擊目前 Tab 時捲回目前可見內容頂部。
- 使用既有 `UITabBarControllerDelegate` 判斷使用者重點擊。
- 使用 `UIScrollView`／`UICollectionView` 原生 content offset API 執行動畫。
- 由共用 `ScrollTrackingBaseViewController` 集中定義 top boundary 計算。
- 保留 Tab Bar Accessibility value、切換動畫、左右滑動與顯示／隱藏行為。
- 維持 Swift 6 MainActor 邊界；不把 UIKit 狀態放進 ViewModel。

### 2.2 非目標

- 不呼叫 `popToRootViewController` 處理 Tab 重點擊。
- 不清除或改寫任何 Tab 的 navigation stack。
- 不在切換到不同 Tab 時重設目標 Tab 的捲動位置。
- 不讓左右滑動、App Intent、deep link 或程式設定 `selectedIndex` 觸發捲回頂部。
- 不重新載入 ViewModel、collection view 或網路資料。
- 不自動關閉搜尋、鍵盤、sheet 或其他 presented controller。
- 不遞迴搜尋任意 View hierarchy 中的 scroll view。
- 不新增 Coordinator、Router、ViewModel API 或新的依賴注入項目。
- 不新增測試 Target、測試 Scheme、測試檔案或第三方套件。

---

## 3. 現況盤點

### 3.1 Main Tab 容器

`MainTabBarController` 建立五個 Tab，每個 Tab 都以 `UINavigationController` 包住 root Controller：

```text
MainTabBarController
├── UINavigationController → MainHomeViewController
├── UINavigationController → MainSearchViewController
├── UINavigationController → MainMediaListViewController (.movie)
├── UINavigationController → MainMediaListViewController (.tv)
└── UINavigationController → MainMemberSettingViewController
```

`MainTabBarController` 已透過 `UITabBarControllerDelegate` 的 `shouldSelect` 比較 `targetIndex` 與 `selectedIndex`，並在 `didSelect` 取得本次是否為 reselect。此判斷只回應使用者點擊 Tab Bar item，不會把程式切換 Tab 誤判成重點擊。

### 3.2 五個 Root Controller 的共用基底

五個 root Controller 全部繼承：

```text
MainBaseViewController
└── ScrollTrackingBaseViewController
    └── collectionView: UICollectionView
```

`ScrollTrackingBaseViewController` 已負責：

- 建立主要垂直 `collectionView`。
- 追蹤 collection view 捲動方向並顯示／隱藏 Tab Bar。
- 依 Dynamic Type 更新 layout。

因此「捲回主要內容頂部」屬於這個共用 UI base 的合理責任，不需要讓 `MainTabBarController` 存取各 Feature 的 private collection view，也不需要建立 Feature 型別白名單。

### 3.3 App Intent 導覽不在本次範圍

`MainTabBarController.navigationController(for:)` 現有的 `popToRootViewController(animated: false)` 是 App Intent／deep-link 入口使用的導覽前置處理：切到指定 Tab、清理舊 stack，再 push 指定目的地。

這條路徑必須保留，不能因為移除 Tab 重點擊的 pop 行為而刪除。

### 3.4 Xcode Target

`MyTMDB_App.xcodeproj` 目前只有 App Target `MyTMDB_App`，沒有 Test Target。本功能使用靜態檢查、App Build 與手動 Runtime matrix 驗證，不建立測試 Target。

---

## 4. 行為規格

| 操作 | 當前狀態 | 預期結果 |
|------|----------|----------|
| 再次點擊目前 Tab | 內容已向下捲動 | 目前可見畫面的主要 collection view 動畫捲回頂部 |
| 再次點擊目前 Tab | 已位於頂部 | 不操作、不閃動、不 reload |
| 再次點擊目前 Tab | navigation stack 超過一層且 Tab Bar 仍可見 | 保留 stack，只處理 top ViewController 支援的主要 scroll view |
| 再次點擊目前 Tab | top ViewController 不支援共用 scroll API | 安全忽略，不猜測其他 scroll view |
| 點擊不同 Tab | 任意 | 正常切換並保留兩側 navigation stack 與 content offset |
| 左右滑動切換 Tab | 任意 | 維持現行行為，不捲動內容 |
| 程式設定 `selectedIndex` | 任意 | 不視為使用者重點擊 |
| App Intent／deep link | 任意 | 維持既有導覽 reset 與 push 行為 |

---

## 5. 技術設計

### 5.1 `ScrollTrackingBaseViewController`

新增共用方法：

```swift
func scrollContentToTop(animated: Bool = true)
```

計算方式：

```swift
let topContentOffset = CGPoint(
    x: collectionView.contentOffset.x,
    y: -collectionView.adjustedContentInset.top
)
```

規則：

1. 使用 `adjustedContentInset.top`，正確包含 Navigation Bar、Safe Area、search bar 與 Feature 自訂 content inset。
2. 保留現有水平 offset；本功能只處理垂直位置。
3. 只有目前 `contentOffset.y` 大於 top boundary 才呼叫 `setContentOffset`。
4. 預設使用動畫。
5. 不 reload、不改 datasource、不發送 ViewModel action。

### 5.2 `MainTabBarController`

`didSelect` 保留既有流程：

1. 讀取 `isReselectingSelectedTab`。
2. 立即將 flag 重設為 `false`。
3. 更新 Tab Bar Accessibility value。
4. 呼叫 `scrollToTopIfNeeded(for:isReselection:)`。

Helper 行為：

```text
isReselection == true
        │
        ▼
Tab container 是 UINavigationController？
        │
        ▼
topViewController 是 ScrollTrackingBaseViewController？
        │
        ├── 否 → 安全忽略
        └── 是 → scrollContentToTop(animated: true)
```

使用 `topViewController` 而不是 navigation root：需求是捲動「目前可見畫面」，且不得改變 navigation stack。

### 5.3 不使用 View hierarchy 遞迴搜尋

不從 `UIView` hierarchy 找第一個 `UIScrollView`，原因如下：

- 搜尋畫面、橫向內容列、Carousel 與 cell 內部可能同時存在多個 scroll view。
- 遞迴找到的第一個 scroll view 不一定是主要垂直內容。
- 共用 base 已擁有明確的主要 collection view 契約。

若未來有 Main Tab 不再繼承 `ScrollTrackingBaseViewController`，應讓該 Controller 明確提供相同能力，而不是改成不受控的 hierarchy 掃描。

### 5.4 分層責任

```text
MainTabBarController
  └── 判斷是否為使用者重點擊目前 Tab
        └── ScrollTrackingBaseViewController
              └── 計算 top boundary 並操作自己的 collectionView
```

- `MainTabBarController` 不持有 Feature collection view。
- `ScrollTrackingBaseViewController` 不知道 Tab index 或 Tab 種類。
- ViewModel 不 import UIKit，也不接收 scroll action。
- Router 與 `AppComposition` 不需要修改。

---

## 6. 實際檔案異動

| 檔案 | 異動 |
|------|------|
| `Feature/Base/ScrollTrackingBase/ScrollTrackingBaseViewController.swift` | 新增 `scrollContentToTop(animated:)`，以 `-adjustedContentInset.top` 計算頂部 |
| `MainTabBar/Controller/MainTabBarController.swift` | 重點擊目前 Tab 時，對 navigation top Controller 呼叫共用捲回頂部 API |
| `Docs/SDD-MainTabBar-Reselection-Scroll-To-Top.md` | 修正需求、設計與驗證紀錄；沿用原文件路徑 |

未修改：

- `MainTabBar/ViewModel/MainTabBarViewModel.swift`
- `MyTMDB_App/Composition/AppComposition.swift`
- 各 Feature Router／ViewModel／root ViewController
- `MyTMDB_App.xcodeproj/project.pbxproj`
- Test Target 或測試檔案

---

## 7. Swift 6 與生命週期

- `MainTabBarController` 與 `ScrollTrackingBaseViewController` 都由 `@MainActor` 隔離。
- `UICollectionView` content offset 只在主執行緒更新。
- 不新增 `Task`、Combine pipeline、timer 或共享可變狀態。
- `isReselectingSelectedTab` 只存在於一次 `shouldSelect` → `didSelect` callback 配對。
- 不保存 scroll view 或 ViewController 的額外 strong reference。

---

## 8. 風險與防護

| 風險 | 影響 | 防護 |
|------|------|------|
| 仍執行 navigation pop | 使用者離開目前頁面 | Tab reselect helper 不呼叫 `popToRootViewController` |
| 以 `.zero` 當頂部 | Navigation Bar／Safe Area／content inset 下位置錯誤 | 使用 `-adjustedContentInset.top` |
| 已在頂部仍觸發動畫 | 畫面閃動 | offset guard，頂部時 no-op |
| 切換 Tab 時誤捲動 | 使用者失去原閱讀位置 | 只在 `targetIndex == selectedIndex` 時觸發 |
| 找錯巢狀 scroll view | 橫向列表或 Carousel 被重設 | 只操作共用 base 的主要 `collectionView` |
| 搜尋或篩選狀態被重置 | 使用者輸入遺失 | 不碰 search controller、ViewModel 或 datasource |
| App Intent 行為被破壞 | deep link 疊加在舊 stack | 保留 `navigationController(for:)` 的既有 pop |

---

## 9. 驗證計畫

### 9.1 靜態檢查

- [x] `MainTabBarController.swift` 與 `ScrollTrackingBaseViewController.swift` Swift frontend parse 通過。
- [x] `git diff --check` 通過。
- [x] `plutil -lint MyTMDB_App.xcodeproj/project.pbxproj` 通過。
- [x] Tab reselect helper 不再呼叫 `popToRootViewController`。
- [x] App Intent 專用的 `navigationController(for:)` 仍保留既有 pop。
- [x] ViewModel、Composition、Router 與 root Feature Controller 未修改。
- [x] 沒有新增 Test Target、測試檔案或第三方套件。

### 9.2 Build 驗證

- [ ] `MyTMDB_App` App Target Debug build 通過。
- [ ] Swift 6 Strict Concurrency 沒有新增 warning／error。

依專案規範，本次低風險小範圍變更不主動執行耗時 Build。若後續執行時遇到套件下載、模擬器啟動或卡住，需把 Build 與 Source 診斷分開記錄。

### 9.3 Runtime 驗收矩陣

| 案例 | Home | Search | Movie | TV | Settings |
|------|------|--------|-------|----|----------|
| 向下捲動後重點擊目前 Tab，動畫回頂 | [ ] | [ ] | [ ] | [ ] | [ ] |
| 回頂位置包含正確 Navigation Bar／search bar inset | [ ] | [ ] | [ ] | [ ] | [ ] |
| 已在頂部重點擊時不閃動、不 reload | [ ] | [ ] | [ ] | [ ] | [ ] |
| 搜尋、篩選與已載入內容保持不變 | [ ] | [ ] | [ ] | [ ] | [ ] |

跨功能迴歸：

- [ ] Tab A 向下捲動 → 切 Tab B → 回 Tab A，A 的原 offset 保留。
- [ ] Tab A 向下捲動 → 再點已選取的 A，只有 A 回頂。
- [ ] navigation stack 不因 Tab 重點擊而改變。
- [ ] 左右滑動切換 Tab 不改變任一內容 offset。
- [ ] Search active／鍵盤顯示時，不清除查詢或自動 dismiss。
- [ ] Tab Bar 捲動隱藏／顯示的既有 tracking 行為正常。
- [ ] App Intent／deep link 仍可切到指定 Tab 並顯示目的頁。
- [ ] VoiceOver selected／not selected value 維持正確。

---

## 10. 驗收條件

全部符合才可將實作狀態改為 `Implemented`：

1. 五個 Main Tab 向下捲動後，重點擊目前 Tab 都會動畫回到正確 top boundary。
2. navigation stack 在操作前後完全不變。
3. 切換不同 Tab 與左右滑動不會重設 content offset。
4. 已在頂部時不 reload、不閃動、不重建 Controller。
5. Search、filter、pagination 與 ViewModel state 不被重設。
6. App Intent／deep-link 導覽行為維持不變。
7. 沒有新增 Test Target、測試 Scheme、測試檔案或第三方套件。
8. Static、Build、Runtime 結果分別記錄；未執行的驗證不得標示為 Passed。

---

## 11. 狀態紀錄

| 檢查 | 狀態 | 證據 |
|------|------|------|
| Requirement correction | `Passed` | 2026-09-25：確認需求為 content scroll-to-top，不是 navigation pop-to-root |
| Architecture review | `Passed` | 五個 Main Tab root 都繼承 `ScrollTrackingBaseViewController`，共用主要 `collectionView` |
| Source implementation | `Passed` | Base 新增 inset-aware scroll API；Tab reselect 改呼叫 top Controller 的共用 API |
| Static verification | `Passed` | Swift parse、`git diff --check`、project `plutil -lint`、scope 搜尋均通過 |
| App Target build | `Passed` | 2026-09-26 iOS Simulator Debug build 通過 |
| Runtime verification | `NotRun` | 待於 Simulator／實機執行第 9.3 節 matrix |

---

## 12. 參考

- Apple Developer Documentation: [`UIScrollView.setContentOffset(_:animated:)`](<https://developer.apple.com/documentation/uikit/uiscrollview/setcontentoffset(_:animated:)>).
- Apple Developer Documentation: [`UIScrollView.adjustedContentInset`](https://developer.apple.com/documentation/uikit/uiscrollview/adjustedcontentinset).
- Apple Developer Documentation: [`UITabBarControllerDelegate.tabBarController(_:didSelect:)`](<https://developer.apple.com/documentation/uikit/uitabbarcontrollerdelegate/tabbarcontroller(_:didselect:)>).

---

## 13. 版本紀錄

| 版本 | 日期 | 內容 |
|------|------|------|
| 2.1 | 2026-09-26 | 對齊現況：App Target build 更新為 Passed；實作狀態由 Partial 改為 Done（source 已完成，僅 Runtime 未驗證）；metadata 狀態改為規格／實作／驗證三欄 |
| 2.0 | 2026-09-25 | 依使用者澄清全面修正：需求改為保留 navigation stack 並將目前內容捲回頂部；新增共用 inset-aware scroll API，撤銷 Tab reselect 的 pop-to-root 設計 |
| 1.1 | 2026-09-25 | 歷史錯誤版本：曾將需求實作為所有 Tab 共用 navigation pop-to-root；已由 2.0 取代 |
| 1.0 | 2026-09-25 | 歷史錯誤規劃：將「回到頂部」解讀為 navigation root；已由 2.0 取代 |
