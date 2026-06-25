import Foundation
import AppStoreIAPClientCore

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
    if actual != expected {
        throw TestFailure(description: "\(message). Expected \(expected), got \(actual).")
    }
}

func assertTrue(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw TestFailure(description: message)
    }
}

func assertNil<T>(_ value: T?, _ message: String) throws {
    if value != nil {
        throw TestFailure(description: message)
    }
}

let tests: [(String, () throws -> Void)] = [
    ("AppIDParser extracts numeric ID", {
        try assertEqual(AppIDParser.extractAppID(from: "1234567890"), "1234567890", "Numeric ID should parse")
    }),
    ("AppIDParser extracts ID from storefront URL", {
        try assertEqual(
            AppIDParser.extractAppID(from: "https://apps.apple.com/us/app/example/id1234567890"),
            "1234567890",
            "Storefront URL should parse"
        )
    }),
    ("AppIDParser extracts ID from query URL", {
        try assertEqual(
            AppIDParser.extractAppID(from: "https://apps.apple.com/app/id987654321?mt=8"),
            "987654321",
            "Query URL should parse"
        )
    }),
    ("AppIDParser rejects missing ID", {
        try assertNil(AppIDParser.extractAppID(from: "https://apps.apple.com/us/app/example"), "URL without ID should not parse")
    }),
    ("AppIDParser extracts storefront country from URL", {
        try assertEqual(AppIDParser.extractCountryCode(from: "https://apps.apple.com/cn/app/example/id1234567890"), "CN", "CN storefront should parse")
        try assertEqual(AppIDParser.extractCountryCode(from: "https://apps.apple.com/jp/app/example/id1234567890"), "JP", "JP storefront should parse")
    }),
    ("AppIDParser returns nil country for plain IDs", {
        try assertNil(AppIDParser.extractCountryCode(from: "1234567890"), "Plain ID should not include country")
    }),
    ("CountryStorefrontCatalog contains major storefronts", {
        let codes = Set(CountryStorefrontCatalog.all.map(\.countryCode))
        try assertTrue(codes.contains("US"), "Catalog should include United States")
        try assertTrue(codes.contains("CN"), "Catalog should include China Mainland")
        try assertTrue(codes.contains("JP"), "Catalog should include Japan")
        try assertTrue(codes.contains("GB"), "Catalog should include United Kingdom")
    }),
    ("CountryStorefrontCatalog countries have currency codes", {
        try assertTrue(!CountryStorefrontCatalog.all.isEmpty, "Catalog should not be empty")
        try assertTrue(CountryStorefrontCatalog.all.allSatisfy { !$0.currencyCode.isEmpty }, "Every storefront needs a currency")
    }),
    ("PriceNormalizer marks missing public rows as not public", {
        let app = AppSearchResult(appId: "123", name: "Example", developerName: "Dev", bundleId: nil, primaryGenre: nil, sourceCountry: "US")
        let storefront = Storefront(countryCode: "US", displayName: "United States", currencyCode: "USD", storefrontIdentifier: nil)
        let row = PriceNormalizer.missingPublicRow(app: app, storefront: storefront, message: "No public IAP prices found")

        try assertEqual(row.countryCode, "US", "Country should match")
        try assertEqual(row.productName, "Example", "Product name should use app name")
        try assertEqual(row.source, .publicStorefront, "Source should be public storefront")
        try assertEqual(row.status, .notPublic, "Status should be not public")
        try assertTrue(row.price == nil, "Missing row should not include a price")
    }),
    ("PriceNormalizer marks failure rows as request failed", {
        let storefront = Storefront(countryCode: "JP", displayName: "Japan", currencyCode: "JPY", storefrontIdentifier: nil)
        let row = PriceNormalizer.failureRow(appName: "Example", storefront: storefront, message: "Timed out")

        try assertEqual(row.status, .requestFailed, "Failure row should have request failed status")
        try assertEqual(row.message, "Timed out", "Failure row should keep message")
    }),
    ("AppStoreConnectClient reports credential configuration", {
        let empty = AppStoreConnectClient()
        try assertTrue(!empty.isConfigured(), "Empty Connect client should not be configured")

        let configured = AppStoreConnectClient(
            credentials: AppStoreConnectCredentials(
                issuerID: "issuer",
                keyID: "key",
                privateKeyPath: "/tmp/AuthKey.p8"
            )
        )
        try assertTrue(configured.isConfigured(), "Connect client with credentials should be configured")
    }),
    ("ExportService CSV contains header and row", {
        let row = PriceResultRow(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            countryCode: "US",
            countryName: "United States",
            currencyCode: "USD",
            productId: "123",
            productName: "Example",
            purchaseKind: .unknown,
            period: nil,
            price: nil,
            source: .publicStorefront,
            status: .notPublic,
            message: "No public price",
            updatedAt: Date(timeIntervalSince1970: 0)
        )
        let csv = ExportService.csv(rows: [row])
        try assertTrue(csv.contains("countryCode,countryName,currencyCode,productId,productName,purchaseKind,period,price,source,status,message,updatedAt"), "CSV should contain stable header")
        try assertTrue(csv.contains("US,United States,USD,123,Example,Unknown,,"), "CSV should contain row values")
    }),
    ("ExportService JSON encodes rows", {
        let data = try ExportService.jsonData(rows: [])
        try assertTrue(!data.isEmpty, "JSON export should produce data")
    }),
    ("L10n follows Simplified Chinese system language", {
        let l10n = L10n(preferredLanguages: ["zh-Hans-CN", "en-US"])
        try assertEqual(l10n.language, .simplifiedChinese, "zh-Hans should choose Simplified Chinese")
        try assertEqual(l10n.searchTitle, "搜索", "Search title should be Chinese")
    }),
    ("L10n falls back to English for unsupported languages", {
        let l10n = L10n(preferredLanguages: ["fr-FR"])
        try assertEqual(l10n.language, .english, "Unsupported language should choose English")
        try assertEqual(l10n.searchTitle, "Search", "Search title should be English")
    }),
    ("L10n localizes price status and source display names", {
        let l10n = L10n(preferredLanguages: ["zh-Hans-CN"])
        try assertEqual(l10n.displayName(for: PriceStatus.notPublic), "未公开", "Not public status should be Chinese")
        try assertEqual(l10n.displayName(for: PriceStatus.notAvailableInStorefront), "不可用", "Unavailable status should be Chinese")
        try assertEqual(l10n.displayName(for: PriceSource.publicStorefront), "公开商店", "Public source should be Chinese")
    }),
    ("L10n localizes control-adjacent save panel file name", {
        let l10n = L10n(preferredLanguages: ["zh-Hans-CN"])
        try assertEqual(l10n.exportBaseFileName, "AppStore内购价格", "Save panel base file name should be Chinese")
    })
]

var failures = 0
for (name, test) in tests {
    do {
        try test()
        print("PASS: \(name)")
    } catch {
        failures += 1
        print("FAIL: \(name): \(error)")
    }
}

if failures > 0 {
    exit(1)
}

print("All \(tests.count) tests passed.")
