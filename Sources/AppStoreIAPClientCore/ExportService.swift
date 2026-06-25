import Foundation

public enum ExportService {
    public static func csv(rows: [PriceResultRow]) -> String {
        let header = "countryCode,countryName,currencyCode,productId,productName,purchaseKind,period,price,source,status,message,updatedAt"
        let formatter = ISO8601DateFormatter()
        let body = rows.map { row in
            [
                row.countryCode,
                row.countryName,
                row.currencyCode,
                row.productId,
                row.productName,
                row.purchaseKind.rawValue,
                row.period ?? "",
                row.price.map { NSDecimalNumber(decimal: $0).stringValue } ?? "",
                row.source.rawValue,
                row.status.rawValue,
                row.message,
                formatter.string(from: row.updatedAt)
            ].map(escapeCSV).joined(separator: ",")
        }
        return ([header] + body).joined(separator: "\n")
    }

    public static func jsonData(rows: [PriceResultRow]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(rows)
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
