import CryptoKit
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

    public var pastappSessionFileName: String? {
        Self.pastappSessionFileName(for: appleAccount)
    }

    public var accountSwitchingTitle: String {
        let trimmedAccount = appleAccount.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAccount.isEmpty {
            return trimmedAccount
        }
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? countryCode : trimmedName
    }

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

    public static func pastappSessionFileName(for appleAccount: String) -> String? {
        let normalized = appleAccount.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return nil
        }
        let digest = SHA256.hash(data: Data(normalized.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return "\(digest).json"
    }

    public mutating func apply(validatedSession session: PastappCompatibleSession, validatedAt: Date = Date()) {
        loginStatus = .validated
        lastValidatedAt = validatedAt
        let validatedStorefrontID = session.storefrontIdentifier
        storefrontID = validatedStorefrontID ?? storefrontID
        if let countryCode = CountryStorefrontCatalog.countryCode(forStorefrontIdentifier: validatedStorefrontID) {
            self.countryCode = countryCode
        }
        sessionFileName = pastappSessionFileName
    }
}

public struct PastappCompatibleSession: Hashable, Codable, Sendable {
    public static let flowVersion = "gsa-srp-v10"
    public static let sessionTTL: TimeInterval = 365 * 24 * 60 * 60

    public var appleAccount: String
    public var flowVersion: String
    public var savedAt: Date
    public var user: PastappSessionUser

    private enum CodingKeys: String, CodingKey {
        case appleAccount
        case flowVersion
        case savedAt
        case user
    }

    public init(
        appleAccount: String,
        flowVersion: String = Self.flowVersion,
        savedAt: Date,
        user: PastappSessionUser
    ) {
        self.appleAccount = appleAccount
        self.flowVersion = flowVersion
        self.savedAt = savedAt
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appleAccount = try container.decode(String.self, forKey: .appleAccount)
        flowVersion = try container.decode(String.self, forKey: .flowVersion)
        let savedAtMilliseconds = try container.decode(Double.self, forKey: .savedAt)
        savedAt = Date(timeIntervalSince1970: savedAtMilliseconds / 1000)
        user = try container.decode(PastappSessionUser.self, forKey: .user)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appleAccount, forKey: .appleAccount)
        try container.encode(flowVersion, forKey: .flowVersion)
        try container.encode(Int64((savedAt.timeIntervalSince1970 * 1000).rounded()), forKey: .savedAt)
        try container.encode(user, forKey: .user)
    }

    public var storefrontIdentifier: String? {
        guard let raw = user.authHeaders["X-Apple-Store-Front"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }
        return raw.split(separator: "-").first.map(String.init)
    }

    public func isValid(for account: String, now: Date = Date()) -> Bool {
        guard flowVersion == Self.flowVersion else {
            return false
        }
        guard Self.normalizedAccount(appleAccount) == Self.normalizedAccount(account) else {
            return false
        }
        guard now.timeIntervalSince(savedAt) <= Self.sessionTTL else {
            return false
        }
        guard !(user.authHeaders["X-Token"] ?? "").isEmpty,
              !(user.authHeaders["X-Dsid"] ?? "").isEmpty else {
            return false
        }
        return true
    }

    private static func normalizedAccount(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

public struct PastappSessionUser: Hashable, Codable, Sendable {
    public var dsPersonId: String
    public var pod: String
    public var authHeaders: [String: String]
    public var cookieText: String

    public init(
        dsPersonId: String,
        pod: String,
        authHeaders: [String: String],
        cookieText: String
    ) {
        self.dsPersonId = dsPersonId
        self.pod = pod
        self.authHeaders = authHeaders
        self.cookieText = cookieText
    }
}

public struct PastappSessionStore: Sendable {
    public enum StoreError: Error {
        case missingAccountIdentifier
    }

    public let sessionsDirectory: URL

    public init(sessionsDirectory: URL) {
        self.sessionsDirectory = sessionsDirectory
    }

    public func sessionURL(for appleAccount: String) throws -> URL {
        guard let fileName = AccountProfile.pastappSessionFileName(for: appleAccount) else {
            throw StoreError.missingAccountIdentifier
        }
        return sessionsDirectory.appendingPathComponent(fileName)
    }

    public func loadValidSession(for appleAccount: String, now: Date = Date()) throws -> PastappCompatibleSession? {
        let url = try sessionURL(for: appleAccount)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        let session = try JSONDecoder().decode(PastappCompatibleSession.self, from: Data(contentsOf: url))
        return session.isValid(for: appleAccount, now: now) ? session : nil
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

    public var validatedAccounts: [AccountProfile] {
        accounts.filter { $0.loginStatus == .validated }
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
