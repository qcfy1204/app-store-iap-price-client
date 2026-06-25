import Foundation

public enum PriceNormalizer {
    public static func missingPublicRow(app: AppSearchResult, storefront: Storefront, message: String) -> PriceResultRow {
        PriceResultRow(
            countryCode: storefront.countryCode,
            countryName: storefront.displayName,
            currencyCode: storefront.currencyCode,
            productId: app.appId,
            productName: app.name,
            purchaseKind: .unknown,
            period: nil,
            price: nil,
            source: .publicStorefront,
            status: .notPublic,
            message: message
        )
    }

    public static func unavailableRow(app: AppSearchResult, storefront: Storefront, message: String) -> PriceResultRow {
        PriceResultRow(
            countryCode: storefront.countryCode,
            countryName: storefront.displayName,
            currencyCode: storefront.currencyCode,
            productId: app.appId,
            productName: app.name,
            purchaseKind: .unknown,
            period: nil,
            price: nil,
            source: .publicStorefront,
            status: .notAvailableInStorefront,
            message: message
        )
    }

    public static func failureRow(appName: String, storefront: Storefront, message: String) -> PriceResultRow {
        PriceResultRow(
            countryCode: storefront.countryCode,
            countryName: storefront.displayName,
            currencyCode: storefront.currencyCode,
            productId: "",
            productName: appName,
            purchaseKind: .unknown,
            period: nil,
            price: nil,
            source: .publicStorefront,
            status: .requestFailed,
            message: message
        )
    }

    public static func connectUnauthorizedRow(app: AppSearchResult, storefront: Storefront, message: String) -> PriceResultRow {
        PriceResultRow(
            countryCode: storefront.countryCode,
            countryName: storefront.displayName,
            currencyCode: storefront.currencyCode,
            productId: app.appId,
            productName: app.name,
            purchaseKind: .unknown,
            period: nil,
            price: nil,
            source: .appStoreConnect,
            status: .connectUnauthorized,
            message: message
        )
    }
}
