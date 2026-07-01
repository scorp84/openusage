import Foundation

enum MagnificUsageMapper {
    static func dataObject(_ body: Data) -> [String: Any]? {
        ProviderParse.jsonObject(body)
    }

    static func usageMetrics(from data: [String: Any]) -> [MetricLine] {
        var lines: [MetricLine] = []
        
        // Response shape depends on their API, usually it has "total_credits_used", "total_consumed", or just "total"
        if let totalUsed = ProviderParse.number(data["total_credits_used"] ?? data["credits_consumed"] ?? data["total"] ?? data["consumed"]) {
            lines.append(.values(label: "Used (30d)", values: [
                MetricValue(number: totalUsed, kind: .count(suffix: " credits"))
            ]))
        } else if let usageArray = data["usage"] as? [[String: Any]], !usageArray.isEmpty {
            var sum: Double = 0
            for item in usageArray {
                if let consumed = ProviderParse.number(item["credits_consumed"] ?? item["used"]) {
                    sum += consumed
                }
            }
            lines.append(.values(label: "Used (30d)", values: [
                MetricValue(number: sum, kind: .count(suffix: " credits"))
            ]))
        }
        
        return lines
    }
}
