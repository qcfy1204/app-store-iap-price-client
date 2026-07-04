import Foundation

public enum AccountLoginStatus: String, Codable, CaseIterable, Sendable {
    case notConfigured = "Not Configured"
    case awaitingUserLogin = "Awaiting User Login"
    case validated = "Validated"
    case failed = "Failed"
}

public struct AccountProfile: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var displayName: String
    public var appleAccount: String
    public var countryCode: String
    public var storefrontID: String?
    public var loginStatus: AccountLoginStatus
    public var lastValidatedAt: Date?
    public var sessionFileName: String?

    public init(
        id: UUID = UUID(),
        displayName: String,
        appleAccount: String = "",
        countryCode: String,
        storefrontID: String? = nil,
        loginStatus: AccountLoginStatus = .notConfigured,
        lastValidatedAt: Date? = nil,
        sessionFileName: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.appleAccount = appleAccount
        self.countryCode = countryCode.uppercased()
        self.storefrontID = storefrontID
        self.loginStatus = loginStatus
        self.lastValidatedAt = lastValidatedAt
        self.sessionFileName = sessionFileName
    }
}

public struct AccountConfiguration: Hashable, Codable, Sendable {
    public var accounts: [AccountProfile]
    public var selectedAccountID: UUID?

    public init(accounts: [AccountProfile] = [], selectedAccountID: UUID? = nil) {
        self.accounts = accounts
        self.selectedAccountID = selectedAccountID ?? accounts.first?.id
    }

    public var selectedAccount: AccountProfile? {
        guard let selectedAccountID else {
            return nil
        }
        return accounts.first { $0.id == selectedAccountID }
    }

    public mutating func selectAccount(id: UUID?) {
        guard let id else {
            selectedAccountID = nil
            return
        }
        selectedAccountID = accounts.contains { $0.id == id } ? id : selectedAccountID
    }

    public mutating func upsert(_ account: AccountProfile) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        if selectedAccountID == nil {
            selectedAccountID = account.id
        }
    }

    public mutating func deleteAccount(id: UUID) {
        accounts.removeAll { $0.id == id }
        if selectedAccountID == id {
            selectedAccountID = accounts.first?.id
        }
    }
}
