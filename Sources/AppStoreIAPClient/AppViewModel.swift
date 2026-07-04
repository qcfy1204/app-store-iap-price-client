import Foundation
import SwiftUI
import AppStoreIAPClientCore

@MainActor
final class AppViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var directLookupText = ""
    @Published var searchResults: [AppSearchResult] = []
    @Published var selectedApp: AppSearchResult?
    @Published var resultRows: [PriceResultRow] = []
    @Published var selectedCountryCodes = CountryStorefrontCatalog.defaultSelection
    @Published var statusMessage: String
    @Published var isSearching = false
    @Published var isQuerying = false
    @Published var issuerID = ""
    @Published var keyID = ""
    @Published var privateKeyPath = ""
    @Published var accountConfiguration: AccountConfiguration

    let l10n: L10n
    private let publicClient = AppStorePublicClient()
    private let accountStore: AccountSecureStore
    private var queryTask: Task<Void, Never>?

    init(l10n: L10n = L10n()) {
        self.l10n = l10n
        self.statusMessage = l10n.ready
        self.accountStore = AccountSecureStore(baseDirectory: Self.defaultAccountStoreDirectory())
        self.accountConfiguration = (try? accountStore.load()) ?? AccountConfiguration()
        if let account = accountConfiguration.selectedAccount {
            self.selectedCountryCodes = [account.countryCode]
        }
    }

    var selectedStorefronts: [Storefront] {
        CountryStorefrontCatalog.all.filter { selectedCountryCodes.contains($0.countryCode) }
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
            name: selectedAccount.displayName,
            countryCode: selectedAccount.countryCode,
            status: l10n.displayName(for: selectedAccount.loginStatus)
        )
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

    func searchApps() {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            statusMessage = l10n.enterAppNameToSearch
            return
        }

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
        let countryCode = AppIDParser.extractCountryCode(from: directLookupText) ?? "US"

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
        let countryCode = selectedCountryCodes.first ?? "US"
        let account = AccountProfile(
            displayName: l10n.newAccountDefaultName(existingCount),
            countryCode: countryCode,
            loginStatus: .awaitingUserLogin
        )
        accountConfiguration.upsert(account)
        selectAccount(account.id)
        saveAccounts()
    }

    func updateAccountProfile(_ account: AccountProfile) {
        accountConfiguration.upsert(account)
        if accountConfiguration.selectedAccountID == account.id {
            selectedCountryCodes = [account.countryCode]
        }
        saveAccounts()
    }

    func selectAccount(_ id: UUID?) {
        accountConfiguration.selectAccount(id: id)
        if let account = accountConfiguration.selectedAccount {
            selectedCountryCodes = [account.countryCode]
            statusMessage = l10n.selectedAccountProfile(account.displayName, countryCode: account.countryCode)
        } else {
            statusMessage = l10n.noAccountSelected
        }
        saveAccounts()
    }

    func deleteSelectedAccount() {
        guard let id = accountConfiguration.selectedAccountID else {
            return
        }
        accountConfiguration.deleteAccount(id: id)
        if let account = accountConfiguration.selectedAccount {
            selectedCountryCodes = [account.countryCode]
        }
        saveAccounts()
    }

    func markSelectedAccountAwaitingLogin() {
        guard var account = accountConfiguration.selectedAccount else {
            return
        }
        account.loginStatus = .awaitingUserLogin
        account.lastValidatedAt = nil
        accountConfiguration.upsert(account)
        saveAccounts()
        statusMessage = l10n.accountAwaitingUserLogin(account.displayName)
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
                } catch {
                    resultRows.append(
                        PriceNormalizer.failureRow(
                            appName: app.name,
                            storefront: storefront,
                            message: error.localizedDescription
                        )
                    )
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
}
