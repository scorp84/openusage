import Foundation

struct HiggsfieldUsageClient: Sendable {
    static let balanceURL = "https://cloud.higgsfield.ai/api/v1/account/balance"
    
    var http: any HTTPClient
    
    init(http: any HTTPClient = URLSessionHTTPClient()) {
        self.http = http
    }
    
    func fetchBalance(apiKey: String) async throws -> HTTPResponse {
        guard let url = URL(string: Self.balanceURL) else {
            throw HiggsfieldUsageError.invalidResponse
        }
        
        return try await http.send(HTTPRequest(
            method: "GET",
            url: url,
            headers: [
                "Authorization": "Bearer \(apiKey)",
                "Accept": "application/json"
            ],
            timeout: 15
        ))
    }
}

enum HiggsfieldUsageError: Error, LocalizedError, Equatable {
    case connectionFailed
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Couldn't reach Higgsfield.ai. Check your connection."
        case .invalidResponse:
            return "Higgsfield.ai usage data unavailable. Try again later."
        case .requestFailed(let status):
            return "Higgsfield.ai request failed (HTTP \(status))."
        }
    }
}
