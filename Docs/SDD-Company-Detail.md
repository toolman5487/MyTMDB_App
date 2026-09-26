# SDD: CineBase 公司詳細頁面

| 項目 | 內容 |
|------|------|
| 文件類型 | Software Design Document |
| App | CineBase (`MyTMDB_App`) |
| Bundle ID | `co.willyhsu.CineBase` |
| 平台 | iOS 26.0+ |
| Swift | Swift 6.0，`SWIFT_STRICT_CONCURRENCY = complete` |
| 既有架構 | UIKit + MVVM + Clean Architecture + Router + `AppComposition` |
| 功能範圍 | 新增 `CompanyDetail` 模組（製作公司詳細頁面），從 MainSearch、MovieDetail 與 TVDetail 導入；第 11 節擴充 `DetailContentList` 共用元件的無限捲動分頁能力 |
| 狀態 | `CompanyDetail` 基礎模組與第 11 節分頁擴充：Build／Runtime Passed（2026-09-24）；MovieDetail／TVDetail 出品公司入口：Source Implementation Done、Static Verification Passed，Build／Runtime Pending（2026-09-25） |
| 日期 | 2026-09-24（初版）；2026-09-24 更新第 11 節；2026-09-25 新增 MovieDetail／TVDetail 出品公司入口；2026-09-26 新增公司標誌專用預覽頁 |

---

## 1. 目的

本文件定義 CineBase 的「製作公司詳細頁面」（Company Detail），對應 TMDB `/company/{id}` 家族端點。`APIConfig.Search.company` 已在 MainSearch 提供公司搜尋與篩選；MainSearch 公司結果及 MovieDetail／TVDetail 出品公司標籤都透過既有 `DetailRouter` 導向一致的公司資訊畫面。

本功能需符合下列原則：

- 沿用 `SDD-Clean-Architecture-Migration.md` 的分層與依賴方向（Domain → Data → Presentation → ViewModel → Controller/Router）。
- 沿用 `SDD-Unified-Interface-Naming.md` 的 Swift API、縮寫與 Router 命名規則。
- 架構、Section 結構、Cell 重用策略比照既有 `PersonDetail` 模組（TMDB 公司資料的形狀與人物資料高度相似：一則基本資料 + 多個輔助端點）。
- 不引入新的第三方套件（例如 SVG 圖片解碼器）。
- 不建立不必要的 UseCase、Repository 抽象；能重用既有共用元件（`DetailBase`、`MediaSummary`、`discover` 端點）就不重新發明。

若文件與實際 SDK／TMDB API 回應有差異，實作需以編譯結果與實際 API 回應為準，並回寫本文件。

---

## 2. 目標與非目標

> **2026-09-24 更新**：實作完成後，使用者要求「該公司與角色（PersonDetail）的所有作品都要看得到」。原本 2.1／2.2 對電影／影集清單「只顯示第一頁、不做查看更多」的範圍界定已被取代，改為第 11 節「內容清單無限捲動分頁擴充」。以下 2.1／2.2 反映目前（含分頁擴充）的完整目標；歷史決策脈絡保留在 3.4 供對照。

### 2.1 目標

- 新增 `CompanyDetail` 功能模組，結構比照 `PersonDetail`（Domain / Data / Presentation / ViewModel / Controller，無獨立 Router）。
- 顯示公司基本資訊：Logo、名稱、總部、成立地區（origin country）、母公司、簡介、官方網站。
- 顯示該公司出品的電影與影集，包含 TMDB 標記為成人內容的作品（各自一個橫向清單區塊，比照 `MovieDetail` 的 Recommendations／Similar）。
- 電影／影集橫向清單的 Section Header 可點擊「查看更多」，導向完整清單頁面（`DetailContentListViewController`），且該清單支援**無限捲動分頁**，直到 TMDB `discover` API 回報沒有下一頁為止（見第 11 節）。
- `PersonDetail` 既有「查看更多」（`movieCredits`／`tvCredits`）維持現狀：資料本來就一次拿齊、非分頁，使用者已經能看到該演員的全部作品，不需額外改動。
- 顯示公司別名（`/company/{id}/alternative_names`）與多國 Logo（`/company/{id}/images`）。
- 從 `MainSearch` 的公司搜尋結果可正確導頁至新頁面（取代目前的 no-op）。
- 從 `MovieDetail`／`TVDetail` 的出品公司標籤可導頁至相同的 `CompanyDetail`；類型與 Network 標籤維持既有行為。
- `APIConfig` 新增 `Company` 端點群組。
- 妥善處理 TMDB 公司 Logo 經常是 `.svg` 向量圖的情況（見 3.5、7.2、13）。

### 2.2 非目標

- 不處理母公司（`parent_company`）的巢狀導頁；母公司只顯示名稱文字，不可點擊。
- 不擴充 `MainMediaList`／`MediaListRepository`；分頁能力直接建立在 `DetailContentList` 模組上（見第 11 節），不與 genre-based 的媒體清單共用程式碼。
- 不改動 `PersonDetail` 的資料層（`combined_credits` 已是完整清單）；只有共用的 `DetailContentListViewController` 會新增「可分頁」能力，且該能力對 `PersonDetail` 是 opt-in（預設關閉，行為零異動）。
- 不下載或解析 SVG，不新增 SVG 圖片解碼套件；SVG 格式的 Logo 一律視為不可顯示，改用預留樣式。
- 不新增 Company 專屬 Router（比照 `PersonDetail`／`EpisodeDetail`，直接使用既有 `DetailRouting`／`DetailRouter`）。
- 不新增測試 target（專案既有慣例：使用者以手動 Build／Runtime 驗證，不建立單元測試）。
- 不修改 `project.pbxproj` 以外的專案設定（新檔案仍需加入 target membership，但不調整其他建置設定）。

---

## 3. 現況盤點

### 3.1 APIConfig 現況

`Feature/Data/Network/APIConfig.swift` 目前完全沒有 `Company` 端點群組。已存在但與公司相關的端點：

| 端點 | 現況 |
|------|------|
| `APIConfig.Search.company` | 已使用（MainSearch 公司搜尋） |
| `APIConfig.discover(kind:)` | 已存在，走 `Discover.movie` / `Discover.tv`，本功能可直接重用並加上 `with_companies` 查詢參數 |
| `/company/{id}` | 未定義 |
| `/company/{id}/alternative_names` | 未定義 |
| `/company/{id}/images` | 未定義 |

### 3.2 `ProductionCompany` 現況

`Feature/Domain/Entity/ProductionCompany.swift` 提供穩定的 `id` 與名稱；MovieDetail／TVDetail section builder 會將它映射成 `kind: .productionCompany` 的 attribute item，保留 `sourceID`。Attribute pill cell 將公司項目標示為可操作按鈕，Controller 再把該 ID 交給 feature router，最終由共用 `DetailRouter.showCompanyDetail(companyID:)` 導頁。

### 3.3 `PersonDetail` 作為結構範本

TMDB 的公司資料形狀與人物資料非常相似：一個「主要詳情」端點 + 數個獨立的輔助端點（別名、圖片），且都沒有內建分頁清單型的「credits」。因此本功能直接比照 `PersonDetail` 的分層：

| PersonDetail | CompanyDetail 對應 |
|--------------|--------------------|
| `/person/{id}` | `/company/{id}` |
| `/person/{id}` 內建的 `also_known_as` | `/company/{id}/alternative_names`（**注意：公司沒有內建欄位，需要獨立呼叫**） |
| `/person/{id}/images` | `/company/{id}/images` |
| `combined_credits`（人物完整作品清單，一次拿全部） | 無對應端點；改用 `discover/movie` `discover/tv` + `with_companies`（**分頁 API，只取第一頁**，見 3.4） |
| `PersonDetailError.invalidIdentifier` | `CompanyDetailError.invalidIdentifier` |
| `DefaultLoadPersonDetailUseCase` 的 `optional(...)` 容錯模式 | `DefaultLoadCompanyDetailUseCase` 沿用相同模式 |

### 3.4 「查看更多」機制不適用於公司作品清單（歷史決策，已被第 11 節取代）

> 本節是實作初版時的決策記錄。2026-09-24 使用者要求公司與演員頁面都要能看到「所有作品」後，結論已改變為：在 `DetailContentList` 共用元件上新增 opt-in 分頁能力（見第 11 節）。保留本節是為了讓後續維護者理解「為什麼一開始沒有直接做分頁」，避免重蹈覆轍或誤以為分頁是隨手加上去的。

`PersonDetail` 的 `movieCredits`／`tvCredits` 有「查看更多」（點 Section Header 觸發 `router.showContentList(...)`），原因是 `combined_credits` 一次回傳全部作品、無分頁，本地即可篩選/排序後整包塞進 `DetailContentListConfiguration`。

公司的電影／影集清單來自 `discover/movie?with_companies=` 與 `discover/tv?with_companies=`，是**伺服器分頁 API**，`DetailContentListConfiguration`／`showContentList` 原本的設計前提（items 已在本地備妥、不分頁）不成立。

`MovieDetail` 的 Recommendations／Similar 面對同樣是分頁 API 的情況，做法是**只取第一頁、當作固定長度的橫向清單、不提供查看更多**（`LoadMovieDetailUseCase` 固定 `recommendationPage: Int = 1`）。實作初版曾採用相同做法，理由是不想新建分頁清單畫面或擴充 `MainMediaList`；「查看更多完整片單」原本留給未來需要時再處理，但使用者提前提出了這個需求，因此第 11 節重新設計了「不擴充 `MainMediaList`、也能做到分頁」的做法（讓 `DetailContentList` 自己具備分頁能力，而不是共用 genre-based 的 `MediaListRepository`）。

### 3.5 SDWebImage 無法渲染 SVG

專案的 `Package.resolved` 只包含 `SDWebImage`、`SkeletonView`、`Lottie`、`SnapKit`、`youtube-ios-player-helper`，沒有任何 SVG 解碼套件（如 `SDWebImageSVGCoder`）。

TMDB 公司資料的 `logo_path`（`/company/{id}` 主欄位）與 `/company/{id}/images` 的 `logos[].file_path` **經常是 `.svg`**（許多製作公司只有向量 Logo，沒有點陣圖版本）。若原樣丟給 `SDWebImage`，圖片會載入失敗、顯示空白。

