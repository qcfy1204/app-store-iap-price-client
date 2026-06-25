import Foundation

public struct AppStoreConnectCredentials: Equatable, Sendable {
    public var issuerID: String
    public var keyID: String
    public var privateKeyPath: String

    public init(issuerID: String, keyID: String, privateKeyPath: String) {
        self.issuerID = issuerID
        self.keyID = keyID
        self.privateKeyPath = privateKeyPath
    }
}

public protocol AppStoreConnectProviding: Sendable {
    func isConfigured() -> Bool
}

public struct AppStoreConnectClient: AppStoreConnectProviding {
    public var credentials: AppStoreConnectCredentials?

    public init(credentials: AppStoreConnectCredentials? = nil) {
        self.credentials = credentials
    }

    public func isConfigured() -> Bool {
        credentials != nil
    }
}
