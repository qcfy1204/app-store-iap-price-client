import Foundation
import AppStoreIAPClientCore

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
    if actual != expected {
        throw TestFailure(description: "\(message). Expected \(expected), got \(actual).")
    }
}

func assertTrue(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw TestFailure(description: message)
    }
}

func assertNil<T>(_ value: T?, _ message: String) throws {
    if value != nil {
        throw TestFailure(description: message)
    }
}

let tests: [(String, () throws -> Void)] = [
    ("AppIDParser extracts numeric ID", {
        try assertEqual(AppIDParser.extractAppID(from: "1234567890"), "1234567890", "Numeric ID should parse")
    }),
    ("AppIDParser extracts ID from storefront URL", {
        try assertEqual(
            AppIDParser.extractAppID(from: "https://apps.apple.com/us/app/example/id1234567890"),
            "1234567890",
            "Storefront URL should parse"
        )
    }),
    ("AppIDParser extracts ID from query URL", {
        try assertEqual(
            AppIDParser.extractAppID(from: "https://apps.apple.com/app/id987654321?mt=8"),
            "987654321",
            "Query URL should parse"
        )
    }),
    ("AppIDParser rejects missing ID", {
        try assertNil(AppIDParser.extractAppID(from: "https://apps.apple.com/us/app/example"), "URL without ID should not parse")
    }),
    ("AppIDParser extracts storefront country from URL", {
        try assertEqual(AppIDParser.extractCountryCode(from: "https://apps.apple.com/cn/app/example/id1234567890"), "CN", "CN storefront should parse")
        try assertEqual(AppIDParser.extractCountryCode(from: "https://apps.apple.com/jp/app/example/id1234567890"), "JP", "JP storefront should parse")
    }),
    ("AppIDParser returns nil country for plain IDs", {
        try assertNil(AppIDParser.extractCountryCode(from: "1234567890"), "Plain ID should not include country")
    }),
    ("CountryStorefrontCatalog contains major storefronts", {
        let codes = Set(CountryStorefrontCatalog.all.map(\.countryCode))
        try assertTrue(codes.contains("US"), "Catalog should include United States")
        try assertTrue(codes.contains("CN"), "Catalog should include China Mainland")
        try assertTrue(codes.contains("JP"), "Catalog should include Japan")
        try assertTrue(codes.contains("GB"), "Catalog should include United Kingdom")
    }),
    ("CountryStorefrontCatalog countries have currency codes", {
        try assertTrue(!CountryStorefrontCatalog.all.isEmpty, "Catalog should not be empty")
        try assertTrue(CountryStorefrontCatalog.all.allSatisfy { !$0.currencyCode.isEmpty }, "Every storefront needs a currency")
    }),
    ("CountryStorefrontCatalog resolves Apple storefront identifiers for account regions", {
        try assertEqual(CountryStorefrontCatalog.countryCode(forStorefrontIdentifier: "143480"), "TR", "Turkey storefront ID should map to TR")
        try assertEqual(CountryStorefrontCatalog.countryCode(forStorefrontIdentifier: "143441-1,29"), "US", "US storefront ID should strip suffix and map to US")
        try assertNil(CountryStorefrontCatalog.countryCode(forStorefrontIdentifier: "999999"), "Unknown storefront ID should not map")
    }),
    ("PriceNormalizer marks missing public rows as not public", {
        let app = AppSearchResult(appId: "123", name: "Example", developerName: "Dev", bundleId: nil, primaryGenre: nil, sourceCountry: "US")
        let storefront = Storefront(countryCode: "US", displayName: "United States", currencyCode: "USD", storefrontIdentifier: nil)
        let row = PriceNormalizer.missingPublicRow(app: app, storefront: storefront, message: "No public IAP prices found")

        try assertEqual(row.countryCode, "US", "Country should match")
        try assertEqual(row.productName, "Example", "Product name should use app name")
        try assertEqual(row.source, .publicStorefront, "Source should be public storefront")
        try assertEqual(row.status, .notPublic, "Status should be not public")
        try assertTrue(row.price == nil, "Missing row should not include a price")
    }),
    ("PriceNormalizer marks failure rows as request failed", {
        let storefront = Storefront(countryCode: "JP", displayName: "Japan", currencyCode: "JPY", storefrontIdentifier: nil)
        let row = PriceNormalizer.failureRow(appName: "Example", storefront: storefront, message: "Timed out")

        try assertEqual(row.status, .requestFailed, "Failure row should have request failed status")
        try assertEqual(row.message, "Timed out", "Failure row should keep message")
    }),
    ("AppStoreConnectClient reports credential configuration", {
        let empty = AppStoreConnectClient()
        try assertTrue(!empty.isConfigured(), "Empty Connect client should not be configured")

        let configured = AppStoreConnectClient(
            credentials: AppStoreConnectCredentials(
                issuerID: "issuer",
                keyID: "key",
                privateKeyPath: "/tmp/AuthKey.p8"
            )
        )
        try assertTrue(configured.isConfigured(), "Connect client with credentials should be configured")
    }),
    ("ExportService CSV contains header and row", {
        let row = PriceResultRow(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            countryCode: "US",
            countryName: "United States",
            currencyCode: "USD",
            productId: "123",
            productName: "Example",
            purchaseKind: .unknown,
            period: nil,
            price: nil,
            source: .publicStorefront,
            status: .notPublic,
            message: "No public price",
            updatedAt: Date(timeIntervalSince1970: 0)
        )
        let csv = ExportService.csv(rows: [row])
        try assertTrue(csv.contains("countryCode,countryName,currencyCode,productId,productName,purchaseKind,period,price,source,status,message,updatedAt"), "CSV should contain stable header")
        try assertTrue(csv.contains("US,United States,USD,123,Example,Unknown,,"), "CSV should contain row values")
    }),
    ("ExportService JSON encodes rows", {
        let data = try ExportService.jsonData(rows: [])
        try assertTrue(!data.isEmpty, "JSON export should produce data")
    }),
    ("L10n follows Simplified Chinese system language", {
        let l10n = L10n(preferredLanguages: ["zh-Hans-CN", "en-US"])
        try assertEqual(l10n.language, .simplifiedChinese, "zh-Hans should choose Simplified Chinese")
        try assertEqual(l10n.searchTitle, "搜索", "Search title should be Chinese")
    }),
    ("L10n follows Traditional Chinese system language", {
        let l10n = L10n(preferredLanguages: ["zh-Hant-TW", "en-US"])
        try assertEqual(l10n.language, .traditionalChinese, "zh-Hant should choose Traditional Chinese")
        try assertEqual(l10n.settingsButton, "設置", "Settings button should be Traditional Chinese")
        try assertEqual(l10n.accountSettingsTitle, "賬戶", "Account settings title should be Traditional Chinese")
    }),
    ("L10n falls back to English for unsupported languages", {
        let l10n = L10n(preferredLanguages: ["fr-FR"])
        try assertEqual(l10n.language, .english, "Unsupported language should choose English")
        try assertEqual(l10n.searchTitle, "Search", "Search title should be English")
    }),
    ("L10n localizes price status and source display names", {
        let l10n = L10n(preferredLanguages: ["zh-Hans-CN"])
        try assertEqual(l10n.displayName(for: PriceStatus.notPublic), "未公开", "Not public status should be Chinese")
        try assertEqual(l10n.displayName(for: PriceStatus.notAvailableInStorefront), "不可用", "Unavailable status should be Chinese")
        try assertEqual(l10n.displayName(for: PriceSource.publicStorefront), "公开商店", "Public source should be Chinese")
    }),
    ("L10n localizes control-adjacent save panel file name", {
        let l10n = L10n(preferredLanguages: ["zh-Hans-CN"])
        try assertEqual(l10n.exportBaseFileName, "AppStore内购价格", "Save panel base file name should be Chinese")
    }),
    ("L10n describes automatic country price lookup after app search", {
        let zh = L10n(preferredLanguages: ["zh-Hans-CN"])
        try assertEqual(
            zh.appNameSearchFieldHint,
            "输入 App Store 应用名称，然后按搜索。系统会自动选择最匹配的应用并查询所有已选国家和地区。",
            "Chinese app search hint should describe automatic lookup"
        )
        try assertEqual(
            zh.searchAppsHint,
            "按名称搜索 App Store 应用，并自动查询所选国家和地区的价格。",
            "Chinese search button hint should describe automatic lookup"
        )
    }),
    ("L10n localizes Pastapp-compatible account session controls", {
        let zh = L10n(preferredLanguages: ["zh-Hans-CN"])
        try assertEqual(zh.accountLoginButton, "登录并获取验证码", "Initial login button should describe requesting the code")
        try assertEqual(zh.accountContinueTwoFactorButton, "继续验证", "2FA continuation button should be Chinese")
        try assertEqual(zh.accountTwoFactorPlaceholder, "收到验证码后输入 6 位数字", "2FA placeholder should describe when to enter the code")
        try assertTrue(
            zh.accountNeedsTwoFactor("账户 1").contains("验证码已发送"),
            "2FA status should tell the user the code was sent"
        )
        try assertTrue(
            !zh.accountSettingsDescription.contains("本地会话"),
            "Compact account management should not expose local-session wording"
        )
    }),
    ("L10n localizes compact settings controls", {
        let zh = L10n(preferredLanguages: ["zh-Hans-CN"])
        try assertEqual(zh.currentAccountSettingLabel, "当前账户", "Current account setting label should be Chinese")
        try assertEqual(zh.queryScopeSettingLabel, "范围", "Query scope setting label should be Chinese")
        try assertEqual(zh.advancedRuntimeSettingsLabel, "高级运行时设置", "Advanced runtime disclosure label should be Chinese")
        try assertEqual(zh.accessibilityVoiceOverLabel, "旁白", "VoiceOver setting label should be Chinese")
    }),
    ("AccountProfile stores local Apple account region metadata without password fields", {
        let account = AccountProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            displayName: "Turkey Apple ID",
            appleAccount: "turkey@example.com",
            countryCode: "TR",
            storefrontID: "143480",
            loginStatus: .awaitingUserLogin,
            lastValidatedAt: nil,
            sessionFileName: "turkey-session.json"
        )

        try assertEqual(account.displayName, "Turkey Apple ID", "Account display name should be stored")
        try assertEqual(account.countryCode, "TR", "Account should keep storefront country code")
        try assertEqual(account.loginStatus, .awaitingUserLogin, "New login should be user-driven")
    }),
    ("AccountProfile display title prefers Apple account for account switching", {
        let account = AccountProfile(
            displayName: "账户 2",
            appleAccount: " user@example.com ",
            countryCode: "US"
        )

        try assertEqual(
            account.accountSwitchingTitle,
            "user@example.com",
            "Account switchers should show the Apple account, not the default profile name"
        )
    }),
    ("AccountConfiguration selection switches the active storefront country", {
        let turkeyID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let japanID = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!
        var configuration = AccountConfiguration(
            accounts: [
                AccountProfile(id: turkeyID, displayName: "Turkey", appleAccount: "tr@example.com", countryCode: "TR"),
                AccountProfile(id: japanID, displayName: "Japan", appleAccount: "jp@example.com", countryCode: "JP")
            ],
            selectedAccountID: turkeyID
        )

        try assertEqual(configuration.selectedAccount?.countryCode, "TR", "Initial selected account should drive Turkey storefront")
        configuration.selectAccount(id: japanID)
        try assertEqual(configuration.selectedAccount?.countryCode, "JP", "Switching account should switch storefront")
    }),
    ("AccountConfiguration exposes only validated accounts for quick switching", {
        let failedID = UUID(uuidString: "00000000-0000-0000-0000-000000000203")!
        let validatedID = UUID(uuidString: "00000000-0000-0000-0000-000000000204")!
        let configuration = AccountConfiguration(
            accounts: [
                AccountProfile(id: failedID, displayName: "Failed", appleAccount: "failed@example.com", countryCode: "SG", loginStatus: .failed),
                AccountProfile(id: validatedID, displayName: "US", appleAccount: "us@example.com", countryCode: "US", loginStatus: .validated)
            ],
            selectedAccountID: failedID
        )

        try assertEqual(configuration.validatedAccounts.map(\.id), [validatedID], "Quick switching should only include logged-in accounts")
    }),
    ("CountryStorefrontCatalog default account country follows system region deterministically", {
        try assertEqual(
            CountryStorefrontCatalog.defaultAccountCountryCode(preferredRegionCode: "cn"),
            "CN",
            "Supported system region should be used for new account defaults"
        )
        try assertEqual(
            CountryStorefrontCatalog.defaultAccountCountryCode(preferredRegionCode: nil),
            "US",
            "Missing system region should fall back to US"
        )
        try assertEqual(
            CountryStorefrontCatalog.defaultAccountCountryCode(preferredRegionCode: "ZZ"),
            "US",
            "Unsupported system region should fall back to US"
        )
    }),
    ("AccountDrivenQueryScope uses only a validated selected account region", {
        let validated = AccountProfile(
            displayName: "Hong Kong",
            appleAccount: "hk@example.com",
            countryCode: "HK",
            loginStatus: .validated
        )
        let awaiting = AccountProfile(
            displayName: "Turkey",
            appleAccount: "tr@example.com",
            countryCode: "TR",
            loginStatus: .awaitingUserLogin
        )

        try assertEqual(
            AccountDrivenQueryScope.resolve(selectedAccount: validated),
            .storefront(CountryStorefrontCatalog.all.first { $0.countryCode == "HK" }!),
            "Validated account should be the only source for query storefront"
        )
        try assertEqual(
            AccountDrivenQueryScope.resolve(selectedAccount: awaiting),
            .unavailable,
            "Awaiting-login account should not be treated as a usable query storefront"
        )
        try assertEqual(
            AccountDrivenQueryScope.resolve(selectedAccount: nil),
            .unavailable,
            "Missing account should force account management instead of defaulting to a public storefront"
        )
    }),
    ("PastappCompatibleSession validates cached StoreServices credentials", {
        let savedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let session = PastappCompatibleSession(
            appleAccount: "turkey@example.com",
            savedAt: savedAt,
            user: PastappSessionUser(
                dsPersonId: "123456",
                pod: "32",
                authHeaders: [
                    "X-Dsid": "123456",
                    "X-Token": "store-token",
                    "X-Apple-Store-Front": "143480-2,29"
                ],
                cookieText: "# Netscape HTTP Cookie File"
            )
        )

        try assertTrue(
            session.isValid(for: " Turkey@Example.com ", now: savedAt.addingTimeInterval(60)),
            "Pastapp-compatible session should validate normalized account and required auth headers"
        )
        try assertEqual(session.storefrontIdentifier, "143480", "Storefront identifier should strip Apple suffix")
    }),
    ("PastappCompatibleSession rejects stale or incomplete sessions", {
        let savedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let incomplete = PastappCompatibleSession(
            appleAccount: "us@example.com",
            savedAt: savedAt,
            user: PastappSessionUser(dsPersonId: "123", pod: "", authHeaders: ["X-Dsid": "123"], cookieText: "")
        )
        let stale = PastappCompatibleSession(
            appleAccount: "us@example.com",
            savedAt: savedAt,
            user: PastappSessionUser(dsPersonId: "123", pod: "", authHeaders: ["X-Dsid": "123", "X-Token": "token"], cookieText: "")
        )

        try assertTrue(!incomplete.isValid(for: "us@example.com", now: savedAt), "Session without X-Token should be invalid")
        try assertTrue(!stale.isValid(for: "us@example.com", now: savedAt.addingTimeInterval(PastappCompatibleSession.sessionTTL + 1)), "Session beyond Pastapp TTL should be invalid")
    }),
    ("PastappCompatibleSession decodes JavaScript millisecond session JSON", {
        let json = """
        {
          "appleAccount": "jp@example.com",
          "flowVersion": "gsa-srp-v10",
          "savedAt": 1800000000000,
          "user": {
            "accountInfo": {"appleId": "jp@example.com"},
            "dsPersonId": "654321",
            "pod": "11",
            "authHeaders": {
              "X-Dsid": "654321",
              "X-Token": "store-token",
              "X-Apple-Store-Front": "143462-9,29"
            },
            "cookieText": "# Netscape HTTP Cookie File"
          }
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(PastappCompatibleSession.self, from: json)

        try assertTrue(session.isValid(for: "jp@example.com", now: Date(timeIntervalSince1970: 1_800_000_001)), "Pastapp JSON session should decode and validate")
        try assertEqual(session.savedAt, Date(timeIntervalSince1970: 1_800_000_000), "JavaScript milliseconds should decode to Date")
        try assertEqual(session.storefrontIdentifier, "143462", "Decoded storefront identifier should strip suffix")
    }),
    ("AccountProfile derives Pastapp-compatible session file name from Apple account", {
        let account = AccountProfile(displayName: "Turkey", appleAccount: " Turkey@Example.com ", countryCode: "TR")

        try assertEqual(
            account.pastappSessionFileName,
            "c31bbd495c5649f5ce07ad3d7848c6ef4c41d0dc72f8cc16e64050447f5fe320.json",
            "Session file should match Pastapp SHA-256 naming"
        )
    }),
    ("PastappSessionStore loads valid local session by derived account file name", {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PastappSessionStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let session = PastappCompatibleSession(
            appleAccount: "tr@example.com",
            savedAt: Date(timeIntervalSince1970: 1_800_000_000),
            user: PastappSessionUser(
                dsPersonId: "123",
                pod: "12",
                authHeaders: ["X-Dsid": "123", "X-Token": "token", "X-Apple-Store-Front": "143480-2,29"],
                cookieText: "cookie"
            )
        )
        let store = PastappSessionStore(sessionsDirectory: directory)
        let fileURL = directory.appendingPathComponent(AccountProfile.pastappSessionFileName(for: "tr@example.com")!)
        try JSONEncoder().encode(session).write(to: fileURL)

        let loaded = try store.loadValidSession(for: " TR@example.com ", now: Date(timeIntervalSince1970: 1_800_000_001))

        try assertEqual(loaded?.storefrontIdentifier, "143480", "Store should load matching valid session")
    }),
    ("PastappLoginLineParser parses JSON events and final validate result", {
        let needs2FA = try PastappLoginLineParser.parse(#"{"type":"needs_2fa","message":"需要双重验证码","code":"NEEDS_2FA"}"#)
        let account = try PastappLoginLineParser.parse(#"{"type":"account","message":"账户地区：143480","storefront":"143480"}"#)
        let result = try PastappLoginLineParser.parse(#"{"ok":true,"storefront":"143480","firstName":"Ada","lastName":"Lovelace"}"#)

        try assertEqual(needs2FA, .event(PastappLoginEvent(type: .needs2FA, message: "需要双重验证码", code: "NEEDS_2FA", storefront: nil)), "2FA event should parse")
        try assertEqual(account, .event(PastappLoginEvent(type: .account, message: "账户地区：143480", code: nil, storefront: "143480")), "Account storefront event should parse")
        try assertEqual(result, .result(PastappLoginResult(ok: true, storefront: "143480", firstName: "Ada", lastName: "Lovelace")), "Final login result should parse")
    }),
    ("PastappAccountIAPLineParser parses account metadata rows", {
        let line = try PastappAccountIAPLineParser.parse(#"{"ok":true,"appId":"414478124","appName":"WeChat","storefront":"143465","countryCode":"CN","currencyCode":"CNY","rows":[{"productId":"vip","productName":"VIP","purchaseKind":"Subscription","period":"1 month","price":"12.00","currencyCode":"CNY","message":"account"}],"message":"ok"}"#)

        try assertEqual(line?.countryCode, "CN", "Account result should preserve country code")
        try assertEqual(line?.rows.count, 1, "Account result should parse rows")
        try assertEqual(line?.rows.first?.price, Decimal(string: "12.00"), "Account row price should parse as Decimal")
        try assertEqual(line?.rows.first?.purchaseKind, .subscription, "Account row kind should parse")
    }),
    ("PastappLoginCommand builds validate-login environment without persisting password", {
        let command = PastappLoginCommand(
            nodeExecutable: URL(fileURLWithPath: "/runtime/node"),
            mainScript: URL(fileURLWithPath: "/runtime/main.js"),
            sessionsDirectory: URL(fileURLWithPath: "/sessions"),
            appleAccount: "tr@example.com",
            password: "secret",
            twoFactorCode: "123456",
            languageCode: "zh-Hans"
        )

        try assertEqual(command.arguments, ["/runtime/main.js"], "Node command should run the Pastapp main script")
        try assertEqual(command.environment["APPLE_ID"], "tr@example.com", "Command should pass account identifier")
        try assertEqual(command.environment["APPLE_PWD"], "secret", "Command should pass password only through process environment")
        try assertEqual(command.environment["APPLE_CODE"], "123456", "Command should pass 2FA code when provided")
        try assertEqual(command.environment["IPA_VALIDATE_LOGIN"], "1", "Command should request validate-login mode")
        try assertEqual(command.environment["PASTAPP_JSON_EVENTS"], "1", "Command should request JSON events")
    }),
    ("PastappLoginRunner executes helper and returns final storefront result", {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PastappLoginRunnerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let scriptURL = directory.appendingPathComponent("fake-login.sh")
        let script = """
        printf '%s\\n' '{"type":"account","message":"账户地区：143480","storefront":"143480"}'
        printf '%s\\n' '{"ok":true,"storefront":"143480","firstName":"Ada","lastName":"Lovelace"}'
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let command = PastappLoginCommand(
            nodeExecutable: URL(fileURLWithPath: "/bin/sh"),
            mainScript: scriptURL,
            sessionsDirectory: directory,
            appleAccount: "tr@example.com",
            password: "secret",
            languageCode: "zh-Hans"
        )
        var events: [PastappLoginEvent] = []

        let result = try PastappLoginRunner().run(command) { events.append($0) }

        try assertEqual(events.count, 1, "Runner should emit structured account event")
        try assertEqual(events.first?.storefront, "143480", "Runner should parse event storefront")
        try assertEqual(result, PastappLoginResult(ok: true, storefront: "143480", firstName: "Ada", lastName: "Lovelace"), "Runner should return final result")
    }),
    ("PastappLoginRunner reports two-factor requirement as a resumable login state", {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PastappLoginRunner2FATests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let scriptURL = directory.appendingPathComponent("fake-needs-2fa.sh")
        let script = """
        printf '%s\\n' '{"type":"needs_2fa","message":"需要双重验证码","code":"NEEDS_2FA"}'
        exit 1
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let command = PastappLoginCommand(
            nodeExecutable: URL(fileURLWithPath: "/bin/sh"),
            mainScript: scriptURL,
            sessionsDirectory: directory,
            appleAccount: "tr@example.com",
            password: "secret",
            languageCode: "zh-Hans"
        )
        var events: [PastappLoginEvent] = []

        do {
            _ = try PastappLoginRunner().run(command) { events.append($0) }
            throw TestFailure(description: "Runner should throw a two-factor requirement")
        } catch let error as PastappLoginRunner.RunnerError {
            try assertEqual(
                error,
                .needsTwoFactor(message: "需要双重验证码"),
                "2FA helper event should become a resumable runner error"
            )
        }
        try assertEqual(events.count, 1, "Runner should still emit the 2FA event before throwing")
    }),
    ("PastappRuntimeLocator finds bundled helper and node executable", {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PastappRuntimeLocatorTests-\(UUID().uuidString)", isDirectory: true)
        let helperRoot = directory.appendingPathComponent("PastappHelper", isDirectory: true)
        let nodeProject = helperRoot.appendingPathComponent("NodeProject", isDirectory: true)
        let nodeURL = helperRoot.appendingPathComponent("runtime/node/bin/node")
        try FileManager.default.createDirectory(at: nodeProject, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: nodeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "".write(to: nodeProject.appendingPathComponent("main.js"), atomically: true, encoding: .utf8)
        try "".write(to: nodeURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let location = PastappRuntimeLocator.locate(
            resourceRoots: [directory],
            nodeCandidates: []
        )

        try assertEqual(location?.mainScript, nodeProject.appendingPathComponent("main.js"), "Locator should find bundled helper main.js")
        try assertEqual(location?.nodeExecutable, nodeURL, "Locator should find bundled node executable")
    }),
    ("AccountProfile applies Pastapp-compatible session metadata", {
        var account = AccountProfile(displayName: "Turkey", appleAccount: "tr@example.com", countryCode: "TR")
        let session = PastappCompatibleSession(
            appleAccount: "tr@example.com",
            savedAt: Date(timeIntervalSince1970: 1_800_000_000),
            user: PastappSessionUser(
                dsPersonId: "123",
                pod: "",
                authHeaders: ["X-Dsid": "123", "X-Token": "token", "X-Apple-Store-Front": "143480-2,29"],
                cookieText: ""
            )
        )

        account.apply(validatedSession: session, validatedAt: Date(timeIntervalSince1970: 1_800_000_010))

        try assertEqual(account.loginStatus, .validated, "Applying a valid session should validate the account")
        try assertEqual(account.storefrontID, "143480", "Applying a session should copy storefront identifier")
        try assertEqual(account.countryCode, "TR", "Applying a session should update country code from storefront identifier")
        try assertEqual(account.lastValidatedAt, Date(timeIntervalSince1970: 1_800_000_010), "Applying a session should store validation time")
        try assertEqual(account.sessionFileName, account.pastappSessionFileName, "Applying a session should store derived session file name")
    }),
    ("AccountSecureCodec encrypts local account configuration without plaintext account identifiers", {
        let configuration = AccountConfiguration(
            accounts: [
                AccountProfile(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
                    displayName: "United States",
                    appleAccount: "us-account@example.com",
                    countryCode: "US"
                )
            ],
            selectedAccountID: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!
        )
        let key = AccountSecureCodec.makeKeyData(seed: "unit-test-key")
        let encrypted = try AccountSecureCodec.encrypt(configuration, keyData: key)
        let encryptedText = String(data: encrypted, encoding: .utf8) ?? ""

        try assertTrue(!encryptedText.contains("us-account@example.com"), "Encrypted payload should not contain plaintext Apple account")

        let decrypted = try AccountSecureCodec.decrypt(AccountConfiguration.self, from: encrypted, keyData: key)
        try assertEqual(decrypted, configuration, "Decrypted configuration should match original")
    }),
    ("AccountSecureStore saves encrypted account configuration and reloads it locally", {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AppStoreIAPClientUnitTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = AccountSecureStore(baseDirectory: directory)
        let configuration = AccountConfiguration(
            accounts: [
                AccountProfile(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000401")!,
                    displayName: "Japan",
                    appleAccount: "jp-account@example.com",
                    countryCode: "JP"
                )
            ],
            selectedAccountID: UUID(uuidString: "00000000-0000-0000-0000-000000000401")!
        )

        try store.save(configuration)
        let raw = try Data(contentsOf: directory.appendingPathComponent("credentials.enc"))
        let rawText = String(data: raw, encoding: .utf8) ?? ""
        try assertTrue(!rawText.contains("jp-account@example.com"), "Saved credential file should be encrypted")

        let loaded = try store.load()
        try assertEqual(loaded, configuration, "Loaded account configuration should match saved configuration")
    })
]

var failures = 0
for (name, test) in tests {
    do {
        try test()
        print("PASS: \(name)")
    } catch {
        failures += 1
        print("FAIL: \(name): \(error)")
    }
}

if failures > 0 {
    exit(1)
}

print("All \(tests.count) tests passed.")