**決策**：Data／Presentation 層一律過濾副檔名為 `.svg` 的 Logo（見 6.2、7.2），不嘗試顯示；UI 層在沒有可用點陣圖時，改用中性預留樣式（building 圖示 + 底色），而非顯示破圖或空白 imageView。這與 2.2「不新增 SVG 套件」的非目標一致。

### 3.6 共用 `DetailBase` 元件盤點

`Feature/Base/DetailBase/Cell/` 已有跨模組共用的通用 Cell，本功能盡量重用：

| 共用元件 | 用途 | 目前使用者 |
|----------|------|-----------|
| `DetailImageTitleStripCollectionViewCell` | 橫向海報／圖片 + 標題 + 副標題清單 | Movie／TV／Season／Episode／Person（Recommendations、Similar、Credits、ProfileImages 等） |
| `DetailFactsCollectionViewCell` | 標題／數值成對的資訊列表 | Person（`PersonDetailFactsCollectionViewCell`） |
| `DetailExternalLinkCollectionViewCell`（`DetailExternalLinkStripCollectionViewCell`） | 外部連結清單（含 icon、開啟外部瀏覽器） | Person |
| `DetailSectionPreviewLimit.itemCount`（= 10） | 詳情頁預覽區塊統一截斷數量 | Movie／Person 等所有 Section Builder |

目前**沒有**通用的「文字 Pill 清單」元件；`PersonDetailAliasesCollectionViewCell` 是 Person 專屬實作（內部 `PersonDetailAliasPillCollectionViewCell` 是 `private`）。本功能的「別名」區塊需要相同的橫向 Pill 清單樣式，屬於第二個使用情境，因此本次**將其抽成共用元件**（見 6.2、9.1、13），符合本專案既有「同一種通用樣式被第二個 feature 需要時才抽到 `DetailBase`」的慣例（`DetailImageTitleStripCollectionViewCell`／`DetailFactsCollectionViewCell`／`DetailExternalLinkCollectionViewCell` 都是跨模組共用而非機能專屬）。

「文字＋內嵌標題」型的說明文字 Cell（`PersonDetailBiographyCollectionViewCell`）則**不抽共用**：Movie／TV／Season／Episode／Person 各自有一份幾乎相同但標題文案不同的 Overview／Biography Cell，這是本專案既有慣例（各 feature 自帶簡介 Cell），本功能比照建立 `CompanyDetailDescriptionCollectionViewCell`，不做額外重構。

---

## 4. TMDB API 對照

| 用途 | Method | Path | 新增到 APIConfig |
|------|--------|------|-------------------|
| 公司基本資料 | GET | `/company/{company_id}` | `APIConfig.Company.detail(id:)` |
| 公司別名 | GET | `/company/{company_id}/alternative_names` | `APIConfig.Company.alternativeNames(id:)` |
| 公司 Logo 清單 | GET | `/company/{company_id}/images` | `APIConfig.Company.images(id:)` |
| 該公司出品電影 | GET | `/discover/movie?with_companies={id}` | 重用 `APIConfig.discover(kind: .movie)` |
| 該公司出品影集 | GET | `/discover/tv?with_companies={id}` | 重用 `APIConfig.discover(kind: .tv)` |

`/company/{company_id}` 回應欄位（節錄，供 DTO 對照）：

```json
{
  "id": 1,
  "name": "Lucasfilm Ltd.",
  "description": "...",
  "headquarters": "Los Angeles, California",
  "homepage": "http://www.lucasfilm.com",
  "logo_path": "/o86DbpburjxrqAzEDhXZcyE8pDb.svg",
  "origin_country": "US",
  "parent_company": {
    "id": 2,
    "name": "The Walt Disney Studios",
    "logo_path": "/xdOueYWJdX41GKfxLwEAiVKtBcw.png"
  }
}
```

`/company/{company_id}/alternative_names`：

```json
{
  "id": 1,
  "results": [
    { "name": "Lucasfilm", "type": "Short Name" }
  ]
}
```

`/company/{company_id}/images`：

```json
{
  "id": 1,
  "logos": [
    { "file_path": "/o86DbpburjxrqAzEDhXZcyE8pDb.svg", "aspect_ratio": 2.35, "width": 512, "height": 218, "vote_average": 5.384, "vote_count": 1, "file_type": ".svg" },
    { "file_path": "/tvSlvwFqSlikP4S3l2VggO2fmr4.png", "aspect_ratio": 1.77, "width": 200, "height": 113, "vote_average": 0, "vote_count": 0, "file_type": ".png" }
  ]
}
```

`description`、`homepage`、`headquarters`、`parent_company` 皆可能為 `null` 或空字串，Data／Presentation 層需與 `Person.biography`／`homepage` 相同方式容錯。

---

## 5. Domain 設計

### 5.1 Entity

```swift
// CompanyDetail/Domain/Entity/Company.swift
nonisolated struct Company: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let headquarters: String?
    let homepage: URL?
    let logoPath: String?
    let originCountry: String?
    let parentCompany: CompanyReference?
}

nonisolated struct CompanyReference: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
}
```

```swift
// CompanyDetail/Domain/Entity/CompanyDetailContent.swift
nonisolated struct CompanyDetailContent: Sendable, Equatable {
    let detail: Company
    let alternativeNames: [CompanyAlternativeName]
    let images: CompanyImages
    let movies: Page<MediaSummary>
    let tvShows: Page<MediaSummary>
}
```

```swift
// CompanyDetail/Domain/Entity/CompanyMetadata.swift
nonisolated struct CompanyAlternativeName: Sendable, Equatable {
    let name: String
    let type: String?
}

nonisolated struct CompanyImages: Sendable, Equatable, Identifiable {
    let id: Int
    let logos: [CompanyLogo]

    static func empty(id: Int) -> CompanyImages {
        CompanyImages(id: id, logos: [])
    }
}

nonisolated struct CompanyLogo: Sendable, Equatable {
    let filePath: String
    let aspectRatio: Double
    let width: Int
    let height: Int
    let voteAverage: Double
    let voteCount: Int

    var isVectorFormat: Bool {
        filePath.lowercased().hasSuffix(".svg")
    }
}
```

`movies`／`tvShows` 直接重用既有 `Page<MediaSummary>`（`Feature/Domain/Entity/Page.swift`、`Feature/Domain/Entity/MediaSummary.swift`），不新增型別。`MediaSummary` 本身不帶 `mediaType`，公司頁需要同時顯示電影與影集兩個區塊，因此在 Presentation 層才附加 `MediaKind`（見 7.1，比照 `PersonDetailCreditItem` 顯式攜帶 `mediaType`）。

### 5.2 Error

```swift
// CompanyDetail/Domain/Error/CompanyDetailError.swift
nonisolated enum CompanyDetailError: Error, Equatable {
    case invalidIdentifier
}
```

比照 `PersonDetailError`：公司不是 `MediaKind`，不重用 `DomainError.invalidIdentifier(MediaKind)`，改用 feature-local error type。

### 5.3 Repository Protocol

```swift
// CompanyDetail/Domain/Repository/CompanyDetailProviding.swift
nonisolated protocol CompanyDetailProviding: Sendable {
    func company(id: Int) async throws -> Company
    func alternativeNames(companyID: Int) async throws -> [CompanyAlternativeName]
    func images(companyID: Int) async throws -> CompanyImages
    func movies(companyID: Int, page: Int) async throws -> Page<MediaSummary>
    func tvShows(companyID: Int, page: Int) async throws -> Page<MediaSummary>
}
```

`company(id:)` 使用 `id`（方法名稱已指出實體），其餘方法需要與其他實體區分或未來可能擴充多個 ID 參數，使用具名 `companyID`——與 `PersonDetailProviding` 的 `person(id:)` vs `combinedCredits(personID:)` 命名方式一致。

### 5.4 UseCase

```swift
// CompanyDetail/Domain/UseCase/LoadCompanyDetailUseCase.swift
nonisolated protocol LoadCompanyDetailUseCase: Sendable {
    func callAsFunction(companyID: Int) async throws -> CompanyDetailContent
}

nonisolated struct DefaultLoadCompanyDetailUseCase: LoadCompanyDetailUseCase {

    private let repository: CompanyDetailProviding
    private let failureReporter: AuxiliaryLoadFailureReporting

    init(
        repository: CompanyDetailProviding,
        failureReporter: AuxiliaryLoadFailureReporting
    ) {
        self.repository = repository
        self.failureReporter = failureReporter
    }

    func callAsFunction(companyID: Int) async throws -> CompanyDetailContent {
        guard companyID > 0 else { throw CompanyDetailError.invalidIdentifier }

        async let alternativeNames = optional(
            name: "company alternative names",
            companyID: companyID,
            fallback: [CompanyAlternativeName]()
        ) {
            try await repository.alternativeNames(companyID: companyID)
        }
        async let images = optional(
            name: "company images",
            companyID: companyID,
            fallback: CompanyImages.empty(id: companyID)
        ) {
            try await repository.images(companyID: companyID)
        }
        async let movies = optional(
            name: "company movies",
            companyID: companyID,
            fallback: Page<MediaSummary>.empty()
        ) {
            try await repository.movies(companyID: companyID, page: 1)
        }
        async let tvShows = optional(
            name: "company tv shows",
            companyID: companyID,
            fallback: Page<MediaSummary>.empty()
        ) {
            try await repository.tvShows(companyID: companyID, page: 1)
        }

        let detail = try await repository.company(id: companyID)

        return await CompanyDetailContent(
            detail: detail,
            alternativeNames: alternativeNames,
            images: images,
            movies: movies,
            tvShows: tvShows
        )
    }

    private func optional<T: Sendable>(
        name: String,
        companyID: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            failureReporter.reportAuxiliaryFailure(name, target: "company \(companyID)", error: error)
            return fallback
        }
    }
}
```

只有 `company(id:)` 是必要資料、失敗即整頁失敗；其餘四項都是輔助資料，個別失敗只記錄、不影響其餘區塊顯示——與 `DefaultLoadMovieDetailUseCase`、`DefaultLoadPersonDetailUseCase` 完全一致的容錯策略。

