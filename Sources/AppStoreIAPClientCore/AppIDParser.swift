import Foundation

public enum AppIDParser {
    public static func extractAppID(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.range(of: #"^\d+$"#, options: .regularExpression) != nil {
            return trimmed
        }

        guard let match = trimmed.range(of: #"id(\d+)"#, options: .regularExpression) else {
            return nil
        }

        return String(trimmed[match]).dropFirst(2).description
    }

    public static func extractCountryCode(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            return nil
        }

        let pathParts = url.pathComponents.filter { $0 != "/" }
        guard pathParts.count >= 2, pathParts[1] == "app" else {
            return nil
        }

        let country = pathParts[0].uppercased()
        guard country.count == 2 else {
            return nil
        }

        return country
    }
}
