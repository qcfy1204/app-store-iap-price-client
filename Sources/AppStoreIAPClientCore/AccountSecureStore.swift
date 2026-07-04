import Foundation

public struct AccountSecureStore: Sendable {
    public enum StoreError: Error {
        case missingConfiguration
    }

    public let baseDirectory: URL
    public let keyURL: URL
    public let credentialsURL: URL

    public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
        self.keyURL = baseDirectory.appendingPathComponent("credential-key.bin")
        self.credentialsURL = baseDirectory.appendingPathComponent("credentials.enc")
    }

    public func load() throws -> AccountConfiguration {
        guard FileManager.default.fileExists(atPath: credentialsURL.path) else {
            return AccountConfiguration()
        }
        let keyData = try loadOrCreateKey()
        let encrypted = try Data(contentsOf: credentialsURL)
        return try AccountSecureCodec.decrypt(AccountConfiguration.self, from: encrypted, keyData: keyData)
    }

    public func save(_ configuration: AccountConfiguration) throws {
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        let keyData = try loadOrCreateKey()
        let encrypted = try AccountSecureCodec.encrypt(configuration, keyData: keyData)
        try encrypted.write(to: credentialsURL, options: [.atomic])
    }

    public func clear() throws {
        if FileManager.default.fileExists(atPath: credentialsURL.path) {
            try FileManager.default.removeItem(at: credentialsURL)
        }
    }

    private func loadOrCreateKey() throws -> Data {
        if FileManager.default.fileExists(atPath: keyURL.path) {
            return try Data(contentsOf: keyURL)
        }
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        let keyData = AccountSecureCodec.makeRandomKeyData()
        try keyData.write(to: keyURL, options: [.atomic])
        return keyData
    }
}
