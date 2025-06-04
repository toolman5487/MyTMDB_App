# MyTMDB_App
一款基於 The Movie Database (TMDB) API 的 iOS 應用，採用 UIKit + Combine + MVVM 架構，提供電影列表瀏覽、詳細資訊、收藏與評分功能。

## 功能特色
- **電影列表與搜尋**  
  - 使用 TMDB 的 Search/Multi 搜尋 API，能同時搜尋電影、影集與演員。  
  - 搜尋結果會自動依「發行／首播日期」由新到舊排序，並將電影、影集顯示在前，演員顯示在後。

- **電影詳情**  
  - 顯示單部電影的海報、標題、簡介、演員名單、預告影片等。  
  - 內嵌 YouTube Trailer 播放功能（使用 `YTPlayerView` + SnapKit 佈局），並能以固定高度呈現。

- **帳號認證（登入／註冊）**  
  - 採用 TMDB 提供的「Request Token → 使用者授權 → 換取 Session ID」流程登入。  
  - 登入後可呼叫「新增最愛」與「評分」API，管理個人最愛清單與影片評分。  
  - 在登入畫面提供「註冊」按鈕，點擊後以 `SFSafariViewController` 開啟 TMDB 官方註冊頁面。

- **收藏／評分功能**  
  - 「收藏」功能：點擊書籤按鈕即可將電影加入或移除最愛，按鈕會即時切換填滿狀態。  
  - 「評分」功能：點擊愛心按鈕後彈出半頁評分介面，使用滑桿選擇 0.5–10 分，提交後即時顯示實心愛心，並在幕後同步到 TMDB。

- **MVVM + Combine 架構**  
  - **Service 層**：封裝所有 TMDB API 呼叫（搜尋、詳情、最愛、評分、帳號狀態）。  
  - **ViewModel 層**：負責呼叫 Service、處理回傳並透過 `@Published` 將資料推送給 View 層。  
  - **View 層**：僅處理畫面與使用者互動，採用 `CombineCocoa` 監聽 UI 事件與綁定 ViewModel。

## 環境需求
- iOS 15.0 以上  
- Xcode 14.0 以上  
- Swift 5.6 以上  
- Swift Packages：  
  - SnapKit  
  - SDWebImage  
  - YouTube-Player-iOS-Helper  
  - CombineCocoa

# 安裝與執行
	•	Clone 專案
	•	在終端機輸入：
git clone https://github.com/你的帳號/MyTMDB_App.git
cd MyTMDB_App
	•	開啟 Xcode 並安裝套件
	•	在 Finder 中打開 MyTMDB_App.xcodeproj。
	•	Xcode 會自動讀取內部的 Swift Package 依賴，並下載：
  	•	SnapKit
  	•	SDWebImage
  	•	YouTube-Player-iOS-Helper
  	•	CombineCocoa
	•	設定 TMDB API Key
	•	在專案中開啟 TMDB.swift（或 Constants.swift），找到：
struct TMDB 
{ 
static let apiKey = "YOUR_API_KEY" 
static let baseURL = "https://api.themoviedb.org/3" 
}
	•	把 "YOUR_API_KEY" 改成你在 TMDB 官網申請的 API Key，然後存檔。
	•	執行 App
	•	選擇模擬器或真機後，按下 Run（⌘R）。
	•	首次啟動會顯示登入頁，若尚未擁有 TMDB 帳號，請點「註冊」按鈕在瀏覽器完成註冊。
	•	註冊完成後返回 App，輸入帳號與密碼並登入，即可瀏覽電影列表、查看詳情、加入最愛與評分。

# 使用說明
1.	登入
•	 使用 TMDB 官網註冊的帳號與密碼進行登入，登入成功後會取得 session_id，後續 API 呼叫皆以該 Session ID 驗證。
2.	電影列表與搜尋
	•	在主畫面輸入關鍵字後，搜尋結果會顯示電影、影集、演員，並依「發行／首播日期」由新到舊排序。
	•	支援空白鍵修剪後的關鍵字過濾，若輸入為空則清除結果。
3.	電影詳情
  •	點擊電影後可進入詳情頁面，包含海報、標題、簡介、演員名單與影片預告。
  •	若該電影有 YouTube Trailer，可在列表中直接播放，並且維持固定高度。
4.	收藏與評分
  •	詳情頁右上角有兩個按鈕：
    1.	書籤（Bookmark）：點擊後將電影加入或移除「我的最愛」清單，書籤圖示會隨狀態切換。
    2.	愛心（Heart）：點擊後彈出半頁評分介面，使用滑桿選擇 0.5–10 分，提交後愛心圖示會立刻變成實心，並在幕後更新到 TMDB。

# 技術細節
•	半頁評分介面
•	採用 iOS 15+ 的 UISheetPresentationController.Detent 自訂 1/4 螢幕高度，並以 SnapKit 排版滑桿與按鈕，滑動時即時顯示數值並動態調整字體大小。
•	Combine 資料流
•	所有 Service 層呼叫皆回傳 AnyPublisher<T, Error>，並在 ViewModel 中使用 .map、.tryMap、.receive(on: DispatchQueue.main) 等操作。
•	在 View 層使用 CombineCocoa 的 textPublisher、tapPublisher 監聽文字輸入與按鈕點擊，並利用 @Published 在 ViewModel 更新資料後自動更新 UI。
•	本地收藏資料庫
•	FavoritesLocalService 使用 Core Data 儲存電影最愛清單，並搭配 NSFetchedResultsController 在收藏頁面實現動態更新。

# 貢獻與回報
如果你有任何問題、建議或想請求新功能，請提交 Issue；若要發 Pull Request，請先確保程式碼風格與專案一致，並附上相應說明。

## 授權條款
本專案以 MIT Licence 授權，詳細條款請見專案根目錄中的文件。  
您可以自由使用、修改、合佈及轉載本專案程式碼，但需保留原作者版權聲明與本許可聲明。

