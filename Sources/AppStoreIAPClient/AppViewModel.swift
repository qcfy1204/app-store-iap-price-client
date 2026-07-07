import Foundation
import SwiftUI
import AppStoreIAPClientCore

@MainActor
final class AppViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var directLookupText = ""
    @Published var queryText = ""
    @Published var searchResults: [AppSearchResult] = []
    @Published var selectedApp: AppSearchResult?
    @Published var resultRows: [PriceResultRow] = []
    @Published var selectedCountryCodes = CountryStorefrontCatalog.defaultSelection
    @Published var dataSourceMode: QueryDataSourceMode = .signedInAccount
    @Published var statusMessage: String
    @Published var isSearching = false
    @Published var isQuerying = false
    @Published var issuerID = ""
    @Published var keyID = ""
    @Published var privateKeyPath = ""
    @Published var accountConfiguration: AccountConfiguration
    @Published var accountPassword = ""
    @Published var accountTwoFactorCode = ""
    @Published var loginNodePath = ""
    @Published var loginMainScriptPath = ""
    @Published var isLoggingIn = false
    @Published var accountManagementRequest = UUID()
    @Published var twoFactorAccountID: UUID?
    @Published var accountLoginCompletion = UUID()

    let l10n: L10n
    private let publicClient = AppStorePublicClient()
    private let accountStore: AccountSecureStore
    private let sessionStore: PastappSessionStore
    private var queryTask: Task<Void, Never>?

    init(l10n: L10n = L10n()) {
        self.l10n = l10n
        self.statusMessage = l10n.ready
        self.accountStore = AccountSecureStore(baseDirectory: Self.defaultAccountStoreDirectory())
        self.sessionStore = PastappSessionStore(sessionsDirectory: Self.defaultSessionDirectory())
        self.accountConfiguration = (try? accountStore.load()) ?? AccountConfiguration()
        if let runtime = Self.defaultPastappRuntimeLocation() {
            self.loginNodePath = runtime.nodeExecutable.path
            self.loginMainScriptPath = runtime.mainScript.path
        }
        if let account = accountConfiguration.selectedAccount {
            self.selectedCountryCodes = [account.countryCode]
        }
    }

    var selectedStorefronts: [Storefront] {
        switch dataSourceMode {
        case .publicStorefront:
            return CountryStorefrontCatalog.all
        case .signedInAccount:
            switch AccountDrivenQueryScope.resolve(selectedAccount: selectedAccount) {
            case .storefront(let storefront):
                return [storefront]
            case .unavailable:
                return []
            }
        }
    }

    var canSubmitQuery: Bool {
        !queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSearching && !isQuerying
    }

    var hasUsableSignedInAccount: Bool {
        if case .storefront = AccountDrivenQueryScope.resolve(selectedAccount: selectedAccount) {
            return true
        }
        return false
    }

    var accountMenuTitle: String {
        guard let selectedAccount else {
            return l10n.accountMenuSignedOut
        }
        return "\(selectedAccount.accountSwitchingTitle) - \(selectedAccount.countryCode)"
    }

    var selectedAppSummary: String {
        guard let selectedApp else {
            return l10n.noAppSelected
        }
        return l10n.selectedAppSummary(
            name: selectedApp.name,
            developer: selectedApp.developerName,
            appID: selectedApp.appId
        )
    }

    var selectedAccount: AccountProfile? {
        accountConfiguration.selectedAccount
    }

    var selectedAccountSummary: String {
        guard let selectedAccount else {
            return l10n.noAccountSelected
        }
        return l10n.accountSummary(
            name: selectedAccount.accountSwitchingTitle,
            countryCode: selectedAccount.countryCode,
            status: l10n.displayName(for: selectedAccount.loginStatus)
        )
    }

    var accountRuntimeStatus: String {
        let hasNode = !loginNodePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasHelper = !loginMainScriptPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasNode && hasHelper {
            return l10n.accountRuntimeReady
        }
        if hasHelper {
            return l10n.accountRuntimeMissingNode
        }
        return l10n.accountRuntimeMissingHelper
    }

    var selectedAccountNeedsTwoFactor: Bool {
        selectedAccount?.id == twoFactorAccountID
    }

    var accountLoginButtonTitle: String {
        selectedAccountNeedsTwoFactor ? l10n.accountContinueTwoFactorButton : l10n.accountLoginButton
    }

    var querySummaryText: String {
        l10n.querySummary(
            completed: summary.completedCountries,
            total: summary.totalCountries,
            available: summary.availableRows,
            missing: summary.missingRows,
            failed: summary.failedRows
        )
    }

    var connectClient: AppStoreConnectClient {
        let trimmedIssuer = issuerID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = keyID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPath = privateKeyPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIssuer.isEmpty, !trimmedKey.isEmpty, !trimmedPath.isEmpty else {
            return AppStoreConnectClient()
        }
        return AppStoreConnectClient(
            credentials: AppStoreConnectCredentials(
                issuerID: trimmedIssuer,
                keyID: trimmedKey,
                privateKeyPath: trimmedPath
            )
        )
    }

    var summary: QuerySummary {
        QuerySummary(
            totalCountries: selectedStorefronts.count,
            completedCountries: Set(resultRows.map(\.countryCode)).count,
            availableRows: resultRows.filter { $0.status == .available }.count,
            missingRows: resultRows.filter { $0.status == .notPublic || $0.status == .notAvailableInStorefront }.count,
            failedRows: resultRows.filter { $0.status == .requestFailed || $0.status == .connectUnauthorized }.count
        )
    }

    func submitQuery() {
        let input = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            statusMessage = l10n.enterQueryBeforeSearch
            return
        }

        if dataSourceMode == .signedInAccount && !hasUsableSignedInAccount {
            statusMessage = l10n.noSignedInAccountForQuery
            openAccountManagement()
            return
        }

        if let appId = AppIDParser.extractAppID(from: input) {
            lookupApp(appId: appId, fallbackCountryCode: publicFallbackCountryCode(from: input))
        } else {
            searchApps(term: input)
        }
    }

    func openAccountManagement() {
        accountManagementRequest = UUID()
    }

    func searchApps() {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            statusMessage = l10n.enterAppNameToSearch
            return
        }

        searchApps(term: term)
    }

    private func searchApps(term: String) {
        isSearching = true
        statusMessage = l10n.searchingFor(term)

        Task {
            defer { isSearching = false }
            do {
                searchResults = try await publicClient.search(term: term)
                if let firstResult = searchResults.first {
                    selectedApp = firstResult
                    startQuery()
                } else {
                    selectedApp = nil
                    resultRows = []
                    statusMessage = l10n.foundApps(0)
                }
            } catch {
                searchResults = []
                selectedApp = nil
                resultRows = []
                statusMessage = l10n.searchFailed(error.localizedDescription)
            }
        }
    }

    func lookupDirectApp() {
        guard let appId = AppIDParser.extractAppID(from: directLookupText) else {
            statusMessage = l10n.enterValidAppID
            return
        }
        lookupApp(appId: appId, fallbackCountryCode: publicFallbackCountryCode(from: directLookupText))
    }

    private func lookupApp(appId: String, fallbackCountryCode: String) {
        let countryCode = primaryLookupCountryCode(fallbackCountryCode: fallbackCountryCode)
        isSearching = true
        statusMessage = l10n.lookingUpApp(appId)

        Task {
            defer { isSearching = false }
            do {
                selectedApp = try await publicClient.lookup(appId: appId, countryCode: countryCode)
                if let selectedApp {
                    searchResults = [selectedApp]
                    statusMessage = l10n.selectedApp(selectedApp.name)
                    startQuery()
                } else {
                    resultRows = []
                    statusMessage = l10n.noAppFound(appId, countryCode: countryCode)
                }
            } catch {
                resultRows = []
                statusMessage = l10n.lookupFailed(error.localizedDescription)
            }
        }
    }

    func chooseSearchResult(_ app: AppSearchResult?) {
        selectedApp = app
        guard app != nil else {
            resultRows = []
            statusMessage = l10n.noAppSelected
            return
        }
        startQuery()
    }

    func addAccountProfile() {
        let existingCount = accountConfiguration.accounts.count + 1
        let countryCode = CountryStorefrontCatalog.defaultAccountCountryCode()
        var account = AccountProfile(
            displayName: l10n.newAccountDefaultName(existingCount),
            countryCode: countryCode,
            loginStatus: .awaitingUserLogin
        )
        account.sessionFileName = account.pastappSessionFileName
        accountConfiguration.upsert(account)
        selectAccount(account.id)
        saveAccounts()
    }

    func updateAccountProfile(_ account: AccountProfile) {
        var normalizedAccount = account
        normalizedAccount.sessionFileName = normalizedAccount.pastappSessionFileName
        accountConfiguration.upsert(normalizedAccount)
        if accountConfiguration.selectedAccountID == normalizedAccount.id {
            selectedCountryCodes = [normalizedAccount.countryCode]
        }
        saveAccounts()
    }

    func selectAccount(_ id: UUID?) {
        let previousID = accountConfiguration.selectedAccountID
        accountConfiguration.selectAccount(id: id)
        if previousID != accountConfiguration.selectedAccountID {
            accountPassword = ""
            accountTwoFactorCode = ""
        }
        if let account = accountConfiguration.selectedAccount {
            selectedCountryCodes = [account.countryCode]
            statusMessage = l10n.selectedAccountProfile(account.accountSwitchingTitle, countryCode: account.countryCode)
        } else {
            statusMessage = l10n.noAccountSelected
        }
        saveAccounts()
    }

    func deleteSelectedAccount() {
        guard let id = accountConfiguration.selectedAccountID else {
            return
        }
        if twoFactorAccountID == id {
            twoFactorAccountID = nil
            accountPassword = ""
            accountTwoFactorCode = ""
        }
        accountConfiguration.deleteAccount(id: id)
        if let account = accountConfiguration.selectedAccount {
            selectedCountryCodes = [account.countryCode]
        } else {
            selectedCountryCodes = []
            statusMessage = l10n.noAccountSelected
        }
        saveAccounts()
    }

    func markSelectedAccountAwaitingLogin() {
        guard var account = accountConfiguration.selectedAccount else {
            return
        }
        do {
            if let session = try sessionStore.loadValidSession(for: account.appleAccount) {
                account.apply(validatedSession: session)
                accountConfiguration.upsert(account)
                if let storefrontID = account.storefrontID {
                statusMessage = l10n.accountSessionValidated(account.accountSwitchingTitle, storefrontID: storefrontID)
                } else {
                statusMessage = l10n.accountSessionValidated(account.accountSwitchingTitle, storefrontID: account.countryCode)
                }
            } else {
                account.loginStatus = .awaitingUserLogin
                account.lastValidatedAt = nil
                account.sessionFileName = account.pastappSessionFileName
                accountConfiguration.upsert(account)
                statusMessage = l10n.accountAwaitingUserLogin(account.accountSwitchingTitle)
            }
            saveAccounts()
        } catch {
            statusMessage = l10n.accountSessionValidationFailed(error.localizedDescription)
        }
    }

    func loginSelectedAccount() {
        guard var account = accountConfiguration.selectedAccount else {
            statusMessage = l10n.noAccountSelected
            return
        }
        let appleAccount = account.appleAccount.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = accountPassword
        let nodePath = loginNodePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let mainScriptPath = loginMainScriptPath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !appleAccount.isEmpty else {
            statusMessage = l10n.accountAppleIDRequired
            return
        }
        guard !password.isEmpty else {
            statusMessage = l10n.accountPasswordRequired
            return
        }
        guard !nodePath.isEmpty, !mainScriptPath.isEmpty else {
            statusMessage = l10n.accountLoginRuntimeRequired
            return
        }

        isLoggingIn = true
        statusMessage = l10n.accountLoginStarted(account.accountSwitchingTitle)
        let sessionsDirectory = Self.defaultSessionDirectory()
        let command = PastappLoginCommand(
            nodeExecutable: URL(fileURLWithPath: nodePath),
            mainScript: URL(fileURLWithPath: mainScriptPath),
            sessionsDirectory: sessionsDirectory,
            appleAccount: appleAccount,
            password: password,
            twoFactorCode: accountTwoFactorCode.trimmingCharacters(in: .whitespacesAndNewlines),
            languageCode: l10n.language == .simplifiedChinese ? "zh-Hans" : "en"
        )

        Task.detached {
            do {
                let result = try PastappLoginRunner().run(command)
                let session = try? PastappSessionStore(sessionsDirectory: sessionsDirectory)
                    .loadValidSession(for: appleAccount)
                await MainActor.run {
                    if let session {
                        account.apply(validatedSession: session)
                    } else {
                        account.loginStatus = result.ok ? .validated : .failed
                        account.storefrontID = result.storefront
                        if let countryCode = CountryStorefrontCatalog.countryCode(forStorefrontIdentifier: result.storefront) {
                            account.countryCode = countryCode
                        }
                        account.lastValidatedAt = Date()
                        account.sessionFileName = account.pastappSessionFileName
                    }
                    self.accountConfiguration.upsert(account)
                    self.selectedCountryCodes = [account.countryCode]
                    self.accountPassword = ""
                    self.accountTwoFactorCode = ""
                    self.twoFactorAccountID = nil
                    self.isLoggingIn = false
                    self.accountLoginCompletion = UUID()
                    self.saveAccounts()
                    self.statusMessage = self.l10n.accountSessionValidated(account.accountSwitchingTitle, storefrontID: result.storefront)
                }
            } catch {
                await MainActor.run {
                    if case let PastappLoginRunner.RunnerError.needsTwoFactor(message) = error {
                        account.loginStatus = .awaitingUserLogin
                        self.accountConfiguration.upsert(account)
                        self.twoFactorAccountID = account.id
                        self.accountTwoFactorCode = ""
                        self.statusMessage = message.isEmpty
                            ? self.l10n.accountNeedsTwoFactor(account.accountSwitchingTitle)
                            : self.l10n.accountNeedsTwoFactor(account.accountSwitchingTitle)
                    } else {
                        account.loginStatus = .failed
                        self.accountConfiguration.upsert(account)
                        self.accountPassword = ""
                        self.accountTwoFactorCode = ""
                        self.twoFactorAccountID = nil
                        self.statusMessage = self.l10n.accountLoginFailed(error.localizedDescription)
                    }
                    self.isLoggingIn = false
                    self.saveAccounts()
                }
            }
        }
    }

    func selectAllCountries() {
        selectedCountryCodes = CountryStorefrontCatalog.defaultSelection
        statusMessage = l10n.allCountriesSelected
    }

    func selectMajorCountries() {
        selectedCountryCodes = ["US", "CN", "JP", "GB", "CA", "AU", "DE", "FR", "KR", "HK"]
        statusMessage = l10n.majorCountriesSelected
    }

    func clearCountries() {
        selectedCountryCodes = []
        statusMessage = l10n.countrySelectionCleared
    }

    func toggleCountry(_ storefront: Storefront, isSelected: Bool) {
        if isSelected {
            selectedCountryCodes.insert(storefront.countryCode)
        } else {
            selectedCountryCodes.remove(storefront.countryCode)
        }
    }

    func startQuery() {
        guard let app = selectedApp else {
            statusMessage = l10n.selectAppBeforeQuery
            return
        }
        guard !selectedStorefronts.isEmpty else {
            statusMessage = l10n.selectCountryBeforeQuery
            return
        }

        queryTask?.cancel()
        resultRows = []
        isQuerying = true
        statusMessage = l10n.queryStarted(app.name)
        let storefronts = selectedStorefronts
        let connectConfigured = connectClient.isConfigured()

        queryTask = Task {
            for storefront in storefronts {
                if Task.isCancelled {
                    break
                }

                do {
                    if dataSourceMode == .signedInAccount {
                        let rows = try accountRows(app: app, storefront: storefront)
                        resultRows.append(contentsOf: rows)
                    } else {
                        let lookup = try await publicClient.lookup(appId: app.appId, countryCode: storefront.countryCode)
                        if let lookup {
                            let message = missingPublicMessage(
                                selectedApp: app,
                                storefrontApp: lookup,
                                connectConfigured: connectConfigured
                            )
                            resultRows.append(
                                PriceNormalizer.missingPublicRow(
                                    app: app,
                                    storefront: storefront,
                                    message: message
                                )
                            )
                        } else {
                            resultRows.append(
                                PriceNormalizer.unavailableRow(
                                    app: app,
                                    storefront: storefront,
                                    message: l10n.appNotFoundInStorefront
                                )
                            )
                        }
                    }
                } catch {
                    resultRows.append(failureRow(appName: app.name, storefront: storefront, message: error.localizedDescription))
                }

                statusMessage = l10n.queriedCountries(summary.completedCountries, summary.totalCountries)
            }

            isQuerying = false
            if Task.isCancelled {
                statusMessage = l10n.queryCancelled(summary.completedCountries)
            } else {
                statusMessage = l10n.queryComplete(summary.completedCountries)
            }
        }
    }

    private func accountRows(app: AppSearchResult, storefront: Storefront) throws -> [PriceResultRow] {
        guard let account = selectedAccount else {
            throw NSError(domain: "AppStoreIAPClient", code: 1, userInfo: [NSLocalizedDescriptionKey: l10n.noSignedInAccountForQuery])
        }
        let nodePath = loginNodePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let mainScriptPath = loginMainScriptPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nodePath.isEmpty, !mainScriptPath.isEmpty else {
            throw NSError(domain: "AppStoreIAPClient", code: 2, userInfo: [NSLocalizedDescriptionKey: l10n.accountLoginRuntimeRequired])
        }
        let command = PastappAccountIAPCommand(
            nodeExecutable: URL(fileURLWithPath: nodePath),
            mainScript: URL(fileURLWithPath: mainScriptPath),
            sessionsDirectory: Self.defaultSessionDirectory(),
            appleAccount: account.appleAccount,
            appId: app.appId,
            countryCode: storefront.countryCode,
            languageCode: l10n.language == .simplifiedChinese ? "zh-Hans" : "en"
        )
        let result = try PastappAccountIAPRunner().run(command)
        if result.rows.isEmpty {
            return [
                PriceResultRow(
                    countryCode: storefront.countryCode,
                    countryName: storefront.displayName,
                    currencyCode: storefront.currencyCode,
                    productId: app.appId,
                    productName: result.appName.isEmpty ? app.name : result.appName,
                    purchaseKind: .unknown,
                    period: nil,
                    price: nil,
                    source: .signedInAccount,
                    status: .notPublic,
                    message: result.message
                )
            ]
        }
        return result.rows.map { row in
            PriceResultRow(
                countryCode: storefront.countryCode,
                countryName: storefront.displayName,
                currencyCode: row.currencyCode.isEmpty ? storefront.currencyCode : row.currencyCode,
                productId: row.productId.isEmpty ? app.appId : row.productId,
                productName: row.productName.isEmpty ? app.name : row.productName,
                purchaseKind: row.purchaseKind,
                period: row.period,
                price: row.price,
                source: .signedInAccount,
                status: row.price == nil ? .notPublic : .available,
                message: row.message.isEmpty ? result.message : row.message
            )
        }
    }

    private func failureRow(appName: String, storefront: Storefront, message: String) -> PriceResultRow {
        if dataSourceMode == .signedInAccount {
            return PriceResultRow(
                countryCode: storefront.countryCode,
                countryName: storefront.displayName,
                currencyCode: storefront.currencyCode,
                productId: "",
                productName: appName,
                purchaseKind: .unknown,
                period: nil,
                price: nil,
                source: .signedInAccount,
                status: .requestFailed,
                message: message
            )
        }
        return PriceNormalizer.failureRow(
            appName: appName,
            storefront: storefront,
            message: message
        )
    }

    private func primaryLookupCountryCode(fallbackCountryCode: String) -> String {
        if dataSourceMode == .signedInAccount,
           case .storefront(let storefront) = AccountDrivenQueryScope.resolve(selectedAccount: selectedAccount) {
            return storefront.countryCode
        }
        return fallbackCountryCode
    }

    private func publicFallbackCountryCode(from input: String) -> String {
        if let countryCode = AppIDParser.extractCountryCode(from: input) {
            return countryCode
        }
        let region = Locale.current.region?.identifier.uppercased() ?? "US"
        return CountryStorefrontCatalog.all.contains { $0.countryCode == region } ? region : "US"
    }

    func cancelQuery() {
        queryTask?.cancel()
        isQuerying = false
        statusMessage = l10n.queryCancelledShort
    }

    func exportCSV(to url: URL) {
        do {
            try ExportService.csv(rows: resultRows).write(to: url, atomically: true, encoding: .utf8)
            statusMessage = l10n.csvExportComplete
        } catch {
            statusMessage = l10n.csvExportFailed(error.localizedDescription)
        }
    }

    func exportJSON(to url: URL) {
        do {
            try ExportService.jsonData(rows: resultRows).write(to: url)
            statusMessage = l10n.jsonExportComplete
        } catch {
            statusMessage = l10n.jsonExportFailed(error.localizedDescription)
        }
    }

    private func missingPublicMessage(
        selectedApp: AppSearchResult,
        storefrontApp: AppSearchResult,
        connectConfigured: Bool
    ) -> String {
        let base = l10n.publicMissingMessage(connectConfigured: connectConfigured)
        guard selectedApp.name != storefrontApp.name else {
            return base
        }
        return "\(base) \(l10n.storefrontLocalizedNameNote(storefrontApp.name))"
    }

    private func saveAccounts() {
        do {
            try accountStore.save(accountConfiguration)
        } catch {
            statusMessage = l10n.accountSaveFailed(error.localizedDescription)
        }
    }

    private static func defaultAccountStoreDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base.appendingPathComponent("AppStoreIAPClient", isDirectory: true)
    }

    private static func defaultSessionDirectory() -> URL {
        defaultAccountStoreDirectory().appendingPathComponent("sessions", isDirectory: true)
    }

    private static func defaultPastappRuntimeLocation() -> PastappRuntimeLocation? {
        let bundle = Bundle.main
        var roots = [bundle.resourceURL, Bundle.module.resourceURL, bundle.bundleURL].compactMap { $0 }
        #if DEBUG
        roots.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
            .appendingPathComponent("Sources/AppStoreIAPClient/Resources", isDirectory: true))
        #endif
        return PastappRuntimeLocator.locate(resourceRoots: roots)
    }
}