---

## 6. Data 設計

### 6.1 APIConfig

在 `Feature/Data/Network/APIConfig.swift`，於 `Collection` 與 `Configuration` 之間（維持既有字母序）新增：

```swift
// MARK: - Company

enum Company {
    static func detail(id: Int) -> String { "/company/\(id)" }
    static func alternativeNames(id: Int) -> String { "/company/\(id)/alternative_names" }
    static func images(id: Int) -> String { "/company/\(id)/images" }
}
```

### 6.2 DTO

```swift
// CompanyDetail/Data/DTO/CompanyDetailDTO.swift
nonisolated struct CompanyDetailDTO: Decodable, Sendable {
    let id: Int
    let name: String?
    let description: String?
    let headquarters: String?
    let homepage: String?
    let logoPath: String?
    let originCountry: String?
    let parentCompany: CompanyReferenceDTO?

    enum CodingKeys: String, CodingKey {
        case id, name, description, headquarters, homepage
        case logoPath = "logo_path"
        case originCountry = "origin_country"
        case parentCompany = "parent_company"
    }
}

nonisolated struct CompanyReferenceDTO: Decodable, Sendable {
    let id: Int
    let name: String?
    let logoPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
    }
}

nonisolated struct CompanyAlternativeNamesResponseDTO: Decodable, Sendable {
    let id: Int
    let results: [CompanyAlternativeNameDTO]
}

nonisolated struct CompanyAlternativeNameDTO: Decodable, Sendable {
    let name: String?
    let type: String?
}

nonisolated struct CompanyImagesDTO: Decodable, Sendable {
    let id: Int
    let logos: [CompanyLogoDTO]
}

nonisolated struct CompanyLogoDTO: Decodable, Sendable {
    let filePath: String?
    let aspectRatio: Double?
    let width: Int?
    let height: Int?
    let voteAverage: Double?
    let voteCount: Int?

    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
        case aspectRatio = "aspect_ratio"
        case width, height
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}
```

`movies`／`tvShows` 直接重用既有 `MediaSummaryDTO` 與 `TMDBPageResponse<MediaSummaryDTO>`（`Feature/Data/DTO/MediaDTO.swift`、`Feature/Data/Mapper/MediaDTO+Mapping.swift`），不新增 DTO。

### 6.3 Mapper

```swift
// CompanyDetail/Data/Mapper/CompanyDetailDTO+Mapping.swift
extension CompanyDetailDTO {
    func mapped() -> Company {
        Company(
            id: id,
            name: name ?? "",
            description: description,
            headquarters: headquarters,
            homepage: homepage.flatMap(URL.init(string:)),
            logoPath: logoPath,
            originCountry: originCountry,
            parentCompany: parentCompany?.mapped()
        )
    }
}

extension CompanyReferenceDTO {
    func mapped() -> CompanyReference {
        CompanyReference(id: id, name: name ?? "", logoPath: logoPath)
    }
}

extension CompanyAlternativeNamesResponseDTO {
    func mapped() -> [CompanyAlternativeName] {
        results.compactMap { dto in
            guard let name = dto.name, !name.isEmpty else { return nil }
            return CompanyAlternativeName(name: name, type: dto.type)
        }
    }
}

extension CompanyImagesDTO {
    func mapped() -> CompanyImages {
        CompanyImages(
            id: id,
            logos: logos.compactMap { $0.mapped() }
        )
    }
}

extension CompanyLogoDTO {
    func mapped() -> CompanyLogo? {
        guard let filePath, !filePath.isEmpty else { return nil }
        return CompanyLogo(
            filePath: filePath,
            aspectRatio: aspectRatio ?? 1,
            width: width ?? 0,
            height: height ?? 0,
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0
        )
    }
}
```

SVG 過濾**不**在 Mapper 做（Mapper 只負責 DTO → Entity 的忠實轉換），而是在 Presentation 的 Section Builder 過濾（見 7.2），理由是 `CompanyLogo.isVectorFormat` 是 Domain 層可查詢的事實，過濾與否屬於「這個畫面能不能顯示這張圖」的 Presentation 決策，未來若換了具備 SVG 能力的圖片元件，只需改 Section Builder。

### 6.4 Repository

```swift
// CompanyDetail/Data/Repository/CompanyDetailRepository.swift
nonisolated final class CompanyDetailRepository: CompanyDetailProviding {

    private let network: NetworkServicing
    private let localization: AppLocalization

    init(
        network: NetworkServicing,
        localization: AppLocalization = .current
    ) {
        self.network = network
        self.localization = localization
    }

    func company(id: Int) async throws -> Company {
        let dto: CompanyDetailDTO = try await network.get(
            path: APIConfig.Company.detail(id: id),
            queryItems: []
        )
        return dto.mapped()
    }

    func alternativeNames(companyID: Int) async throws -> [CompanyAlternativeName] {
        let dto: CompanyAlternativeNamesResponseDTO = try await network.get(
            path: APIConfig.Company.alternativeNames(id: companyID),
            queryItems: []
        )
        return dto.mapped()
    }

    func images(companyID: Int) async throws -> CompanyImages {
        let dto: CompanyImagesDTO = try await network.get(
            path: APIConfig.Company.images(id: companyID),
            queryItems: []
        )
        return dto.mapped()
    }

    func movies(companyID: Int, page: Int) async throws -> Page<MediaSummary> {
        let dto: TMDBPageResponse<MediaSummaryDTO> = try await network.get(
            path: APIConfig.discover(kind: .movie),
            queryItems: discoverQueryItems(kind: .movie, companyID: companyID, page: page)
        )
        return dto.mapped()
    }

    func tvShows(companyID: Int, page: Int) async throws -> Page<MediaSummary> {
        let dto: TMDBPageResponse<MediaSummaryDTO> = try await network.get(
            path: APIConfig.discover(kind: .tv),
            queryItems: discoverQueryItems(kind: .tv, companyID: companyID, page: page)
        )
        return dto.mapped()
    }

    private func discoverQueryItems(
        kind: MediaKind,
        companyID: Int,
        page: Int
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "language", value: localization.languageParameter)
        ]

        if kind == .movie {
            queryItems.append(URLQueryItem(name: "region", value: localization.regionCode))
        }

        queryItems.append(contentsOf: [
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "include_adult", value: "true"),
            URLQueryItem(name: "with_companies", value: String(companyID)),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ])

        return queryItems
    }
}
```

`/company/{id}`、`alternative_names`、`images` 三個端點在 TMDB 文件中不支援 `language` 參數（名稱、別名、Logo metadata 本身無語系差異），因此不加 `language` query item，比照 `PersonDetailRepository.images(personID:)`／`externalIDs(personID:)` 的做法（那兩個呼叫也是 `queryItems: []`）。

`include_adult` 固定為 `true`，讓公司電影與影集清單包含 TMDB 標記為成人內容的作品。`sort_by` 固定 `popularity.desc`，不提供排序切換（見第 11 節的完整分頁清單）。`discoverQueryItems` 不與 `MediaListRepository.discoverQueryItems` 共用：兩者查詢條件不同（`with_genres` + 可變 `sortOrder` vs 固定 `with_companies` + 固定排序），且專案中 `MovieDetailRepository.recommendations`／`similar` 與 `MediaListRepository.discover` 本來就是各自獨立的查詢建構，不強行共用。

---

## 7. Presentation 設計

### 7.1 Section Item 與展示模型

```swift
// CompanyDetail/Presentation/CompanyDetailPresentationModels.swift
nonisolated enum CompanyDetailSectionItem: Sendable, Equatable {
    case header(CompanyDetailHeaderSectionItem)
    case facts([CompanyDetailFactItem])
    case movies([CompanyDetailMediaItem])
    case tvShows([CompanyDetailMediaItem])
    case logos([CompanyDetailLogoItem])
    case alternativeNames([CompanyDetailAlternativeNameItem])
    case externalLinks([CompanyDetailExternalLinkItem])

    func title(localization: AppInterfaceLocalization) -> String? {
        switch self {
        case .header:
            return nil

        case .facts:
            return localization.string("company_detail.section.information", defaultValue: "Company Information")

        case .movies:
            return localization.string("company_detail.section.movies", defaultValue: "Movies")

        case .tvShows:
            return localization.string("company_detail.section.tv_shows", defaultValue: "TV Shows")

        case .logos:
            return localization.string("company_detail.section.logos", defaultValue: "Logos")

        case .alternativeNames:
            return localization.string("company_detail.section.alternative_names", defaultValue: "Also Known As")

        case .externalLinks:
            return localization.string("detail.section.external_links", defaultValue: "Related Links")
        }
    }
}

nonisolated struct CompanyDetailHeaderSectionItem: Sendable, Equatable {
    let hero: CompanyDetailHeroItem
    let description: String?
}

nonisolated struct CompanyDetailItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let logoURL: URL?
    let headquartersText: String?
    let originCountryText: String?
    let parentCompanyText: String?
    let homepageURL: URL?

    init(detail: Company, localization: AppInterfaceLocalization) {
        self.id = detail.id
        self.name = BaseDisplayTextFormatter.text(
            detail.name,
            fallback: localization.string("common.fallback.unnamed", defaultValue: "Unnamed")
        )
        self.description = BaseDisplayTextFormatter.nonEmptyText(detail.description)
        self.logoURL = Self.makeLogoURL(path: detail.logoPath)
        self.headquartersText = BaseDisplayTextFormatter.nonEmptyText(detail.headquarters)
        self.originCountryText = Self.makeOriginCountryText(detail.originCountry, localization: localization)
        self.parentCompanyText = BaseDisplayTextFormatter.nonEmptyText(detail.parentCompany?.name)
        self.homepageURL = detail.homepage
    }

    private static func makeLogoURL(path: String?) -> URL? {
        guard let path, !path.isEmpty, !path.lowercased().hasSuffix(".svg") else { return nil }
        return TMDBResourceURL.image(path: path, size: .w500)
    }

    private static func makeOriginCountryText(
        _ countryCode: String?,
        localization: AppInterfaceLocalization
    ) -> String? {
        guard let countryCode, !countryCode.isEmpty else { return nil }
        return localization.language.locale.localizedString(forRegionCode: countryCode) ?? countryCode
    }
}

nonisolated struct CompanyDetailHeroItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let logoURL: URL?
    let metadataText: String?

    init(detail: CompanyDetailItem) {
        self.id = detail.id
        self.name = detail.name
        self.logoURL = detail.logoURL
        self.metadataText = BaseDisplayTextFormatter.metadata([
            detail.originCountryText,
            detail.headquartersText
        ])
    }
}

nonisolated struct CompanyDetailFactItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String

    init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

nonisolated struct CompanyDetailMediaItem: Sendable, Equatable, Identifiable {
    let id: String
    let sourceID: Int
    let mediaKind: MediaKind
    let title: String
    let dateText: String?
    let scoreText: String?
    let posterURL: URL?

    init(
        summary: MediaSummary,
        mediaKind: MediaKind,
        localization: AppInterfaceLocalization
    ) {
        self.id = "\(mediaKind.rawValue)-\(summary.id)"
        self.sourceID = summary.id
        self.mediaKind = mediaKind
        self.title = BaseDisplayTextFormatter.text(
            summary.title,
            fallback: localization.string("common.fallback.untitled", defaultValue: "Untitled")
        )
        self.dateText = BaseDisplayTextFormatter.isoDayText(from: summary.releaseDate)
        self.scoreText = BaseDisplayTextFormatter.score(summary.voteAverage, voteCount: summary.voteCount)
        self.posterURL = summary.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }
}

nonisolated struct CompanyDetailLogoItem: Sendable, Equatable, Identifiable {
    let id: String
    let imageURL: URL?
    let sizeText: String

    init(logo: CompanyLogo) {
        self.id = logo.filePath
        self.imageURL = TMDBResourceURL.image(path: logo.filePath, size: .w500)
        self.sizeText = BaseDisplayTextFormatter.resolutionText(width: logo.width, height: logo.height)
    }
}

nonisolated struct CompanyDetailAlternativeNameItem: Sendable, Equatable, Identifiable {
    let id: String
    let name: String

    init(alternativeName: CompanyAlternativeName) {
        self.id = alternativeName.name
        self.name = alternativeName.name
    }
}

nonisolated struct CompanyDetailExternalLinkItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String
    let url: URL
}
```

