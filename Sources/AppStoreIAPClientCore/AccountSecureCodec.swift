import CryptoKit
import Foundation

public enum AccountSecureCodec {
    public enum CodecError: Error {
        case invalidKey
        case invalidCiphertext
    }

    public static func makeKeyData(seed: String) -> Data {
        Data(SHA256.hash(data: Data(seed.utf8)))
    }

    public static func makeRandomKeyData() -> Data {
        SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    }

    public static func encrypt<T: Encodable>(_ value: T, keyData: Data) throws -> Data {
        let key = try symmetricKey(from: keyData)
        let payload = try JSONEncoder().encode(value)
        let sealed = try AES.GCM.seal(payload, using: key)
        guard let combined = sealed.combined else {
            throw CodecError.invalidCiphertext
        }
        return combined
    }

    public static func decrypt<T: Decodable>(_ type: T.Type, from data: Data, keyData: Data) throws -> T {
        let key = try symmetricKey(from: keyData)
        let sealed = try AES.GCM.SealedBox(combined: data)
        let payload = try AES.GCM.open(sealed, using: key)
        return try JSONDecoder().decode(T.self, from: payload)
    }

    private static func symmetricKey(from keyData: Data) throws -> SymmetricKey {
        guard keyData.count == 32 else {
            throw CodecError.invalidKey
        }
        return SymmetricKey(data: keyData)
    }
}
