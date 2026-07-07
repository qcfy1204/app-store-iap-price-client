import Foundation

public enum QueryDataSourceMode: String, Codable, CaseIterable, Sendable {
    case publicStorefront
    case signedInAccount
}

public enum AccountDrivenQueryScope: Equatable, Sendable {
    case unavailable
    case storefront(Storefront)

    public static func resolve(
        selectedAccount: AccountProfile?,
        catalog: [Storefront] = CountryStorefrontCatalog.all
    ) -> AccountDrivenQueryScope {
        guard let selectedAccount,
              selectedAccount.loginStatus == .validated,
              let storefront = catalog.first(where: { $0.countryCode == selectedAccount.countryCode }) else {
            return .unavailable
        }
        return .storefront(storefront)
    }
}
