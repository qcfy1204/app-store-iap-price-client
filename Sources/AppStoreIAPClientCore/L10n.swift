import Foundation

public struct L10n: Equatable, Sendable {
    public enum Language: Equatable, Sendable {
        case english
        case simplifiedChinese
    }

    public let language: Language

    public init(preferredLanguages: [String] = Locale.preferredLanguages) {
        self.language = Self.resolveLanguage(preferredLanguages: preferredLanguages)
    }

    public static func resolveLanguage(preferredLanguages: [String]) -> Language {
        for language in preferredLanguages {
            let normalized = language.lowercased()
            if normalized.hasPrefix("zh-hans") || normalized == "zh-cn" || normalized == "zh-sg" {
                return .simplifiedChinese
            }
            if normalized.hasPrefix("en") {
                return .english
            }
        }
        return .english
    }

    private func text(_ english: String, _ simplifiedChinese: String) -> String {
        language == .simplifiedChinese ? simplifiedChinese : english
    }

    public var appTitle: String { text("App Store IAP Price Client", "App Store 内购价格查询") }
    public var appAccessibilityTitle: String { text("App Store in-app purchase price client", "App Store 内购价格查询客户端") }
    public var searchTitle: String { text("Search", "搜索") }
    public var appNamePlaceholder: String { text("App name", "App 名称") }
    public var appNameSearchFieldLabel: String { text("App name search field", "App 名称搜索输入框") }
    public var appNameSearchFieldHint: String {
        text(
            "Enter an App Store app name, then press Search. The best match is selected automatically and prices are queried for all selected countries.",
            "输入 App Store 应用名称，然后按搜索。系统会自动选择最匹配的应用并查询所有已选国家和地区。"
        )
    }
    public var searchButton: String { text("Search", "搜索") }
    public var searchAppsLabel: String { text("Search apps", "搜索应用") }
    public var searchAppsHint: String {
        text(
            "Searches App Store apps by name and automatically queries prices for the selected countries.",
            "按名称搜索 App Store 应用，并自动查询所选国家和地区的价格。"
        )
    }
    public var directLookupPlaceholder: String { text("App Store URL or App ID", "App Store 链接或 App ID") }
    public var directLookupFieldLabel: String { text("Direct lookup field", "直接查询输入框") }
    public var directLookupFieldHint: String { text("Enter an App Store URL or numeric App ID.", "输入 App Store 链接或数字 App ID。") }
    public var lookUpButton: String { text("Look Up", "查询") }
    public var lookUpLabel: String { text("Look up app by URL or ID", "通过链接或 ID 查询应用") }
    public var lookUpHint: String { text("Finds one app from the entered URL or App ID.", "根据输入的链接或 App ID 查找一个应用。") }
    public var selectedAppTitle: String { text("Selected App", "已选择应用") }
    public var selectedAppLabel: String { text("Selected app", "已选择应用") }
    public var noAppSelected: String { text("No app selected", "未选择应用") }
    public var developer: String { text("developer", "开发者") }
    public var appID: String { text("App ID", "App ID") }
    public var searchResultsTitle: String { text("Search Results", "搜索结果") }
    public var appSearchResultsLabel: String { text("App search results", "应用搜索结果") }
    public var selectAppHint: String { text("Selects this app and starts the price lookup.", "选择此应用并开始价格查询。") }
    public var countriesTitle: String { text("Countries", "国家和地区") }
    public var allButton: String { text("All", "全选") }
    public var selectAllCountriesLabel: String { text("Select all countries", "选择所有国家和地区") }
    public var majorButton: String { text("Major", "常用") }
    public var selectMajorCountriesLabel: String { text("Select major countries", "选择常用国家和地区") }
    public var selectMajorCountriesHint: String {
        text(
            "Selects United States, China Mainland, Japan, United Kingdom, Canada, Australia, Germany, France, South Korea, and Hong Kong.",
            "选择美国、中国大陆、日本、英国、加拿大、澳大利亚、德国、法国、韩国和香港。"
        )
    }
    public var clearButton: String { text("Clear", "清除") }
    public var clearSelectedCountriesLabel: String { text("Clear selected countries", "清除已选国家和地区") }
    public var customCountriesButton: String { text("Custom", "自定义") }
    public var customCountriesLabel: String { text("Customize selected countries", "自定义已选国家和地区") }
    public var customCountriesHint: String { text("Opens the country selection list.", "打开国家和地区选择列表。") }
    public var selectedCountryCountLabel: String { text("Selected country count", "已选国家和地区数量") }
    public var countrySelectionListLabel: String { text("Country selection list", "国家和地区选择列表") }
    public var countryToggleHint: String { text("Includes or excludes this country from the price query.", "在价格查询中包含或排除此国家或地区。") }
    public var startQueryButton: String { text("Refresh", "刷新") }
    public var startQueryLabel: String { text("Refresh price query", "刷新价格查询") }
    public var startQueryHint: String { text("Refreshes selected countries for the selected app.", "刷新所选应用在所选国家和地区的价格。") }
    public var cancelButton: String { text("Cancel", "取消") }
    public var cancelQueryLabel: String { text("Cancel price query", "取消价格查询") }
    public var settingsButton: String { text("Settings", "设置") }
    public var openSettingsLabel: String { text("Open settings", "打开设置") }
    public var openSettingsHint: String { text("Opens optional App Store Connect credential settings.", "打开可选的 App Store Connect 凭据设置。") }
    public var exportCSVButton: String { text("Export CSV", "导出 CSV") }
    public var exportCSVHint: String { text("Saves the visible query results to a CSV file.", "将当前查询结果保存为 CSV 文件。") }
    public var exportJSONButton: String { text("Export JSON", "导出 JSON") }
    public var exportJSONHint: String { text("Saves the visible query results to a JSON file.", "将当前查询结果保存为 JSON 文件。") }
    public var exportBaseFileName: String { text("app-store-iap-prices", "AppStore内购价格") }
    public var queryStatusLabel: String { text("Query status", "查询状态") }
    public var querySummaryLabel: String { text("Query summary", "查询摘要") }
    public var completedSummaryLabel: String { text("Checked", "已查") }
    public var availableSummaryLabel: String { text("Available", "可用") }
    public var missingSummaryLabel: String { text("Missing", "缺失") }
    public var failedSummaryLabel: String { text("Failed", "失败") }
    public var countryColumn: String { text("Country", "国家和地区") }
    public var currencyColumn: String { text("Currency", "货币") }
    public var productColumn: String { text("Product", "产品") }
    public var periodColumn: String { text("Period", "周期") }
    public var priceColumn: String { text("Price", "价格") }
    public var sourceColumn: String { text("Source", "来源") }
    public var statusColumn: String { text("Status", "状态") }
    public var messageColumn: String { text("Message", "说明") }
    public var unknown: String { text("Unknown", "未知") }
    public var notPublic: String { text("Not public", "未公开") }
    public var resultTableLabel: String { text("In-app purchase price result table", "内购价格结果表") }
    public var publicDataLimitation: String {
        text(
            "Public data may not expose detailed third-party in-app purchase prices. Missing rows are marked as not public instead of treated as free.",
            "公开数据可能不会暴露第三方应用的详细内购价格。缺失结果会标记为未公开，不会被当作免费。"
        )
    }
    public var publicDataLimitationLabel: String { text("Public data limitation", "公开数据限制说明") }
    public var connectTitle: String { text("App Store Connect", "App Store Connect") }
    public var connectCredentialNote: String {
        text(
            "Credentials are optional and only apply to apps your Apple developer account can access.",
            "凭据是可选项，只适用于你的 Apple 开发者账号有权限访问的应用。"
        )
    }
    public var connectCredentialNoteLabel: String { text("App Store Connect credential note", "App Store Connect 凭据说明") }
    public var issuerIDPlaceholder: String { text("Issuer ID", "Issuer ID") }
    public var issuerIDLabel: String { text("App Store Connect issuer ID", "App Store Connect Issuer ID") }
    public var issuerIDHint: String { text("Enter the issuer ID from App Store Connect API access.", "输入 App Store Connect API 访问中的 Issuer ID。") }
    public var keyIDPlaceholder: String { text("Key ID", "Key ID") }
    public var keyIDLabel: String { text("App Store Connect key ID", "App Store Connect Key ID") }
    public var keyIDHint: String { text("Enter the key ID for the App Store Connect API key.", "输入 App Store Connect API 密钥的 Key ID。") }
    public var privateKeyPathPlaceholder: String { text("Private key file path", "私钥文件路径") }
    public var privateKeyPathLabel: String { text("App Store Connect private key file path", "App Store Connect 私钥文件路径") }
    public var privateKeyPathHint: String { text("Enter the local path to the private key p8 file.", "输入本地 p8 私钥文件路径。") }
    public var doneButton: String { text("Done", "完成") }
    public var closeSettingsLabel: String { text("Close settings", "关闭设置") }
    public var settingsLabel: String { text("App Store Connect settings", "App Store Connect 设置") }
    public var ready: String { text("Ready", "就绪") }
    public var enterAppNameToSearch: String { text("Enter an app name to search.", "请输入应用名称再搜索。") }
    public func searchingFor(_ term: String) -> String { text("Searching for \(term).", "正在搜索 \(term)。") }
    public func foundApps(_ count: Int) -> String { text("Found \(count) apps.", "找到 \(count) 个应用。") }
    public func searchFailed(_ message: String) -> String { text("Search failed: \(message)", "搜索失败：\(message)") }
    public var enterValidAppID: String { text("Enter a valid App Store URL or numeric App ID.", "请输入有效的 App Store 链接或数字 App ID。") }
    public func lookingUpApp(_ appID: String) -> String { text("Looking up app \(appID).", "正在查询应用 \(appID)。") }
    public func selectedApp(_ name: String) -> String { text("Selected \(name).", "已选择 \(name)。") }
    public func noAppFound(_ appID: String, countryCode: String) -> String {
        text("No app found for \(appID) in storefront \(countryCode).", "在 \(countryCode) 商店地区未找到 App ID \(appID) 对应的应用。")
    }
    public func lookupFailed(_ message: String) -> String { text("Lookup failed: \(message)", "查询失败：\(message)") }
    public var allCountriesSelected: String { text("All countries selected.", "已选择所有国家和地区。") }
    public var majorCountriesSelected: String { text("Major countries selected.", "已选择常用国家和地区。") }
    public var countrySelectionCleared: String { text("Country selection cleared.", "已清除国家和地区选择。") }
    public var selectAppBeforeQuery: String { text("Select or look up an app before querying prices.", "请先选择或查询一个应用，再查询价格。") }
    public var selectCountryBeforeQuery: String { text("Select at least one country before querying prices.", "请至少选择一个国家或地区，再查询价格。") }
    public func queryStarted(_ name: String) -> String { text("Query started for \(name).", "已开始查询 \(name)。") }
    public var appNotFoundInStorefront: String { text("The app was not found in this storefront.", "此商店地区未找到该应用。") }
    public func queriedCountries(_ completed: Int, _ total: Int) -> String { text("Queried \(completed) of \(total) countries.", "已查询 \(completed) / \(total) 个国家和地区。") }
    public func queryCancelled(_ completed: Int) -> String { text("Query cancelled. \(completed) countries checked.", "查询已取消。已检查 \(completed) 个国家和地区。") }
    public func queryComplete(_ completed: Int) -> String { text("Query complete. \(completed) countries checked.", "查询完成。已检查 \(completed) 个国家和地区。") }
    public var queryCancelledShort: String { text("Query cancelled.", "查询已取消。") }
    public var csvExportComplete: String { text("CSV export complete.", "CSV 导出完成。") }
    public func csvExportFailed(_ message: String) -> String { text("CSV export failed: \(message)", "CSV 导出失败：\(message)") }
    public var jsonExportComplete: String { text("JSON export complete.", "JSON 导出完成。") }
    public func jsonExportFailed(_ message: String) -> String { text("JSON export failed: \(message)", "JSON 导出失败：\(message)") }
    public func selectedCountryCount(_ count: Int) -> String { text("\(count) countries selected", "已选择 \(count) 个国家和地区") }
    public func selectedAppSummary(name: String, developer: String, appID: String) -> String {
        text("\(name), developer \(developer), App ID \(appID)", "\(name)，开发者 \(developer)，App ID \(appID)")
    }
    public func querySummary(completed: Int, total: Int, available: Int, missing: Int, failed: Int) -> String {
        text(
            "Countries checked \(completed) of \(total). Available \(available). Missing \(missing). Failed \(failed).",
            "已检查 \(completed) / \(total) 个国家和地区。可用 \(available)。缺失 \(missing)。失败 \(failed)。"
        )
    }
    public func appResultLabel(name: String, developer: String, appID: String) -> String {
        text("\(name), developer \(developer), App ID \(appID)", "\(name)，开发者 \(developer)，App ID \(appID)")
    }
    public func countryToggleLabel(name: String, code: String, currency: String) -> String {
        text("\(name), \(code), \(currency)", "\(name)，\(code)，\(currency)")
    }
    public func publicMissingMessage(connectConfigured: Bool) -> String {
        if connectConfigured {
            return text(
                "Public App Store data did not expose detailed IAP prices. App Store Connect credentials are configured but Connect price fetching is not enabled in this build.",
                "公开 App Store 数据未暴露详细内购价格。已配置 App Store Connect 凭据，但此版本尚未启用 Connect 价格抓取。"
            )
        }
        return text(
            "Public App Store data did not expose detailed IAP prices for this storefront.",
            "公开 App Store 数据未暴露此商店地区的详细内购价格。"
        )
    }

    public func storefrontLocalizedNameNote(_ name: String) -> String {
        text("Storefront localized app name: \(name).", "此商店地区的本地化应用名称：\(name)。")
    }

    public func displayName(for source: PriceSource) -> String {
        switch source {
        case .publicStorefront:
            return text("Public Storefront", "公开商店")
        case .appStoreConnect:
            return text("App Store Connect", "App Store Connect")
        }
    }

    public func displayName(for status: PriceStatus) -> String {
        switch status {
        case .available:
            return text("Available", "可用")
        case .notPublic:
            return text("Not Public", "未公开")
        case .notAvailableInStorefront:
            return text("Not Available", "不可用")
        case .requestFailed:
            return text("Request Failed", "请求失败")
        case .connectUnauthorized:
            return text("Connect Unauthorized", "Connect 未授权")
        }
    }
}
