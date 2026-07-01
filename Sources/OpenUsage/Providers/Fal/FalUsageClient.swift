import Foundation

struct FalUsageClient: Sendable {
    static let billingURL = "https://api.fal.ai/v1/account/billing"
    
    var http: any HTTPClient
    
    init(http: any HTTPClient = URLSessionHTTPClient()) {
        self.http = http
    }
    
    func fetchBilling(apiKey: String) async throws -> HTTPResponse {
        guard let url = URL(string: Self.billingURL) else {
            throw FalUsageError.invalidResponse
        }
        
        return try await http.send(HTTPRequest(
            method: "GET",
            url: url,
            headers: [
                "Authorization": "Key \(apiKey)",
                "Accept": "application/json"
            ],
            timeout: 15
        ))
    }
}

enum FalUsageError: Error, LocalizedError, Equatable {
    case connectionFailed
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Couldn't reach Fal.ai. Check your connection."
        case .invalidResponse:
            return "Fal.ai usage data unavailable. Try again later."
        case .requestFailed(let status):
            return "Fal.ai request failed (HTTP \(status))."
        }
    }
}