`MediaKind` 沒有內建 `rawValue` 相容 id 字串時，`id` 組字串改用 `mediaKind == .movie ? "movie" : "tv"`；實作時以既有 `MediaKind` 實際介面為準（比照 `PersonDetailCreditItem.id` 的 `resolvedMediaType.idValue` 寫法）。

`originCountryText` 是唯一需要新增格式化邏輯的欄位：`Company.originCountry` 是 ISO 3166-1 兩碼（如 `"US"`），直接顯示代碼對使用者不友善。已確認 `Feature/Formatter/BaseFormatter.swift` 目前只有 `SimplifiedChineseTextMapper`、`CrewJobDisplayMapper`，沒有地區名稱對照表，因此不新增自訂 ISO 3166 對照表（範圍膨脹），改用 Foundation 內建的 `Locale.localizedString(forRegionCode:)` 依目前介面語系轉換（例如 `"US"` → 依語系顯示「美國」／「アメリカ合衆国」／`"United States"`），取不到對照時原樣顯示代碼字串。

### 7.2 Section Builder

```swift
// CompanyDetail/Presentation/CompanyDetailSectionBuilder.swift
nonisolated enum CompanyDetailSectionBuilder {

    static func makeSections(
        content: CompanyDetailContent,
        localization: AppInterfaceLocalization
    ) -> [CompanyDetailSectionItem] {
        let detailItem = CompanyDetailItem(detail: content.detail, localization: localization)

        var sections: [CompanyDetailSectionItem] = [
            .header(
                CompanyDetailHeaderSectionItem(
                    hero: CompanyDetailHeroItem(detail: detailItem),
                    description: detailItem.description
                )
            )
        ]

        let facts = makeFacts(detail: detailItem, localization: localization)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let movieItems = content.movies.items
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { CompanyDetailMediaItem(summary: $0, mediaKind: .movie, localization: localization) }
        if !movieItems.isEmpty {
            sections.append(.movies(Array(movieItems)))
        }

        let tvItems = content.tvShows.items
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { CompanyDetailMediaItem(summary: $0, mediaKind: .tv, localization: localization) }
        if !tvItems.isEmpty {
            sections.append(.tvShows(Array(tvItems)))
        }

        let logoItems = content.images.logos
            .filter { !$0.isVectorFormat }
            .sorted { $0.voteAverage > $1.voteAverage }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(CompanyDetailLogoItem.init(logo:))
        if !logoItems.isEmpty {
            sections.append(.logos(Array(logoItems)))
        }

        let alternativeNameItems = content.alternativeNames
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(CompanyDetailAlternativeNameItem.init(alternativeName:))
        if !alternativeNameItems.isEmpty {
            sections.append(.alternativeNames(Array(alternativeNameItems)))
        }

        let externalLinks = makeExternalLinks(detail: detailItem, localization: localization)
        if !externalLinks.isEmpty {
            sections.append(.externalLinks(externalLinks))
        }

        return sections
    }

    private static func makeFacts(
        detail: CompanyDetailItem,
        localization: AppInterfaceLocalization
    ) -> [CompanyDetailFactItem] {
        [
            makeFact(
                title: localization.string("company_detail.fact.headquarters", defaultValue: "Headquarters"),
                value: detail.headquartersText
            ),
            makeFact(
                title: localization.string("company_detail.fact.origin_country", defaultValue: "Origin Country"),
                value: detail.originCountryText
            ),
            makeFact(
                title: localization.string("company_detail.fact.parent_company", defaultValue: "Parent Company"),
                value: detail.parentCompanyText
            )
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> CompanyDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return CompanyDetailFactItem(title: title, value: value)
    }

    private static func makeExternalLinks(
        detail: CompanyDetailItem,
        localization: AppInterfaceLocalization
    ) -> [CompanyDetailExternalLinkItem] {
        [
            detail.homepageURL.map {
                CompanyDetailExternalLinkItem(
                    id: "homepage",
                    title: localization.string("company_detail.link.homepage", defaultValue: "Official Website"),
                    value: $0.absoluteString,
                    url: $0
                )
            }
        ].compactMap { $0 }
    }
}
```

`.filter { !$0.isVectorFormat }` 是 3.5 決策的落地位置：Logo 區塊只顯示點陣圖；若某公司全部 Logo 都是 SVG，`logoItems` 會是空陣列，`.logos` 區塊整段不顯示（與 Person 的 `profileImages` 為空時不顯示同一邏輯）。Header 的 `CompanyDetailItem.makeLogoURL` 也套用相同過濾，因此當 `logo_path` 是 SVG 時，Hero 直接視為「無 Logo」，交由 UI 層顯示預留樣式（見 9.1）。

---

## 8. ViewModel 設計

```swift
// CompanyDetail/ViewModel/CompanyDetailViewModel.swift
nonisolated enum CompanyDetailViewState: Equatable {
    case idle
    case loading
    case loaded([CompanyDetailSectionItem])
    case failed(ErrorMessage)
}

@MainActor
final class CompanyDetailViewModel {

    private(set) var state: CompanyDetailViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (CompanyDetailViewState) -> Void)?
    private let loadCompanyDetailUseCase: LoadCompanyDetailUseCase
    private let localization: AppInterfaceLocalization
    private var content: CompanyDetailContent?

    init(
        loadCompanyDetailUseCase: LoadCompanyDetailUseCase,
        localization: AppInterfaceLocalization
    ) {
        self.loadCompanyDetailUseCase = loadCompanyDetailUseCase
        self.localization = localization
    }

    func bind(onStateChange: @escaping @MainActor (CompanyDetailViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    func loadInitialContent(companyID: Int) async {
        state = .loading
        content = nil

        do {
            let loadedContent = try await loadCompanyDetailUseCase(companyID: companyID)
            guard !Task.isCancelled else { return }
            content = loadedContent
            state = .loaded(CompanyDetailSectionBuilder.makeSections(
                content: loadedContent,
                localization: localization
            ))
        } catch let error as CompanyDetailError {
            guard !Task.isCancelled else { return }
            state = .failed(detailErrorMessage(for: error))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    func contentListConfiguration(for mediaKind: MediaKind) -> DetailContentListConfiguration? {
        guard let content else { return nil }
        return CompanyDetailContentListPresentationBuilder.makeContentListConfiguration(
            content: content,
            mediaKind: mediaKind,
            localization: localization
        )
    }

    private func detailErrorMessage(for error: CompanyDetailError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return ErrorMessage(
                title: localization.string("company_detail.error.not_found.title", defaultValue: "Company Not Found"),
                message: localization.string(
                    "company_detail.error.invalid_id.message",
                    defaultValue: "The company ID is invalid. Go back and try again."
                ),
                actionTitle: nil
            )
        }
    }
}
```

比 `PersonDetailViewModel` 更簡單：沒有 `loadCreditsList`／`PersonDetailCreditsListResult` 對應機制（見 3.4 的歷史脈絡），只有 `loadInitialContent(companyID:)` 與同步的 `contentListConfiguration(for:)`，命名遵循 `SDD-Unified-Interface-Naming.md` 5.4「首次載入完整畫面 → `loadInitialContent()`」規則。

> **已實作**：以上為目前 `CompanyDetailViewModel.swift` 的實際內容。`contentListConfiguration(for:)` 目前只回傳第一頁資料組成的 `DetailContentListConfiguration`；第 11 節會把它擴充成同時回傳一個可選的分頁提供者，讓「查看更多」畫面能繼續往下捲動載入。

---

## 9. View / Cell 設計

### 9.1 Header：`CompanyDetailHeroHeaderView`

結構比照 `PersonDetailHeroHeaderView`，差異：

