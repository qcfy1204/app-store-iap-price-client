import Foundation

public struct AppSearchResult: Identifiable, Hashable, Codable, Sendable {
    public let appId: String
    public let name: String
    public let developerName: String
    public let bundleId: String?
    public let primaryGenre: String?
    public let sourceCountry: String

    public var id: String { appId }

    public init(
        appId: String,
        name: String,
        developerName: String,
        bundleId: String?,
        primaryGenre: String?,
        sourceCountry: String
    ) {
        self.appId = appId
        self.name = name
        self.developerName = developerName
        self.bundleId = bundleId
        self.primaryGenre = primaryGenre
        self.sourceCountry = sourceCountry
    }
}

public struct Storefront: Identifiable, Hashable, Codable, Sendable {
    public let countryCode: String
    public let displayName: String
    public let currencyCode: String
    public let storefrontIdentifier: String?

    public var id: String { countryCode }

    public init(countryCode: String, displayName: String, currencyCode: String, storefrontIdentifier: String?) {
        self.countryCode = countryCode
        self.displayName = displayName
        self.currencyCode = currencyCode
        self.storefrontIdentifier = storefrontIdentifier
    }
}

public enum PriceSource: String, Codable, CaseIterable, Sendable {
    case publicStorefront = "Public Storefront"
    case appStoreConnect = "App Store Connect"
}

public enum PriceStatus: String, Codable, CaseIterable, Sendable {
    case available = "Available"
    case notPublic = "Not Public"
    case notAvailableInStorefront = "Not Available"
    case requestFailed = "Request Failed"
    case connectUnauthorized = "Connect Unauthorized"
}

public enum PurchaseKind: String, Codable, CaseIterable, Sendable {
    case consumable = "Consumable"
    case nonConsumable = "Non-Consumable"
    case subscription = "Subscription"
    case unknown = "Unknown"
}

public struct PriceResultRow: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let countryCode: String
    public let countryName: String
    public let currencyCode: String
    public let productId: String
    public let productName: String
    public let purchaseKind: PurchaseKind
    public let period: String?
    public let price: Decimal?
    public let source: PriceSource
    public let status: PriceStatus
    public let message: String
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        countryCode: String,
        countryName: String,
        currencyCode: String,
        productId: String,
        productName: String,
        purchaseKind: PurchaseKind,
        period: String?,
        price: Decimal?,
        source: PriceSource,
        status: PriceStatus,
        message: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.countryCode = countryCode
        self.countryName = countryName
        self.currencyCode = currencyCode
        self.productId = productId
        self.productName = productName
        self.purchaseKind = purchaseKind
        self.period = period
        self.price = price
        self.source = source
        self.status = status
        self.message = message
        self.updatedAt = updatedAt
    }
}

public struct QuerySummary: Equatable, Sendable {
    public var totalCountries: Int
    public var completedCountries: Int
    public var availableRows: Int
    public var missingRows: Int
    public var failedRows: Int

    public init(totalCountries: Int, completedCountries: Int, availableRows: Int, missingRows: Int, failedRows: Int) {
        self.totalCountries = totalCountries
        self.completedCountries = completedCountries
        self.availableRows = availableRows
        self.missingRows = missingRows
        self.failedRows = failedRows
    }
}
