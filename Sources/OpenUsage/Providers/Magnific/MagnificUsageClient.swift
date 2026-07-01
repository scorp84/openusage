import Foundation

struct MagnificUsageClient: Sendable {
    static let analyticsURL = "https://api.magnific.com/v1/analytics/team-credit-usage"
    
    var http: any HTTPClient
    
    init(http: any HTTPClient = URLSessionHTTPClient()) {
        self.http = http
    }
    
    func fetchTeamCreditUsage(apiKey: String) async throws -> HTTPResponse {
        guard let url = URL(string: Self.analyticsURL) else {
            throw MagnificUsageError.invalidResponse
        }
        
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let startDate = dateFormatter.string(from: thirtyDaysAgo)
        let endDate = dateFormatter.string(from: now)
        
        let body: [String: Any] = [
            "granularity": "day",
            "start_date": startDate,
            "end_date": endDate
        ]
        
        let payload = try? JSONSerialization.data(withJSONObject: body)
        
        return try await http.send(HTTPRequest(
            method: "POST",
            url: url,
            headers: [
                "X-Magnific-API-Key": apiKey,
                "Content-Type": "application/json",
                "Accept": "application/json"
            ],
            body: payload,
            timeout: 15
        ))
    }
}

enum MagnificUsageError: Error, LocalizedError, Equatable {
    case connectionFailed
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Couldn't reach Magnific. Check your connection."
        case .invalidResponse:
            return "Magnific usage data unavailable. Try again later."
        case .requestFailed(let status):
            return "Magnific request failed (HTTP \(status))."
        }
    }
}