- Logo 顯示為**正方形、`.scaleAspectFit`**，而非人物頭像的 2:3 `.scaleAspectFill`縱向照片（公司 Logo 通常是方形／橫向，變形拉伸會很明顯）。
- Logo 容器背景使用淺色底板 `ThemeColor.backgroundInverted`（即 `.label`；App 全域鎖定深色模式，解析後為白色），而非偏深的 `ThemeColor.fillSecondary`。原因：TMDB 公司 Logo 常見「透明背景＋深色線條」設計，深色模式下若容器背景也偏深，Logo 會幾乎不可見。此為 Runtime 驗收必須實機檢查的項目（見 12.3、13）。
- `logoURL == nil`（含 3.5 的 SVG 過濾情況）時，顯示中性預留樣式：系統圖示 `building.2.fill` 置中於固定底色容器，不留空白 imageView。
- 點擊 Logo **不**開啟圖片預覽（`router.showImagePreview`）；Logo 屬於品牌識別圖像，不是「可瀏覽的圖庫」語意，這點與 Person 的頭像不同。`Logos` 區塊（9.4）才是可瀏覽、可預覽的圖片集合。

```swift
func configure(with item: CompanyDetailHeroItem, localization: AppInterfaceLocalization)
static func headerHeight() -> CGFloat
```

### 9.2 說明文字：`CompanyDetailDescriptionCollectionViewCell`

結構比照 `PersonDetailBiographyCollectionViewCell`（見 3.6，刻意不共用）：內嵌標題「簡介」（`company_detail.description.title`，defaultValue `"About"`）+ 內文，`description == nil` 時該 Cell 不顯示（`numberOfItemsInSection` 回傳 0，比照 Person 的 biography 處理）。

### 9.3 Facts：`CompanyDetailFactsCollectionViewCell`

```swift
final class CompanyDetailFactsCollectionViewCell: DetailFactsCollectionViewCell {
    func configure(facts: [CompanyDetailFactItem]) {
        configure(facts: facts.map { DetailFactItem(title: $0.title, value: $0.value) })
    }
}
```

直接重用共用元件，比照 `PersonDetailFactsCollectionViewCell`。

### 9.4 Movies／TV Shows／Logos：重用 `DetailImageTitleStripCollectionViewCell`

三個橫向清單各自一個薄封裝 Cell，比照 `PersonDetailMovieCreditsCollectionViewCell`／`MovieDetailRecommendationsCollectionViewCell`：

```swift
final class CompanyDetailMoviesCollectionViewCell: DetailImageTitleStripCollectionViewCell {
    func configure(
        items: [CompanyDetailMediaItem],
        localization: AppInterfaceLocalization,
        onItemSelected: @escaping (CompanyDetailMediaItem) -> Void
    )
}

final class CompanyDetailTVShowsCollectionViewCell: DetailImageTitleStripCollectionViewCell { /* 同上 */ }

final class CompanyDetailLogosCollectionViewCell: DetailImageTitleStripCollectionViewCell {
    func configure(
        items: [CompanyDetailLogoItem],
        localization: AppInterfaceLocalization,
        onImageSelected: @escaping (URL) -> Void
    )
}
```

`Movies`／`TVShows` 點擊透過 `router.showMediaDetail(kind:id:)` 導頁（重用既有方法，不新增）。`Logos` 清單的圖片底色使用 `.label`；點擊後由 Router 顯示 `CompanyLogoImagePreviewViewController`。圖片預覽的分頁、縮放、手勢與 accessibility 行為集中在 `BaseImagePreviewViewController`；基底不持有任何顏色，只宣告 `previewBackgroundColor`、`previewForegroundColor`、`previewPageIndicatorColor`、`previewTitleColor`、`previewCloseButtonBackgroundColor`（未覆寫即 `fatalError`），由各子類別覆寫，狀態列樣式也由子類別覆寫 `preferredStatusBarStyle`。`DetailImagePreviewViewController` 使用 `ThemeColor.background` 背景、`ThemeColor.textPrimary` 控制元件與 `.lightContent` 狀態列（全域鎖定深色模式下即黑底白色控制元件）；`CompanyLogoImagePreviewViewController` 使用 `.label` 背景、`.systemBackground` 控制元件與 `.darkContent` 狀態列，維持與頁面的反差；兩者頁點為前景色 32%、關閉按鈕底色為背景色 48% 透明度，標題皆為 `ThemeColor.highlight`。

### 9.5 別名：`CompanyDetailAlternativeNamesCollectionViewCell`（新增共用基礎元件）

比照 3.6／6.3 的決策，將 `PersonDetailAliasesCollectionViewCell` 的通用邏輯抽成 `Feature/Base/DetailBase/Cell/DetailPillListCollectionViewCell.swift`：

```swift
// Feature/Base/DetailBase/Cell/DetailPillListCollectionViewCell.swift
struct DetailPillItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
}

class DetailPillListCollectionViewCell: BaseNestedCollectionViewCell {
    func configure(items: [DetailPillItem], localization: AppInterfaceLocalization)
    static func fittingHeight(for items: [DetailPillItem]) -> CGFloat
}
```

`PersonDetailAliasesCollectionViewCell` 改為：

```swift
final class PersonDetailAliasesCollectionViewCell: DetailPillListCollectionViewCell {
    func configure(items: [PersonDetailAliasItem], localization: AppInterfaceLocalization) {
        configure(
            items: items.map { DetailPillItem(id: $0.id, title: $0.name) },
            localization: localization
        )
    }
}
```

`CompanyDetailAlternativeNamesCollectionViewCell` 比照：

```swift
final class CompanyDetailAlternativeNamesCollectionViewCell: DetailPillListCollectionViewCell {
    func configure(items: [CompanyDetailAlternativeNameItem], localization: AppInterfaceLocalization) {
        configure(
            items: items.map { DetailPillItem(id: $0.id, title: $0.name) },
            localization: localization
        )
    }
}
```

此重構**必須保持 Person 畫面像素級不變**（Pill 樣式、圓角、邊框、無障礙文字皆不變），僅搬動程式碼位置。驗收方式見 11.1（source diff 檢查 Person 既有畫面邏輯無行為變更）與 11.3（Person 詳情頁「Also Known As」區塊 Runtime 截圖比對）。

### 9.6 External Links：重用 `DetailExternalLinkStripCollectionViewCell`

```swift
final class CompanyDetailExternalLinksCollectionViewCell: DetailExternalLinkStripCollectionViewCell {
    func configure(
        items: [CompanyDetailExternalLinkItem],
        localization: AppInterfaceLocalization,
        onLinkSelected: @escaping (URL) -> Void
    )
    static func fittingHeight(for items: [CompanyDetailExternalLinkItem]) -> CGFloat
}
```

Phase 1 只有 `homepage` 一種連結（見 2.2，母公司不可點擊，也不算外部連結）。

### 9.7 Controller

`CompanyDetailViewController` 結構、Section 高度計算、`UICollectionViewDataSource`／`UICollectionViewDelegateFlowLayout` 實作方式全部比照 `PersonDetailViewController`（見 3.3 對照表），差異只在：

- 不需要 `creditsListTask`／`loadCreditsList`（無「查看更多」）。
- `sections[indexPath.section]` 的 `case` 對應改為 `header`／`facts`／`movies`／`tvShows`／`logos`／`alternativeNames`／`externalLinks`。
- Navigation title 由 `.header` 區塊的 `hero.name` 提供（比照 `detailNavigationTitle(from:)` 讀 `.biography` 的寫法）。

---

## 10. Router 與 Scene Builder 設計

### 10.1 `DetailRouting` / `DetailRouter`

`Feature/Base/DetailBase/Router/DetailRouter.swift` 新增：

```swift
protocol DetailRouting {
    // 既有方法...
    func showCompanyDetail(companyID: Int)
}

extension DetailRouter {
    func showCompanyDetail(companyID: Int) {
        guard companyID > 0 else { return }
        show(sceneBuilder.makeCompanyDetailViewController(companyID: companyID), using: .push)
    }
}
```

命名與參數形狀比照 `showPersonDetail(personID:)`（純 scalar identifier、方法名稱已含實體、使用具名 `companyID`），符合 `SDD-Unified-Interface-Naming.md` 5.5。

不新增 `CompanyDetailRouting`／`CompanyDetailRouter`：本頁沒有跨畫面轉發需求，比照 `PersonDetail`／`EpisodeDetail` 直接持有 `DetailRouting`。

### 10.2 `DetailSceneBuilding`

`MyTMDB_App/Composition/AppComposition.swift`：

```swift
protocol DetailSceneBuilding: LoginSceneBuilding {
    // 既有方法...
    func makeCompanyDetailViewController(companyID: Int) -> UIViewController
}
```

實作：

```swift
func makeCompanyDetailViewController(companyID: Int) -> UIViewController {
    let repository = CompanyDetailRepository(network: network, localization: localization)
    let viewModel = CompanyDetailViewModel(
        loadCompanyDetailUseCase: DefaultLoadCompanyDetailUseCase(
            repository: repository,
            failureReporter: AppLoggerAuxiliaryFailureReporter()
        ),
        localization: interfaceLocalization
    )
    return CompanyDetailViewController(
        companyID: companyID,
        viewModel: viewModel,
        sceneBuilder: self,
        interfaceLocalization: interfaceLocalization
    )
}
```

與 `makePersonDetailViewController` 逐行對應，`AppLoggerAuxiliaryFailureReporter` 為既有實作，直接重用。

### 10.3 MainSearch 導頁收尾

`Main/MainSearch/Router/MainSearchRouter.swift` 目前（本次對話稍早新增）：

```swift
switch item.mediaType {
    // ...
    case .company:
        break
}
```

本功能完成後改為：

```swift
case .company:
    detailRouter.showCompanyDetail(companyID: item.sourceID)
```

### 10.4 MovieDetail／TVDetail 出品公司入口

MovieDetail／TVDetail 保留既有 UIKit／MVVM／Router／DI 邊界：section builder 只產生帶有 `sourceID` 的 presentation item；attribute pill cell 只回傳使用者選取的 item；ViewController 依 `kind` 分流；Movie／TV 專屬 router 再轉發到共用 `DetailRouter`。`AppComposition` 沿用既有 `makeCompanyDetailViewController(companyID:)`，不建立第二套 CompanyDetail factory，也不改動其他 attribute UI。

---

## 11. 內容清單無限捲動分頁擴充

