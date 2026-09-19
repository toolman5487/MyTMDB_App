//
//  NetworkError+ErrorMessage.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - NetworkError ErrorMessageConvertible

extension NetworkError: ErrorMessageConvertible {

    func errorMessage(localization: AppInterfaceLocalization) -> ErrorMessage {
        switch self {
        case .invalidURL:
            return Self.makeMessage(
                titleKey: "network_error.invalid_url.title",
                title: "Unable to Create Request",
                messageKey: "network_error.invalid_url.message",
                message: "The URL is invalid. Please try again later.",
                localization: localization
            )

        case .invalidResponse:
            return Self.makeMessage(
                titleKey: "network_error.invalid_response.title",
                title: "Unexpected Server Response",
                messageKey: "network_error.invalid_response.message",
                message: "The server response could not be verified. Please try again later.",
                localization: localization
            )

        case .requestFailed(let code):
            return Self.urlErrorMessage(for: code, localization: localization)

        case .encodingFailed:
            return Self.makeMessage(
                titleKey: "network_error.encoding_failed.title",
                title: "Invalid Request Data",
                messageKey: "network_error.encoding_failed.message",
                message: "The submitted data could not be processed. Please try again later.",
                localization: localization
            )

        case .httpError(let statusCode):
            return Self.httpErrorMessage(for: statusCode, localization: localization)

        case .apiError(let statusCode, let apiCode, let message):
            let fallback = Self.httpErrorMessage(
                for: statusCode,
                localization: localization
            )
            return ErrorMessage(
                title: fallback.title,
                message: message.isEmpty
                    ? fallback.message
                    : Self.apiErrorMessage(
                        apiCode: apiCode,
                        message: message,
                        localization: localization
                    ),
                systemImageName: fallback.systemImageName,
                actionTitle: fallback.actionTitle
            )

        case .decodingFailed:
            return Self.makeMessage(
                titleKey: "network_error.decoding_failed.title",
                title: "Unable to Read Data",
                messageKey: "network_error.decoding_failed.message",
                message: "The server data does not match the format expected by the app. Please try again later.",
                localization: localization
            )
        }
    }

    private static func httpErrorMessage(
        for statusCode: Int,
        localization: AppInterfaceLocalization
    ) -> ErrorMessage {
        switch statusCode {
        case 401:
            return makeMessage(
                titleKey: "network_error.unauthorized.title",
                title: "Sign-in Expired",
                messageKey: "network_error.unauthorized.message",
                message: "Sign in again and retry.",
                systemImageName: "person.crop.circle.badge.exclamationmark",
                localization: localization
            )

        case 403:
            return makeMessage(
                titleKey: "network_error.forbidden.title",
                title: "Permission Denied",
                messageKey: "network_error.forbidden.message",
                message: "This account does not have permission to perform this action.",
                systemImageName: "lock",
                includesRetry: false,
                localization: localization
            )

        case 404:
            return makeMessage(
                titleKey: "network_error.not_found.title",
                title: "Content Not Found",
                messageKey: "network_error.not_found.message",
                message: "This content may no longer exist or may be temporarily unavailable.",
                systemImageName: "questionmark.folder",
                localization: localization
            )

        case 408:
            return makeMessage(
                titleKey: "network_error.timeout.title",
                title: "Connection Timed Out",
                messageKey: "network_error.server_timeout.message",
                message: "The server took too long to respond. Please try again later.",
                systemImageName: "clock.badge.exclamationmark",
                localization: localization
            )

        case 429:
            return makeMessage(
                titleKey: "network_error.rate_limit.title",
                title: "Too Many Requests",
                messageKey: "network_error.rate_limit.message",
                message: "Too many requests were made. Please try again later.",
                systemImageName: "hourglass",
                localization: localization
            )

        case 500...599:
            return makeMessage(
                titleKey: "network_error.server_unavailable.title",
                title: "Server Temporarily Unavailable",
                messageKey: "network_error.server_unavailable.message",
                message: "The service is currently unstable. Please try again later.",
                systemImageName: "externaldrive.badge.exclamationmark",
                localization: localization
            )

        default:
            return ErrorMessage(
                title: localization.string(
                    "network_error.http.title",
                    defaultValue: "Connection Error"
                ),
                message: localization.formatted(
                    "network_error.http.message_format",
                    defaultValue: "HTTP error (%lld). Please try again later.",
                    statusCode
                ),
                actionTitle: retryTitle(localization: localization)
            )
        }
    }

