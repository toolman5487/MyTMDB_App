# MyTMDB_App

<p align="center">
  <img src="MyTMDB_App/Assets.xcassets/AppIcon.appiconset/CineBase1x.png" alt="CineBase App Icon" width="160" />
</p>

MyTMDB_App 是一款基於 [The Movie Database (TMDB)](https://www.themoviedb.org/) API 的 iOS App。專案以 UIKit 為主要 UI 技術，採用 MVVM、Service、Repository、Router 分層，並使用 Swift Concurrency 處理 API 請求與畫面狀態更新。

目前 App 以 TMDB 內容探索為核心，包含首頁推薦、電影與劇集分類列表、搜尋、詳細頁、季/集資訊、人物資訊、會員中心、收藏、觀看清單與評分流程。

## 主要功能

- **登入與 Session 管理**
  - 支援 TMDB 帳號登入與訪客 Session。
  - 登入流程使用 TMDB `Request Token -> Validate With Login -> Session`。
  - 啟動時會驗證已儲存的使用者 Session，失效時回到登入頁。
  - Session 透過 `SessionStore` 儲存在 `UserDefaults`，並保留舊 Key 的遷移邏輯。

- **首頁內容探索**
  - 首頁由多個 TMDB 分類區塊組成，例如 Trending、Popular、Now Playing、Upcoming、Top Rated 與 TV on air 相關內容。
  - `MainHomeService` 負責 API 請求，`MainHomePresentationBuilder` 負責組裝畫面資料。
  - 首頁內容使用系統語言、地區與時區參數取得在地化結果。

- **電影與劇集列表**
  - `MainMovieList` 使用 TMDB Genre 與 Discover Movie API。
  - `MainTVList` 使用 TMDB Genre 與 Discover TV API。
  - 支援分類篩選、排序與分頁載入。
  - 列表共用 `MovieGrid` 元件與分頁控制器。

- **搜尋**
  - `MovieSearch` 使用 TMDB Search Movie API。
  - `TVSearch` 使用 TMDB Search TV API。
  - 搜尋關鍵字會先移除前後空白，並排除 adult 內容。

- **詳細頁**
  - 支援 Movie、TV、Season、Episode、Person 詳細頁。
  - 詳細頁會整合基本資訊、演員/製作人員、影片、圖片、推薦內容、觀看平台與外部連結。
  - Movie/TV 詳細頁共用 `DetailBase`、`DetailRouter` 與底部操作列。
  - YouTube 預告片使用 `youtube-ios-player-helper` 播放。

- **收藏、觀看清單與評分**
  - 會員中心支援 favorite、watchlist、rated movies、rated TV、rated TV episodes 與 TMDB lists。
  - 收藏與觀看清單透過 TMDB Account API 更新。
  - 評分流程使用 `RatingPageSheetViewController`，以 `UISheetPresentationController` 呈現半頁評分介面。
  - 評分支援 Movie、TV 與 Episode 目標。

- **會員中心**
  - `MemberCenterViewModel` 管理會員頁狀態與展示資料。
  - `MemberCenterContentRepository` 負責會員內容組裝與快取。
  - `MemberCenterService` 專注 TMDB Account/List API 呼叫。
  - `MemberCenterRouter` 以語意化路由處理會員相關跳轉。

- **共用 UI 與主題**
  - App 主題 logo 使用 `MyTMDB_App/Assets.xcassets/AppIcon.appiconset/CineBase1x.png`。
  - `ThemeColor` 使用 TMDB 品牌色：`#0D253F`、`#01B4E4`。
  - `AppFactory` 集中建立常用 Label、Button 與 Animation View。
  - `AppAnimationView` 集中處理 Lottie 動畫生命週期。
  - `ErrorMessageView` 提供網路錯誤與空狀態畫面。
  - 專案目前以 Dark Mode 與系統色為主要 UI 基準。

## 技術架構

專案採用 feature-based 目錄結構，每個主要功能通常包含 Model、Service、ViewModel、View、Controller、Router。

```text
MyTMDB_App/
├── MyTMDB_App/              # AppDelegate、SceneDelegate、Info.plist、Assets
├── Network/                 # APIConfig、NetworkService、NetworkError、Localization
├── MainLogIn/               # 登入、訪客登入、Session、Root 切換
├── MainTabBar/              # 原生 UITabBarController 與 tab 狀態
├── MainHome/                # 首頁內容區塊
├── MainMovieList/           # 電影分類列表
├── MainTVList/              # 劇集分類列表
├── MovieSearch/             # 電影搜尋
├── TVSearch/                # 劇集搜尋
├── MovieDetail/             # 電影詳細頁
├── TVDetail/                # 劇集詳細頁
├── SeasonDetail/            # 季詳細頁
├── EisodeDetail/            # 集詳細頁
├── PersonDetail/            # 人物詳細頁
├── MemberCenter/            # 會員中心與帳號內容
├── MainMemberSetting/       # 會員設定頁
├── PageSheet/               # Rating、Genre、ReviewDetail 等 Sheet 畫面
└── Feature/                 # Base、Components、Config、Extension、Logger
```

### 分層原則

- **View / ViewController**：負責畫面組裝、使用者互動、collection view layout 與 ViewModel 綁定。
- **ViewModel**：管理畫面狀態，將 Service 回傳資料轉成 UI 可用的 presentation model。
- **Service**：封裝 TMDB API 呼叫與 JSON decode。
- **Repository**：處理跨 API 或跨資料來源的內容組裝與快取。
- **Router**：集中處理 push、present、page sheet、Safari 等導航規則。

## 環境需求

- iOS Deployment Target：18.4
- Swift：6.0
- Xcode：建議使用支援 Swift 6 與 iOS 18.4 SDK 的版本
- Swift Package Manager 依賴：
  - [SnapKit](https://github.com/SnapKit/SnapKit) `5.7.1+`
  - [SDWebImage](https://github.com/SDWebImage/SDWebImage) `5.21.0+`
  - [youtube-ios-player-helper](https://github.com/youtube/youtube-ios-player-helper) `1.0.4+`
  - [lottie-ios](https://github.com/airbnb/lottie-ios) `4.5.2+`
  - [SkeletonView](https://github.com/Juanpe/SkeletonView) `1.31.0+`

## 安裝與執行

1. Clone 專案：

   ```bash
   git clone https://github.com/toolman5487/MyTMDB_App
   cd MyTMDB_App
   ```

2. 使用 Xcode 開啟：

   ```text
   MyTMDB_App.xcodeproj
   ```

3. 確認 Swift Package 依賴已由 Xcode 解析完成。

4. 設定 TMDB API Key：

   `Network/APIConfig.swift` 會從 `Info.plist` 的 `TMDBAPIKey` 讀取 API Key。

   ```xml
   <key>TMDBAPIKey</key>
   <string>YOUR_TMDB_API_KEY</string>
   ```

   請到 [TMDB API Settings](https://www.themoviedb.org/settings/api) 申請 API Key，並將 `YOUR_TMDB_API_KEY` 換成自己的 key。

5. 選擇 iOS Simulator 或真機，按下 Xcode Run。

## API 與在地化

- API base URL：`https://api.themoviedb.org/3`
- 圖片 base URL：`https://image.tmdb.org/t/p`
- `NetworkService` 會自動在 query items 補上 `api_key`。
- 需要會員權限的 API 會另外帶入 `session_id`。
- `AppLocalization.current` 會依系統語言產生 TMDB `language`、`region`、`timezone` 與圖片/影片語言參數。

## 開發注意事項

- 使用 Swift 6 語言模式，新增跨執行緒傳遞的型別時應評估 `Sendable`。
- ViewModel 不應 import UIKit，也不應直接持有或操作 ViewController。
- API 請求優先使用 Swift Concurrency。
- 畫面狀態優先使用 enum 表達 loading、loaded、empty、failed 等狀態。
- 導航與 page sheet presentation policy 放在 Router。
- 新增共用 UI 前先確認是否屬於真正跨 feature 的需求，避免把 feature-only 邏輯放進 base class。
- 新增檔案後需確認 `MyTMDB_App.xcodeproj/project.pbxproj` 的 target membership。

## 測試

專案包含：

- `MyTMDB_AppTests`
- `MyTMDB_AppUITests`

可在 Xcode 內使用 Test action 執行。若要用命令列驗證，請依目前本機 Xcode 與 Simulator SDK 狀態調整目的地與 DerivedData 路徑。

## 資料來源

本專案使用 TMDB API，但未由 TMDB 官方背書或認證。內容、圖片與相關資料版權歸 TMDB 與原權利人所有。