本節為 2026-09-24 追加：使用者要求公司（`CompanyDetail`）與演員（`PersonDetail`）頁面的作品清單都要能看到「所有作品」。`PersonDetail` 本來就沒有這個問題（`combined_credits` 一次回傳全部），需要新設計的只有 `CompanyDetail` 的電影／影集清單如何從「第一頁」擴充成「無限捲動直到 TMDB 回報沒有下一頁」。

### 11.1 問題重述

`DetailContentListViewController`（見 3.4／10 節）目前是**完全靜態**的清單：初始化時收到 `DetailContentListConfiguration.items` 之後就不再變動，沒有 `loadNextPageIfNeeded`、沒有分頁狀態。這個假設對 `PersonDetail`成立（資料本來就是全部），對 `CompanyDetail` 不成立（`discover` API 每頁最多 20 筆，公司作品可能有數百筆）。

### 11.2 設計原則

- **`PersonDetail` 零異動、零風險**：`DetailContentListConfiguration` 的既有欄位（`title`／`thumbnailStyle`／`items`）完全不變；分頁能力以「額外、可選」的方式注入，`PersonDetail` 的呼叫端不需要修改一行程式碼，行為與現在完全相同。
- **`DetailContentList` 維持與功能無關**：分頁的「怎麼拿下一頁資料」由呼叫端（`CompanyDetail`）提供，`DetailContentList` 只依賴一個通用協定，不 import `CompanyDetailProviding` 或任何 Company 專屬型別，維持 `SDD-Clean-Architecture-Migration.md` 的依賴方向。
- **不擴充 `MainMediaList`**：`MediaListRepository` 是為 genre-based 瀏覽設計的（見 3.4），這裡不與它共用，改直接讓 `CompanyDetailProviding` 現有的 `movies(companyID:page:)`／`tvShows(companyID:page:)` 被重複呼叫。
- **重用既有分頁基礎設施**：`MediaGridPaginationState.shouldLoadNextPage(currentIndex:itemCount:)` 與 `MediaGridPaginationTaskController` 已經是與功能無關的共用元件（`MainSearch`、`MainMediaList` 都在用），直接搬進 `DetailContentListViewController`，不重新發明一套分頁判斷邏輯。
- **Swift 6 並行安全**：分頁提供者需要在多次呼叫之間記住「目前拿到第幾頁」，用 `actor` 而非 `@unchecked Sendable class`，讓編譯器保證正確性，不使用專案裡少見的並行安全豁免。

### 11.3 `DetailContentListPageProviding`（新協定，`DetailContentList/Domain/`）

```swift
// DetailContentList/Domain/DetailContentListPageProviding.swift
protocol DetailContentListPageProviding: Sendable {
    func loadNextPage() async throws -> DetailContentListPage
}

nonisolated struct DetailContentListPage: Sendable, Equatable {
    let items: [DetailContentListItem]
    let canLoadNextPage: Bool
}
```

`DetailContentList` 模組因此第一次擁有 `Domain` 子資料夾；這個協定完全不知道呼叫端是 Company、還是未來其他 feature，只負責「再給我一批項目，以及還能不能再要」。

> **實作時發現**：協定本身**不能**加 `nonisolated`（本專案其餘 `XxxProviding` 協定都是 `nonisolated protocol ... : Sendable`，這裡是唯一例外）。原因是 11.7 的 `CompanyDetailContentListPageProvider` 是 `actor`；`actor` 遵循一個宣告為 `nonisolated` 的 protocol 時，編譯器會出現 `'nonisolated' on an actor's synchronous initializer is invalid`——`actor` 的 initializer 本身已經有特殊的隔離規則，再疊加協定層級的 `nonisolated` 會產生衝突。這個協定只有 `Sendable` 精煉與一個 `async` 方法，拿掉 `nonisolated` 不影響任何並行安全性，純粹是為了讓 `actor` 能正常遵循它。已用 `xcodebuild build`（非只有 typecheck）驗證過這個修正；純 `swiftc -typecheck` 沒有重現這個錯誤，代表這類問題必須以完整 Build 驗收，不能只信賴 typecheck（見 12.2）。

### 11.4 `DetailContentListConfiguration` 不變

維持 6.1 節既有定義：

```swift
nonisolated struct DetailContentListConfiguration: Sendable, Equatable {
    let title: String
    let thumbnailStyle: DetailContentListThumbnailStyle
    let items: [DetailContentListItem]
}
```

分頁能力**不**塞進這個型別（避免它因為帶有 `any DetailContentListPageProviding` 而失去 `Equatable`，進而波及 `PersonDetailCreditsListResult: Equatable` 等既有型別），而是在 Router／Controller 層以獨立參數傳遞（見 11.6）。

### 11.5 `DetailContentListViewController` 改動

```swift
final class DetailContentListViewController: BaseListViewController {

    private let configuration: DetailContentListConfiguration
    private let pageProvider: (any DetailContentListPageProviding)?

    private var items: [DetailContentListItem]
    private var canLoadNextPage: Bool
    private var isLoadingNextPage = false
    private let paginationTaskController = MediaGridPaginationTaskController()

    init(
        configuration: DetailContentListConfiguration,
        pageProvider: (any DetailContentListPageProviding)? = nil,
        sceneBuilder: DetailSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.configuration = configuration
        self.pageProvider = pageProvider
        self.items = configuration.items
        self.canLoadNextPage = pageProvider != nil
        ...
    }

    // UICollectionViewDataSource 改讀 `items`，不再直接讀 `configuration.items`。

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        loadNextPageIfNeeded(currentIndex: indexPath.item)
    }

    private func loadNextPageIfNeeded(currentIndex: Int) {
        guard let pageProvider, canLoadNextPage, !isLoadingNextPage else { return }
        guard !paginationTaskController.isRunning else { return }
        guard MediaGridPaginationState.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: items.count
        ) else { return }

        isLoadingNextPage = true

        paginationTaskController.run { [weak self] in
            guard let self else { return }
            defer { isLoadingNextPage = false }

            do {
                let page = try await pageProvider.loadNextPage()
                let existingIDs = Set(items.map(\.id))
                let newItems = page.items.filter { !existingIDs.contains($0.id) }
                let insertedIndexPaths = (items.count..<(items.count + newItems.count))
                    .map { IndexPath(item: $0, section: 0) }

                items.append(contentsOf: newItems)
                canLoadNextPage = page.canLoadNextPage

                guard !insertedIndexPaths.isEmpty else { return }
                collectionView.insertItems(at: insertedIndexPaths)
            } catch {
                // 下一頁載入失敗時保持現有清單可用，不打斷使用者；不新增錯誤提示 UI（見 13 的風險處理）。
                canLoadNextPage = false
            }
        }
    }
}
```

`didSelectItemAt`／`showDestination` 邏輯不變，只是索引來源從 `configuration.items` 換成 `items`。`.image`／`.gallery` 目的地（見 10.1 的 `DetailContentListRouter.showDestination`）目前只有 Person 的圖庫清單在用，`Company` 只用 `.portrait` + `.movie`／`.tv`，不受影響（見 11.10 已知限制）。

### 11.6 `DetailRouting`／`DetailSceneBuilding` 簽章擴充

```swift
protocol DetailRouting {
    // 既有方法...
    func showContentList(
        _ configuration: DetailContentListConfiguration,
        pageProvider: (any DetailContentListPageProviding)?
    )
}

extension DetailRouting {
    func showContentList(_ configuration: DetailContentListConfiguration) {
        showContentList(configuration, pageProvider: nil)
    }
}
```

```swift
protocol DetailSceneBuilding: LoginSceneBuilding {
    // 既有方法...
    func makeDetailContentListViewController(
        configuration: DetailContentListConfiguration,
        pageProvider: (any DetailContentListPageProviding)?
    ) -> UIViewController
}
```

`PersonDetailViewController` 現有呼叫 `router.showContentList(configuration)` 完全不用改：透過 protocol extension 的預設多載，等同呼叫 `showContentList(configuration, pageProvider: nil)`，`DetailContentListViewController` 收到 `pageProvider == nil` 時行為與現在一模一樣。

`AppComposition.makeDetailContentListViewController` 實作：

```swift
func makeDetailContentListViewController(
    configuration: DetailContentListConfiguration,
    pageProvider: (any DetailContentListPageProviding)?
) -> UIViewController {
    DetailContentListViewController(
        configuration: configuration,
        pageProvider: pageProvider,
        sceneBuilder: self,
        interfaceLocalization: interfaceLocalization
    )
}
```

### 11.7 `CompanyDetailContentListPageProvider`（新檔案，`CompanyDetail/Presentation/`）

```swift
actor CompanyDetailContentListPageProvider: DetailContentListPageProviding {

    private let repository: CompanyDetailProviding
    private let companyID: Int
    private let mediaKind: MediaKind
    private let localization: AppInterfaceLocalization
    private var nextPage: Int
    private var totalPages: Int

    init(
        repository: CompanyDetailProviding,
        companyID: Int,
        mediaKind: MediaKind,
        startingPage: Page<MediaSummary>,
        localization: AppInterfaceLocalization
    ) {
        self.repository = repository
        self.companyID = companyID
        self.mediaKind = mediaKind
        self.localization = localization
        self.nextPage = startingPage.number + 1
        self.totalPages = startingPage.totalPages
    }

    func loadNextPage() async throws -> DetailContentListPage {
        guard nextPage <= totalPages else {
            return DetailContentListPage(items: [], canLoadNextPage: false)
        }

        let page: Page<MediaSummary>
        switch mediaKind {
        case .movie:
            page = try await repository.movies(companyID: companyID, page: nextPage)

        case .tv:
            page = try await repository.tvShows(companyID: companyID, page: nextPage)
        }

        totalPages = page.totalPages
        nextPage = page.number + 1

        return DetailContentListPage(
            items: page.items.map {
                CompanyDetailContentListPresentationBuilder.makeItem(
                    summary: $0,
                    mediaKind: mediaKind,
                    localization: localization
                )
            },
            canLoadNextPage: nextPage <= totalPages
        )
    }
}
```

