import Foundation

enum HiggsfieldUsageMapper {
    static func dataObject(_ body: Data) -> [String: Any]? {
        ProviderParse.jsonObject(body)
    }

    static func balanceMetrics(from data: [String: Any]) -> [MetricLine] {
        var lines: [MetricLine] = []
        
        if let balance = ProviderParse.number(data["balance"] ?? data["credit_balance"] ?? data["credits"] ?? data["available"]) {
            lines.append(.values(label: "Balance", values: [
                MetricValue(amount: balance, kind: .dollars)
            ]))
        }
        
        return lines
    }
}
