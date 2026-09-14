//
//  NetworkError+ErrorMessage.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - NetworkError ErrorMessageConvertible

extension NetworkError: ErrorMessageConvertible {

    var errorMessage: ErrorMessage {
        switch self {
        case .invalidURL:
            return ErrorMessage(
                title: "無法建立請求",
                message: "網址格式錯誤，請稍後再試。",
                actionTitle: "重試"
            )

        case .invalidResponse:
            return ErrorMessage(
                title: "伺服器回應異常",
                message: "目前無法確認伺服器回應，請稍後再試。",
                actionTitle: "重試"
            )

        case .requestFailed(let code):
            return code.errorMessage

        case .encodingFailed:
            return ErrorMessage(
                title: "請求資料錯誤",
                message: "送出的資料無法處理，請稍後再試。",
                actionTitle: "重試"
            )

        case .httpError(let statusCode):
            return NetworkError.errorMessage(for: statusCode)

        case .apiError(let statusCode, let apiCode, let message):
            let errorMessage = NetworkError.errorMessage(for: statusCode)
            let apiCodeText = apiCode.map { "（\($0)）" } ?? ""
            return ErrorMessage(
                title: errorMessage.title,
                message: message.isEmpty ? errorMessage.message : "服務回傳錯誤\(apiCodeText)：\(message)",
                systemImageName: errorMessage.systemImageName,
                actionTitle: errorMessage.actionTitle
            )

        case .decodingFailed:
            return ErrorMessage(
                title: "資料解析失敗",
                message: "伺服器資料格式和 App 預期不一致，請稍後再試。",
                actionTitle: "重試"
            )
        }
    }

    private static func errorMessage(for statusCode: Int) -> ErrorMessage {
        switch statusCode {
        case 401:
            return ErrorMessage(
                title: "登入已失效",
                message: "請重新登入後再試。",
                systemImageName: "person.crop.circle.badge.exclamationmark",
                actionTitle: "重試"
            )

        case 403:
            return ErrorMessage(
                title: "沒有權限",
                message: "目前帳號沒有執行此操作的權限。",
                systemImageName: "lock",
                actionTitle: nil
            )

        case 404:
            return ErrorMessage(
                title: "找不到資料",
                message: "這筆資料可能已不存在或暫時無法取得。",
                systemImageName: "questionmark.folder",
                actionTitle: "重試"
            )

        case 408:
            return ErrorMessage(
                title: "連線逾時",
                message: "伺服器回應時間過長，請稍後再試。",
                systemImageName: "clock.badge.exclamationmark",
                actionTitle: "重試"
            )

        case 429:
            return ErrorMessage(
                title: "請求過於頻繁",
                message: "目前請求次數過多，請稍後再試。",
                systemImageName: "hourglass",
                actionTitle: "重試"
            )

        case 500...599:
            return ErrorMessage(
                title: "伺服器暫時無法回應",
                message: "服務目前不穩定，請稍後再試。",
                systemImageName: "externaldrive.badge.exclamationmark",
                actionTitle: "重試"
            )

        default:
            return ErrorMessage(
                title: "連線發生錯誤",
                message: "HTTP 錯誤（\(statusCode)），請稍後再試。",
                actionTitle: "重試"
            )
        }
    }
}

// MARK: - URLError Presentation

private extension URLError.Code {

    var errorMessage: ErrorMessage {
        switch self {
        case .notConnectedToInternet:
            return ErrorMessage(
                title: "沒有網路連線",
                message: "請檢查網路連線後再試。",
                systemImageName: "wifi.exclamationmark",
                actionTitle: "重試"
            )

        case .timedOut:
            return ErrorMessage(
                title: "連線逾時",
                message: "網路回應時間過長，請稍後再試。",
                systemImageName: "clock.badge.exclamationmark",
                actionTitle: "重試"
            )

        case .cancelled:
            return ErrorMessage(
                title: "請求已取消",
                message: "操作已取消。",
                systemImageName: "xmark.circle",
                actionTitle: nil
            )

        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return ErrorMessage(
                title: "無法連線到伺服器",
                message: "目前找不到服務主機，請稍後再試。",
                systemImageName: "network.slash",
                actionTitle: "重試"
            )

        case .networkConnectionLost:
            return ErrorMessage(
                title: "網路連線中斷",
                message: "請確認連線穩定後再試。",
                systemImageName: "wifi.slash",
                actionTitle: "重試"
            )

        case .secureConnectionFailed,
                .serverCertificateHasBadDate,
                .serverCertificateUntrusted,
                .serverCertificateHasUnknownRoot,
                .serverCertificateNotYetValid,
                .clientCertificateRejected,
                .clientCertificateRequired,
                .appTransportSecurityRequiresSecureConnection:
            return ErrorMessage(
                title: "安全連線失敗",
                message: "無法建立安全連線，請稍後再試。",
                systemImageName: "lock.trianglebadge.exclamationmark",
                actionTitle: "重試"
            )

        default:
            return ErrorMessage(
                title: "連線失敗",
                message: "網路請求失敗，請稍後再試。",
                actionTitle: "重試"
            )
        }
    }
}