用 `actor` 而非一般 `class`：`nextPage`／`totalPages` 是跨 `await` 呼叫需要保留的可變狀態，`actor` 讓編譯器保證每次 `loadNextPage()` 呼叫序列化執行、不會有資料競爭，天生滿足 `Sendable`，不需要 `@unchecked Sendable`。

`CompanyDetailContentListPresentationBuilder.makeItem(summary:mediaKind:localization:)` 需要從 `private` 改成 `internal`（見 6/7 節既有的 `private static func makeItem`），讓這個新的 `actor` 可以重用同一份映射邏輯，Person／Movie 那類「重複程式碼」的問題不會發生。

### 11.8 `CompanyDetailViewModel` 改動

```swift
@MainActor
final class CompanyDetailViewModel {

    private let loadCompanyDetailUseCase: LoadCompanyDetailUseCase
    private let repository: CompanyDetailProviding
    private let localization: AppInterfaceLocalization
    private var content: CompanyDetailContent?

    init(
        loadCompanyDetailUseCase: LoadCompanyDetailUseCase,
        repository: CompanyDetailProviding,
        localization: AppInterfaceLocalization
    ) {
        self.loadCompanyDetailUseCase = loadCompanyDetailUseCase
        self.repository = repository
        self.localization = localization
    }

    // loadInitialContent(companyID:) 不變（見 8 節）。

    func contentList(
        companyID: Int,
        mediaKind: MediaKind
    ) -> CompanyDetailContentListResult? {
        guard let content else { return nil }

        guard let configuration = CompanyDetailContentListPresentationBuilder.makeContentListConfiguration(
            content: content,
            mediaKind: mediaKind,
            localization: localization
        ) else { return nil }

        let page: Page<MediaSummary> = mediaKind == .movie ? content.movies : content.tvShows
        let pageProvider: (any DetailContentListPageProviding)? = page.hasNextPage
            ? CompanyDetailContentListPageProvider(
                repository: repository,
                companyID: companyID,
                mediaKind: mediaKind,
                startingPage: page,
                localization: localization
            )
            : nil

        return CompanyDetailContentListResult(configuration: configuration, pageProvider: pageProvider)
    }
}

// MARK: - CompanyDetailContentListResult

struct CompanyDetailContentListResult: Sendable {
    let configuration: DetailContentListConfiguration
    let pageProvider: (any DetailContentListPageProviding)?
}
```

`CompanyDetailContentListResult` 用具名 struct 取代匿名 tuple，放在 `CompanyDetail/Presentation/CompanyDetailPresentationModels.swift`；只宣告 `Sendable`，不宣告 `Equatable`（`pageProvider` 是 protocol existential，天生無法比較相等，這是刻意的取捨，不影響任何既有型別）。

新增的 `repository: CompanyDetailProviding` 依賴直接注入 Domain repository protocol，不透過 UseCase：比照既有 `MainSearchViewModel` 同時持有 `LoadMainSearchDiscoveryUseCase` 與 `MainSearchProviding` 的做法（複雜的整頁編排走 UseCase；單一、直接的資料存取走 Repository protocol），不需要為了「叫用一支既有 Repository 方法」新增一個只做轉呼叫的 UseCase。

`contentListConfiguration(for:)`（8 節、已實作）被 `contentList(companyID:mediaKind:)` 取代；改成需要 `companyID` 參數，比照 `PersonDetailViewModel.loadCreditsList(personID:mediaType:)` 每次呼叫都帶入 `personID` 的既有慣例（ViewModel 不重複保存 Controller 已經有的識別值）。

### 11.9 `CompanyDetailViewController` 改動

```swift
private func showContentList(for mediaKind: MediaKind) {
    guard let result = viewModel.contentList(companyID: companyID, mediaKind: mediaKind) else { return }
    router.showContentList(result.configuration, pageProvider: result.pageProvider)
}
```

Runtime 驗收新增（併入 12.3）：

- 找一間作品數量明顯超過 20 筆的公司（例如 Marvel Studios、Warner Bros. Pictures），進入「電影」或「影集」查看更多頁面，持續往下捲動，確認清單會不斷載入下一頁，直到 TMDB 沒有更多資料為止（可比對 `total_pages` 或捲到底後不再增加）。
- 確認 `PersonDetail` 任一演員的「查看更多」（`movieCredits`／`tvCredits`）行為與外觀完全沒有變化（分頁能力預設關閉）。
- 模擬網路中斷：捲到需要載入下一頁時斷網，確認清單維持目前已載入的項目、不崩潰、`canLoadNextPage` 安靜地變成 `false`（見 13 風險處理，第一版不做重試 UI）。

### 11.10 已知限制

- `DetailContentListRouter.showDestination` 的 `.image` 分支會用「當下傳入 Router 的 `configuration.items`」組成圖庫預覽清單（見 10.1 程式碼）；如果一個分頁清單同時是 `.gallery` 縮圖樣式又用 `.image` 目的地，使用者捲動載入的新項目不會出現在圖庫預覽裡。`CompanyDetail` 目前只用 `.portrait` + `.movie`／`.tv`，不受影響；未來若有 feature 想要「可分頁的圖庫」，需要一併修正這個 Router 方法讀取即時 `items` 而非建立時的快照。
- 分頁提供者失敗後不會自動重試，也不會顯示「載入失敗，點擊重試」的列。第一版選擇「安靜失敗、停止分頁」，避免在共用清單元件裡新增另一套錯誤 UI；如果之後量到失敗率不低，再回來加。
- TMDB `discover` API 沒有速率限制文件明確保證，公司作品數量很大時使用者若瘋狂捲動可能短時間內觸發多次請求；`MediaGridPaginationTaskController`／`isLoadingNextPage` 已經避免同時發出兩個請求，但沒有額外的節流（debounce）。與 `MainSearch`／`MainMediaList` 目前的做法一致，不算本功能特有風險。

---

## 12. 靜態檢查與驗證邊界

### 12.1 Source 檢查

```bash
rg -n "APIConfig.Company\.|CompanyDetailProviding|LoadCompanyDetailUseCase" \
  CompanyDetail Feature/Data/Network/APIConfig.swift

rg -n "showCompanyDetail|makeCompanyDetailViewController" \
  Feature/Base/DetailBase MyTMDB_App/Composition Main/MainSearch

rg -n "DetailPillListCollectionViewCell" \
  Feature/Base/DetailBase PersonDetail CompanyDetail

rg -n "\.svg" CompanyDetail

rg -n "DetailContentListPageProviding|DetailContentListPage\b" \
  DetailContentList CompanyDetail

rg -n "showContentList" \
  Feature/Base/DetailBase MyTMDB_App/Composition PersonDetail CompanyDetail

git diff --check
```

預期：

- `CompanyDetail` 模組完全依循 Domain → Data → Presentation → ViewModel → Controller 方向，Presentation／ViewModel 不 import UIKit（Cell／Controller 除外）。
- `DetailPillListCollectionViewCell` 抽出後，`PersonDetail` 與 `CompanyDetail` 都是薄封裝。
- SVG 過濾邏輯只出現在 Data Mapper（略過空字串）與 Presentation Section Builder／`CompanyDetailItem`（過濾 `.svg`），不會意外出現在 Domain 層。
- `PersonDetailViewController` 呼叫 `router.showContentList(...)` 的地方維持一個參數的舊寫法（走 11.6 的 protocol extension 預設多載），不需要因為分頁擴充而修改。
- `DetailContentListPageProviding` 只出現在 `DetailContentList/Domain/` 與 `CompanyDetail/Presentation/`，不會被 `PersonDetail` 引用。
- `git diff --check` 無 whitespace error。

### 12.2 Whole-module Typecheck

比照本次對話先前使用的 no-build typecheck 指令（見專案記憶「Simulator 驗證流程」），在新增檔案／改動 `APIConfig.swift`、`DetailRouter.swift`、`AppComposition.swift`、`MainSearchRouter.swift`、`PersonDetailCells.swift` 後執行一次，確認 0 errors／0 warnings。若 Xcode 版本已更新導致預編譯 `.swiftmodule` 失效，改用完整 `xcodebuild build`。

### 12.3 Runtime

Build 成功不代表功能完成。以下必須以 Simulator 實機操作驗證：

- 從 MainSearch 搜尋任一有結果的公司關鍵字（例如 `"Pixar"`），切到「製作公司」篩選，點擊結果，確認正確導頁到 `CompanyDetailViewController` 且顯示對應公司資料。
- 找一間 Logo 只有 SVG（例如 Lucasfilm）的公司，確認 Header 顯示 9.1 的預留樣式，而非空白或 App 崩潰。
- 深色模式下檢查 Logo 容器背景是否讓透明背景的深色 Logo 保持可視（9.1 的固定淺色底板）。
- 確認 `PersonDetail` 的「Also Known As」區塊在 `DetailPillListCollectionViewCell` 抽取後外觀與互動未變。
- 確認離線或 API 錯誤時，`.failed` 狀態的重試流程可用（比照既有詳情頁）。
- 分頁擴充項目見第 11.9 節。
- 從任一 MovieDetail 與 TVDetail 點擊出品公司 pill，確認 push 至 ID 對應的 `CompanyDetailViewController`；類型與 TV Network 標籤的既有互動維持不變。
- 點擊 CompanyDetail 的任一標誌，確認開啟 `CompanyLogoImagePreviewViewController`，列表縮圖與全螢幕圖片背景皆為 `.label`，Page Control、頁碼與關閉按鈕以 `.systemBackground` 保持可見，狀態列文字在白底上可辨識，並驗證分頁、縮放及關閉操作；其他功能的圖片預覽維持黑底白色控制元件。

---

## 13. 風險與處理