    private static func urlErrorMessage(
        for code: URLError.Code,
        localization: AppInterfaceLocalization
    ) -> ErrorMessage {
        switch code {
        case .notConnectedToInternet:
            return makeMessage(
                titleKey: "network_error.offline.title",
                title: "No Internet Connection",
                messageKey: "network_error.offline.message",
                message: "Check your internet connection and try again.",
                systemImageName: "wifi.exclamationmark",
                localization: localization
            )

        case .timedOut:
            return makeMessage(
                titleKey: "network_error.timeout.title",
                title: "Connection Timed Out",
                messageKey: "network_error.connection_timeout.message",
                message: "The network took too long to respond. Please try again later.",
                systemImageName: "clock.badge.exclamationmark",
                localization: localization
            )

        case .cancelled:
            return makeMessage(
                titleKey: "network_error.cancelled.title",
                title: "Request Cancelled",
                messageKey: "network_error.cancelled.message",
                message: "The operation was cancelled.",
                systemImageName: "xmark.circle",
                includesRetry: false,
                localization: localization
            )

        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return makeMessage(
                titleKey: "network_error.host_unavailable.title",
                title: "Unable to Reach Server",
                messageKey: "network_error.host_unavailable.message",
                message: "The service host could not be reached. Please try again later.",
                systemImageName: "network.slash",
                localization: localization
            )

        case .networkConnectionLost:
            return makeMessage(
                titleKey: "network_error.connection_lost.title",
                title: "Connection Lost",
                messageKey: "network_error.connection_lost.message",
                message: "Check that your connection is stable and try again.",
                systemImageName: "wifi.slash",
                localization: localization
            )

        case .secureConnectionFailed,
                .serverCertificateHasBadDate,
                .serverCertificateUntrusted,
                .serverCertificateHasUnknownRoot,
                .serverCertificateNotYetValid,
                .clientCertificateRejected,
                .clientCertificateRequired,
                .appTransportSecurityRequiresSecureConnection:
            return makeMessage(
                titleKey: "network_error.secure_connection.title",
                title: "Secure Connection Failed",
                messageKey: "network_error.secure_connection.message",
                message: "A secure connection could not be established. Please try again later.",
                systemImageName: "lock.trianglebadge.exclamationmark",
                localization: localization
            )

        default:
            return makeMessage(
                titleKey: "network_error.generic.title",
                title: "Connection Failed",
                messageKey: "network_error.generic.message",
                message: "The network request failed. Please try again later.",
                localization: localization
            )
        }
    }

    private static func makeMessage(
        titleKey: StaticString,
        title: String,
        messageKey: StaticString,
        message: String,
        systemImageName: String = "exclamationmark.triangle",
        includesRetry: Bool = true,
        localization: AppInterfaceLocalization
    ) -> ErrorMessage {
        ErrorMessage(
            title: localization.string(titleKey, defaultValue: title),
            message: localization.string(messageKey, defaultValue: message),
            systemImageName: systemImageName,
            actionTitle: includesRetry ? retryTitle(localization: localization) : nil
        )
    }

    private static func apiErrorMessage(
        apiCode: Int?,
        message: String,
        localization: AppInterfaceLocalization
    ) -> String {
        guard let apiCode else {
            return localization.formatted(
                "network_error.api.message_format",
                defaultValue: "The service returned an error: %@",
                message
            )
        }

        return localization.formatted(
            "network_error.api.message_with_code_format",
            defaultValue: "The service returned an error (%1$lld): %2$@",
            apiCode,
            message
        )
    }

    private static func retryTitle(
        localization: AppInterfaceLocalization
    ) -> String {
        localization.string("common.action.retry", defaultValue: "Retry")
    }
}
