import Foundation
import AppStoreIAPClientCore

let arguments = Array(CommandLine.arguments.dropFirst())
let countries = ["US", "CN", "JP", "GB"]
let client = AppStorePublicClient()

func runLookups(app: AppSearchResult) async throws {
    var rows: [PriceResultRow] = []
    for country in countries {
        guard let storefront = CountryStorefrontCatalog.all.first(where: { $0.countryCode == country }) else {
            print("SMOKE_FAIL: missing storefront \(country)")
            exit(1)
        }

        do {
            if let lookup = try await client.lookup(appId: app.appId, countryCode: country) {
                let l10n = L10n(preferredLanguages: ["en-US"])
                let baseMessage = l10n.publicMissingMessage(connectConfigured: false)
                let message = lookup.name == app.name ? baseMessage : "\(baseMessage) \(l10n.storefrontLocalizedNameNote(lookup.name))"
                let row = PriceNormalizer.missingPublicRow(
                    app: app,
                    storefront: storefront,
                    message: message
                )
                rows.append(row)
                print("LOOKUP_OK: \(country) product=\(row.productName) storefrontName=\(lookup.name) status=\(row.status.rawValue)")
            } else {
                let row = PriceNormalizer.unavailableRow(
                    app: app,
                    storefront: storefront,
                    message: L10n(preferredLanguages: ["en-US"]).appNotFoundInStorefront
                )
                rows.append(row)
                print("LOOKUP_MISSING: \(country) status=\(row.status.rawValue)")
            }
        } catch {
            let row = PriceNormalizer.failureRow(appName: app.name, storefront: storefront, message: error.localizedDescription)
            rows.append(row)
            print("LOOKUP_FAIL: \(country) \(error.localizedDescription)")
        }
    }

    let failureCount = rows.filter { $0.status == .requestFailed }.count
    if failureCount == countries.count {
        print("SMOKE_FAIL: all storefront lookups failed")
        exit(1)
    }

    print("SMOKE_PASS: rows=\(rows.count) failures=\(failureCount)")
}

do {
    if arguments.first == "--url", let url = arguments.dropFirst().first {
        guard let appID = AppIDParser.extractAppID(from: url) else {
            print("SMOKE_FAIL: URL missing App ID")
            exit(1)
        }
        let country = AppIDParser.extractCountryCode(from: url) ?? "US"
        print("Direct URL lookup appId: \(appID) country: \(country)")
        guard let app = try await client.lookup(appId: appID, countryCode: country) else {
            print("SMOKE_FAIL: no app found for direct URL")
            exit(1)
        }
        print("Selected app: \(app.name) | developer: \(app.developerName) | appId: \(app.appId)")
        try await runLookups(app: app)
        exit(0)
    }

    let term = arguments.first ?? "ChatGPT"
    let searchCountry = arguments.dropFirst().first ?? "US"
    print("Searching term: \(term) country: \(searchCountry)")
    let results = try await client.search(term: term, countryCode: searchCountry)
    guard let app = results.first else {
        print("SMOKE_FAIL: no app found")
        exit(1)
    }

    print("Selected app: \(app.name) | developer: \(app.developerName) | appId: \(app.appId)")
    try await runLookups(app: app)
} catch {
    print("SMOKE_FAIL: \(error.localizedDescription)")
    exit(1)
}