| 風險 | 影響 | 處理方式 |
|------|------|----------|
| 公司 Logo 多為 SVG，`SDWebImage` 無法渲染 | Header／Logos 區塊出現空白或破圖 | Data／Presentation 層一律過濾 `.svg`，Header 無點陣圖時顯示 `building.2.fill` 預留樣式（3.5、7.1、7.2、9.1） |
| 透明背景深色 Logo 在深色模式底色下不可視 | 使用者看不到公司識別 | Header Logo 容器固定使用淺色底板，不隨系統主題切換（9.1），需 Runtime 實機驗收 |
| `DetailPillListCollectionViewCell` 抽取影響既有 `PersonDetail` 畫面 | Person 詳情頁「Also Known As」外觀或互動退化 | 抽取時保持介面與視覺參數不變，只搬動實作位置；Runtime 驗收含 Person 畫面比對（12.3） |
| 幫 `DetailContentListConfiguration` 加分頁欄位會讓它失去 `Equatable`，波及 `PersonDetailCreditsListResult` 等既有型別 | `PersonDetail` 相關程式碼可能需要連鎖修改，風險外溢到與本次需求無關的檔案 | 分頁能力不放進 `DetailContentListConfiguration`，改成 Router／SceneBuilder／Controller 的獨立參數，`DetailContentListConfiguration` 本身完全不變（11.4） |
| `DetailContentListViewController` 從純靜態改成可分頁，可能連帶影響 `PersonDetail` 既有行為 | Person「查看更多」畫面出現非預期的載入或崩潰 | `pageProvider` 預設為 `nil`，`PersonDetail` 呼叫端不需要修改；Runtime 驗收明確包含 Person 迴歸測試（11.9） |
| 分頁狀態（目前第幾頁）在多次非同步呼叫之間需要保留 | 若用一般 class 處理可變狀態，Swift 6 strict concurrency 下容易被迫用 `@unchecked Sendable`，失去編譯器保護 | `CompanyDetailContentListPageProvider` 用 `actor` 實作，天生 `Sendable`、天生序列化，不使用並行安全豁免（11.7） |
| 使用者快速捲動可能短時間內觸發多次下一頁請求 | 重複請求、資料重複插入、UI 閃爍 | 重用既有 `MediaGridPaginationTaskController`／`isLoadingNextPage` 機制防止重疊呼叫，插入前用 `Set` 對已存在的 `id` 去重（11.5、11.10） |
| 下一頁請求失敗時使用者不知道還有沒有更多資料 | 使用者可能誤以為清單已經到底 | 第一版選擇「安靜失敗、`canLoadNextPage` 設為 `false`」，不新增重試 UI；已在 11.10 明確記錄為已知限制，非遺漏 |
| `origin_country` 是 ISO 代碼，直接顯示不友善 | Facts／Header metadata 顯示 `"US"` 而非「美國」 | 已確認 `BaseFormatter` 無地區名稱對照，改用 Foundation `Locale.localizedString(forRegionCode:)`，不新增自訂對照表（7.1） |
| 出品公司入口誤用名稱而非 TMDB ID 導頁 | 同名公司可能導向錯誤資料 | 沿用 `ProductionCompany.id` → attribute `sourceID` → Router `companyID` 的純 ID 資料流，不以顯示文字查詢 |
| 新增 `APIConfig.Company` 與既有字母序慣例不一致 | 之後盤點端點時難以維護 | 依現有 A-Z enum 排列慣例插入 `Collection` 與 `Configuration` 之間（6.1） |

---

## 14. 完成定義

只有同時滿足下列條件，功能才能標為完成：

- `APIConfig.Company` 三個端點與命名符合 6.1。
- `CompanyDetail` 模組五層（Domain／Data／Presentation／ViewModel／Controller）皆依本文件實作，Section Builder 的容錯（`optional(...)`）行為與 `PersonDetail`／`MovieDetail` 一致。
- SVG Logo 一律不嘗試顯示，Header 有預留樣式。
- `DetailPillListCollectionViewCell` 抽取後，`PersonDetail` 既有畫面行為與外觀不變。
- `MainSearchRouter` 的 `case .company` 導向新頁面，不再是 no-op。
- MovieDetail／TVDetail 的 `.productionCompany` attribute 導向相同 CompanyDetail；genre 與 TV network 行為不變。
- `DetailRouting`／`DetailSceneBuilding` 新增方法命名符合 `SDD-Unified-Interface-Naming.md`。
- 12.1 Source 檢查、12.2 Typecheck／Build 通過並獨立記錄結果。
- 12.3 Runtime 項目（含 SVG 公司、深色模式、Person 迴歸、電影／影集清單無限捲動分頁）以 Simulator 或實機驗證後才能標記 Passed。
- `project.pbxproj` 只新增本功能檔案的 target membership，其餘設定不變。
- 第 11 節的分頁擴充完成後，`DetailContentListConfiguration` 對既有呼叫端（`PersonDetail`）維持零異動、零新增警告。
- Company 的電影／影集查看更多清單可持續捲動載入下一頁，直到 TMDB `total_pages` 用盡為止；`PersonDetail` 的查看更多清單行為與外觀維持完全不變（`pageProvider` 為 `nil`）。
- `CompanyDetailContentListPageProvider` 以 `actor` 實作，whole-module typecheck 在 `-strict-concurrency=complete` 下無資料競爭相關警告或錯誤。

---

## 15. 實作狀態

截至 2026-09-26：

**基礎 `CompanyDetail` 模組（第 1–10 節，含電影／影集清單只顯示第一頁的「查看更多」）**

- Design：Ready。
- Source Implementation：Done（`CompanyDetail/` 五層、`DetailPillListCollectionViewCell` 抽取、`APIConfig.Company`、Router／SceneBuilder／MainSearchRouter 收尾皆已落地）。
- Static Verification：Passed（whole-module typecheck，Swift 6 strict concurrency，0 errors／0 warnings）。
- Xcode Build：Passed（`xcodebuild build` BUILD SUCCEEDED；以 `git stash` 比對修改前後，確認建置訊息中僅有的 2 個 linker warning 為既有、與本次改動無關，未新增警告）。
- Runtime／UI：Passed（2026-09-24，iPhone 17 / iOS 27.0 Simulator，經使用者授權存取）。實際操作：MainSearch 搜尋 "Marvel Studios" → 切到「製作公司」篩選 → 點擊結果，正確導頁到 `CompanyDetailViewController`，Header（白底 Logo、名稱、總部、所屬國家）、公司資訊 Facts、電影橫向清單、標誌（Logos，含尺寸文字）、別名 Pill 清單（韓／簡中／日三種別名同時正確顯示）、相關連結（官方網站）皆正確渲染；點擊電影橫向清單項目正確導頁到 `MovieDetailViewController`（復仇者聯盟：終局之戰）。`PersonDetail`（Agnez Mo）「電影作品」查看更多維持原本一次性靜態清單行為，無迴歸。

**第 11 節：內容清單無限捲動分頁擴充**

- Design：Ready。
- Source Implementation：Done（`DetailContentListPageProviding`／`DetailContentListPage`、`DetailContentListViewController` 分頁改動、`DetailRouting`／`DetailSceneBuilding`／`AppComposition` 簽章擴充、`CompanyDetailContentListPageProvider`、`CompanyDetailViewModel.contentList(companyID:mediaKind:)` 皆已落地）。
- Static Verification：Passed（whole-module typecheck，0 errors／0 warnings）。
- Xcode Build：Passed（`xcodebuild build` BUILD SUCCEEDED，僅有前述 2 個既有 linker warning，無新增警告）。實作過程中發現 `DetailContentListPageProviding` 不能宣告為 `nonisolated`（`actor` 遵循 `nonisolated` protocol會導致 `actor` initializer 隔離規則衝突），此問題只有完整 Build 才會出現、`swiftc -typecheck` 不會（見 11.3 附註），已修正並重新驗證兩者皆通過。
- Runtime／UI：Passed（2026-09-24，同一次 Simulator session）。點擊 Marvel Studios「電影」Section Header 進入 `DetailContentListViewController`，持續下拉捲動，清單從第一頁（首批約 20 筆：蜘蛛人、復仇者聯盟系列等）不間斷載入到後續頁面（含 Team Thor、Agent Carter 等 one-shot 短片），最終捲到 TMDB 資料庫盡頭（未上映的 Spider-Man 5、Untitled Deadpool/X-Men Teamup Film 等），清單自然停止成長、無重複項目、無崩潰、`canLoadNextPage` 正確落為 `false`；返回上一頁與整體 App 操作皆維持正常回應，未觀察到記憶體或效能異常。

**MovieDetail／TVDetail 出品公司入口（2026-09-25）**

- Source Implementation：Done（沿用既有 production company ID、attribute selection callback、`DetailRouter.showCompanyDetail` 與 `AppComposition.makeCompanyDetailViewController`）。
- Static Verification：Passed（Swift frontend parse、String Catalog JSON／compile、`project.pbxproj` lint、`git diff --check`）。
- Xcode Build：Not Run（本次為小範圍既有路由串接，依專案規範先採快速靜態檢查）。
- Runtime／UI：Not Run（尚未以 Simulator／實機點擊 MovieDetail 與 TVDetail 的出品公司 pill 驗證 push 與返回流程）。

**CompanyDetail 標誌專用預覽（2026-09-26）**

- Source Implementation：Done（`CompanyLogoImagePreviewViewController` 繼承共用圖片預覽，只覆寫 `.label` 背景；CompanyDetail Logos 由 Router 導向專用 VC）。
- Static Verification：Passed（Swift frontend parse、`project.pbxproj` lint／target membership、`git diff --check`）。
- Xcode Build：Not Run（依專案規範先執行快速靜態檢查）。
- Runtime／UI：Not Run（尚未以 Simulator／實機驗證 `.label` 動態色彩、透明 Logo、分頁與縮放效果）。

本文件建立不代表功能已實作。每個狀態只能在取得對應證據後更新。

---

## 16. 參考資料

- [TMDB API — Company Details](https://developer.themoviedb.org/reference/company-details)
- [TMDB API — Company Alternative Names](https://developer.themoviedb.org/reference/company-alternative-names)
- [TMDB API — Company Images](https://developer.themoviedb.org/reference/company-images)
- [TMDB API — Discover Movie](https://developer.themoviedb.org/reference/discover-movie)（`with_companies` 參數）
- [TMDB API — Discover TV](https://developer.themoviedb.org/reference/discover-tv)（`with_companies` 參數）
- `Docs/SDD-Clean-Architecture-Migration.md`
- `Docs/SDD-Unified-Interface-Naming.md`
- `Docs/SDD-Detail-Sharing.md`（Router／Scene Builder 擴充模式參考）
- `PersonDetail/`（本文件的主要結構範本）
