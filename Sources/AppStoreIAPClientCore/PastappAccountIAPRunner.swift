import Foundation

public struct PastappAccountIAPRow: Hashable, Decodable, Sendable {
    public var productId: String
    public var productName: String
    public var purchaseKind: PurchaseKind
    public var period: String?
    public var price: Decimal?
    public var currencyCode: String
    public var message: String

    public init(
        productId: String,
        productName: String,
        purchaseKind: PurchaseKind,
        period: String?,
        price: Decimal?,
        currencyCode: String,
        message: String
    ) {
        self.productId = productId
        self.productName = productName
        self.purchaseKind = purchaseKind
        self.period = period
        self.price = price
        self.currencyCode = currencyCode
        self.message = message
    }

    private enum CodingKeys: String, CodingKey {
        case productId
        case productName
        case purchaseKind
        case period
        case price
        case currencyCode
        case message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productId = try container.decodeIfPresent(String.self, forKey: .productId) ?? ""
        productName = try container.decodeIfPresent(String.self, forKey: .productName) ?? ""
        let rawKind = try container.decodeIfPresent(String.self, forKey: .purchaseKind) ?? PurchaseKind.unknown.rawValue
        purchaseKind = PurchaseKind(rawValue: rawKind) ?? .unknown
        period = try container.decodeIfPresent(String.self, forKey: .period)
        if let rawPrice = try container.decodeIfPresent(String.self, forKey: .price),
           !rawPrice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            price = Decimal(string: rawPrice)
        } else {
            price = nil
        }
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? ""
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
    }
}

public struct PastappAccountIAPResult: Hashable, Decodable, Sendable {
    public var ok: Bool
    public var appId: String
    public var appName: String
    public var storefront: String
    public var countryCode: String
    public var currencyCode: String
    public var rows: [PastappAccountIAPRow]
    public var message: String

    public init(
        ok: Bool,
        appId: String,
        appName: String,
        storefront: String,
        countryCode: String,
        currencyCode: String,
        rows: [PastappAccountIAPRow],
        message: String
    ) {
        self.ok = ok
        self.appId = appId
        self.appName = appName
        self.storefront = storefront
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.rows = rows
        self.message = message
    }
}

public enum PastappAccountIAPLineParser {
    public static func parse(_ line: String) throws -> PastappAccountIAPResult? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "{", trimmed.last == "}" else {
            return nil
        }
        return try? JSONDecoder().decode(PastappAccountIAPResult.self, from: Data(trimmed.utf8))
    }
}

public struct PastappAccountIAPCommand: Hashable, Sendable {
    public var nodeExecutable: URL
    public var mainScript: URL
    public var sessionsDirectory: URL
    public var appleAccount: String
    public var appId: String
    public var countryCode: String
    public var languageCode: String

    public init(
        nodeExecutable: URL,
        mainScript: URL,
        sessionsDirectory: URL,
        appleAccount: String,
        appId: String,
        countryCode: String,
        languageCode: String
    ) {
        self.nodeExecutable = nodeExecutable
        self.mainScript = mainScript
        self.sessionsDirectory = sessionsDirectory
        self.appleAccount = appleAccount
        self.appId = appId
        self.countryCode = countryCode
        self.languageCode = languageCode
    }

    public var arguments: [String] {
        [
            mainScript.path,
            "account-iap",
            "--id", appId,
            "--email", appleAccount,
            "--country", countryCode.lowercased(),
            "--json-events"
        ]
    }

    public var environment: [String: String] {
        var values = ProcessInfo.processInfo.environment
        values["IPA_SESSION_DIR"] = sessionsDirectory.path
        values["IPA_LANG"] = languageCode
        values["IPA_APP_COUNTRY"] = countryCode.lowercased()
        return values
    }
}

public struct PastappAccountIAPRunner: Sendable {
    public enum RunnerError: Error, CustomStringConvertible, LocalizedError, Equatable {
        case missingResult
        case failed(exitCode: Int32, stderr: String)

        public var description: String {
            switch self {
            case .missingResult:
                return "Pastapp helper did not return account in-app purchase metadata."
            case let .failed(exitCode, stderr):
                return "Pastapp helper exited with code \(exitCode): \(stderr)"
            }
        }

        public var errorDescription: String? { description }
    }

    public init() {}

    public func run(_ command: PastappAccountIAPCommand) throws -> PastappAccountIAPResult {
        let process = Process()
        process.executableURL = command.nodeExecutable
        process.arguments = command.arguments
        process.environment = command.environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        var result: PastappAccountIAPResult?

        for line in output.split(whereSeparator: \.isNewline).map(String.init) {
            if let parsed = try PastappAccountIAPLineParser.parse(line) {
                result = parsed
            }
        }

        guard process.terminationStatus == 0 else {
            throw RunnerError.failed(exitCode: process.terminationStatus, stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        guard let result else {
            throw RunnerError.missingResult
        }
        return result
    }
}
