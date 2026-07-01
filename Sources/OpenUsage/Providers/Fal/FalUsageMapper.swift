import Foundation

enum FalUsageMapper {
    static func dataObject(_ body: Data) -> [String: Any]? {
        ProviderParse.jsonObject(body)
    }

    static func billingMetrics(from data: [String: Any]) -> [MetricLine] {
        var lines: [MetricLine] = []
        
        if let credits = data["credits"] as? [String: Any],
           let currentBalance = ProviderParse.number(credits["current_balance"]) {
            lines.append(.values(label: "Balance", values: [
                MetricValue(number: currentBalance, kind: .dollars)
            ]))
        } else if let balance = ProviderParse.number(data["current_balance"] ?? data["balance"]) {
            lines.append(.values(label: "Balance", values: [
                MetricValue(number: balance, kind: .dollars)
            ]))
        }
        
        return lines
    }
}
