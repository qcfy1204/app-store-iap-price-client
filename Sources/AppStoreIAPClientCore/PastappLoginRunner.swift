import Foundation

public enum PastappLoginEventType: String, Codable, Sendable {
    case account
    case needs2FA = "needs_2fa"
    case error
    case done
}

public struct PastappLoginEvent: Hashable, Codable, Sendable {
    public var type: PastappLoginEventType
    public var message: String
    public var code: String?
    public var storefront: String?

    public init(type: PastappLoginEventType, message: String, code: String? = nil, storefront: String? = nil) {
        self.type = type
        self.message = message
        self.code = code
        self.storefront = storefront
    }
}

public struct PastappLoginResult: Hashable, Codable, Sendable {
    public var ok: Bool
    public var storefront: String
    public var firstName: String
    public var lastName: String

    public init(ok: Bool, storefront: String, firstName: String = "", lastName: String = "") {
        self.ok = ok
        self.storefront = storefront
        self.firstName = firstName
        self.lastName = lastName
    }
}

public enum PastappLoginLine: Hashable, Sendable {
    case event(PastappLoginEvent)
    case result(PastappLoginResult)
    case ignored
}

public enum PastappLoginLineParser {
    public static func parse(_ line: String) throws -> PastappLoginLine {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "{", trimmed.last == "}" else {
            return .ignored
        }
        let data = Data(trimmed.utf8)
        if let event = try? JSONDecoder().decode(PastappLoginEvent.self, from: data) {
            return .event(event)
        }
        if let result = try? JSONDecoder().decode(PastappLoginResult.self, from: data) {
            return .result(result)
        }
        return .ignored
    }
}

public struct PastappLoginCommand: Hashable, Sendable {
    public var nodeExecutable: URL
    public var mainScript: URL
    public var sessionsDirectory: URL
    public var appleAccount: String
    public var password: String
    public var twoFactorCode: String
    public var languageCode: String

    public init(
        nodeExecutable: URL,
        mainScript: URL,
        sessionsDirectory: URL,
        appleAccount: String,
        password: String,
        twoFactorCode: String = "",
        languageCode: String
    ) {
        self.nodeExecutable = nodeExecutable
        self.mainScript = mainScript
        self.sessionsDirectory = sessionsDirectory
        self.appleAccount = appleAccount
        self.password = password
        self.twoFactorCode = twoFactorCode
        self.languageCode = languageCode
    }

    public var arguments: [String] {
        [mainScript.path]
    }

    public var environment: [String: String] {
        var values = ProcessInfo.processInfo.environment
        values["APPLE_ID"] = appleAccount
        values["APPLE_PWD"] = password
        values["APPLE_CODE"] = twoFactorCode
        values["IPA_VALIDATE_LOGIN"] = "1"
        values["PASTAPP_JSON_EVENTS"] = "1"
        values["IPA_SESSION_DIR"] = sessionsDirectory.path
        values["IPA_LANG"] = languageCode
        return values
    }
}

public struct PastappRuntimeLocation: Hashable, Sendable {
    public var nodeExecutable: URL
    public var mainScript: URL

    public init(nodeExecutable: URL, mainScript: URL) {
        self.nodeExecutable = nodeExecutable
        self.mainScript = mainScript
    }
}

public enum PastappRuntimeLocator {
    public static func locate(
        resourceRoots: [URL],
        nodeCandidates: [URL] = defaultNodeCandidates()
    ) -> PastappRuntimeLocation? {
        guard let mainScript = resourceRoots.lazy
            .flatMap(helperMainScriptCandidates(in:))
            .first(where: fileExists) else {
            return nil
        }
        let candidates = resourceRoots.flatMap(helperNodeCandidates(in:)) + nodeCandidates
        guard let nodeExecutable = candidates.first(where: fileExists) else {
            return nil
        }
        return PastappRuntimeLocation(nodeExecutable: nodeExecutable, mainScript: mainScript)
    }

    public static func defaultNodeCandidates() -> [URL] {
        [
            URL(fileURLWithPath: "/opt/homebrew/bin/node"),
            URL(fileURLWithPath: "/usr/local/bin/node"),
            URL(fileURLWithPath: "/usr/bin/node")
        ]
    }

    private static func helperMainScriptCandidates(in root: URL) -> [URL] {
        [
            root.appendingPathComponent("PastappHelper/NodeProject/main.js"),
            root.appendingPathComponent("PastappHelper/runtime/NodeProject/main.js"),
            root.appendingPathComponent("Resources/PastappHelper/NodeProject/main.js"),
            root.appendingPathComponent("Resources/PastappHelper/runtime/NodeProject/main.js"),
            root.appendingPathComponent("NodeProject/main.js"),
            root.appendingPathComponent("runtime/NodeProject/main.js")
        ]
    }

    private static func helperNodeCandidates(in root: URL) -> [URL] {
        [
            root.appendingPathComponent("PastappHelper/runtime/node/bin/node"),
            root.appendingPathComponent("PastappHelper/runtime/node/node"),
            root.appendingPathComponent("Resources/PastappHelper/runtime/node/bin/node"),
            root.appendingPathComponent("Resources/PastappHelper/runtime/node/node"),
            root.appendingPathComponent("runtime/node/bin/node"),
            root.appendingPathComponent("runtime/node/node")
        ]
    }

    private static func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}

public struct PastappLoginRunner: Sendable {
    public enum RunnerError: Error, CustomStringConvertible, LocalizedError, Equatable {
        case needsTwoFactor(message: String)
        case missingResult
        case failed(exitCode: Int32, stderr: String)

        public var description: String {
            switch self {
            case let .needsTwoFactor(message):
                return message
            case .missingResult:
                return "Pastapp helper did not return a final login result."
            case let .failed(exitCode, stderr):
                return "Pastapp helper exited with code \(exitCode): \(stderr)"
            }
        }

        public var errorDescription: String? {
            description
        }
    }

    public init() {}

    public func run(
        _ command: PastappLoginCommand,
        onEvent: (PastappLoginEvent) -> Void = { _ in }
    ) throws -> PastappLoginResult {
        let process = Process()
        process.executableURL = command.nodeExecutable
        process.arguments = command.arguments
        process.environment = command.environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        var result: PastappLoginResult?
        var twoFactorEvent: PastappLoginEvent?

        for line in output.split(whereSeparator: \.isNewline).map(String.init) {
            switch try PastappLoginLineParser.parse(line) {
            case let .event(event):
                if event.type == .needs2FA {
                    twoFactorEvent = event
                }
                onEvent(event)
            case let .result(parsedResult):
                result = parsedResult
            case .ignored:
                continue
            }
        }

        guard process.terminationStatus == 0 else {
            if let twoFactorEvent {
                throw RunnerError.needsTwoFactor(message: twoFactorEvent.message)
            }
            throw RunnerError.failed(exitCode: process.terminationStatus, stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        guard let result else {
            throw RunnerError.missingResult
        }
        return result
    }
}
