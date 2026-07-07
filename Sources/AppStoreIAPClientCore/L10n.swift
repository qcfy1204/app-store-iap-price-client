import Foundation

public struct L10n: Equatable, Sendable {
    public enum Language: Equatable, Sendable {
        case english
        case simplifiedChinese
        case traditionalChinese
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
            if normalized.hasPrefix("zh-hant") || normalized == "zh-tw" || normalized == "zh-hk" || normalized == "zh-mo" {
                return .traditionalChinese
            }
            if normalized.hasPrefix("en") {
                return .english
            }
        }
        return .english
    }

    private func text(_ english: String, _ simplifiedChinese: String) -> String {
        switch language {
        case .english:
            return english
        case .simplifiedChinese:
            return simplifiedChinese
        case .traditionalChinese:
            return simplifiedChinese.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? simplifiedChinese
        }
    }

    public var appTitle: String { text("App Store IAP Price Client", "App Store 内购价格查询") }
    public var appAccessibilityTitle: String { text("App Store in-app purchase price client", "App Store 内购价格查询客户端") }
    public var queryInputPlaceholder: String { text("App name, App Store URL, or App ID", "App 名称、App Store 链接或 App ID") }
    public var queryInputLabel: String { text("Query input", "查询输入框") }
    public var queryInputHint: String {
        text(
            "Enter an app name, App Store URL, or numeric App ID.",
            "输入 App 名称、App Store 链接或数字 App ID。"
        )
    }
    public var queryButton: String { text("Query", "查询") }
    public var queryButtonLabel: String { text("Query app price", "查询应用价格") }
    public var queryButtonHint: String {
        text(
            "Queries prices using the selected data source. Signed-in account mode uses only the selected account region.",
            "使用已选择的数据来源查询价格。按已登录账户模式只使用当前账户所属地区。"
        )
    }
    public var accountMenuSignedOut: String { text("Not Signed In", "未登录") }
    public var accountManagementMenuItem: String { text("Manage Accounts...", "管理账户...") }
    public var savedAccountsMenuTitle: String { text("Saved Accounts", "已保存账户") }
    public var noSignedInSavedAccounts: String { text("No signed-in saved accounts", "没有已登录账户") }
    public var dataSourceMenuTitle: String { text("Data Source", "数据来源") }
    public var publicDataSourceMenuItem: String { text("Public Data", "公开数据") }
    public var signedInAccountDataSourceMenuItem: String { text("Signed-in Account", "按已登录账户") }
    public var queryMenuTitle: String { text("Query", "查询") }
    public var exportMenuTitle: String { text("Export", "导出") }
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
    public var openSettingsHint: String { text("Opens account, data source, and accessibility settings.", "打开账户、数据源和辅助功能设置。") }
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
    public var generalSettingsTitle: String { text("General", "通用") }
    public var querySettingsTitle: String { text("Query", "查询") }
    public var accountSettingsTitle: String { text("Accounts", "账户") }
    public var countrySettingsTitle: String { text("Countries", "国家和地区") }
    public var dataSourceSettingsTitle: String { text("Data Sources", "数据源") }
    public var cacheSettingsTitle: String { text("Cache", "缓存") }
    public var exportSettingsTitle: String { text("Export", "导出") }
    public var accessibilitySettingsTitle: String { text("Accessibility", "辅助功能") }
    public var generalSettingsDescription: String {
        text(
            "Current app, account, query status, and local runtime state.",
            "查看当前应用、账户、查询状态和本地运行时状态。"
        )
    }
    public var querySettingsDescription: String {
        text(
            "The query scope follows the selected data source. Signed-in account mode uses only the current account storefront.",
            "查询范围跟随已选择的数据来源。按已登录账户模式只使用当前账户商店地区。"
        )
    }
    public var countrySettingsDescription: String {
        text(
            "Select every country or region that should appear in the price result table.",
            "选择需要出现在价格结果表中的所有国家和地区。"
        )
    }
    public var dataSourceSettingsDescription: String {
        text(
            "Public storefront data is used first. Developer API credentials are optional.",
            "优先使用公开商店数据。开发者 API 凭据为可选项。"
        )
    }
    public var exportSettingsDescription: String {
        text(
            "Export the current price table after a query has produced results.",
            "查询产生结果后，可导出当前价格表。"
        )
    }
    public var accessibilitySettingsDescription: String {
        text(
            "The interface uses native macOS controls, system language, and labelled table data.",
            "界面使用 macOS 原生控件、系统语言和带标签的表格数据。"
        )
    }
    public var selectedAppSettingLabel: String { text("Selected app", "已选应用") }
    public var currentAccountSettingLabel: String { text("Current account", "当前账户") }
    public var statusSettingLabel: String { text("Status", "状态") }
    public var runtimeSettingLabel: String { text("Runtime", "运行时") }
    public var queryScopeSettingLabel: String { text("Scope", "范围") }
    public var publicStorefrontSettingLabel: String { text("Public storefront", "公开商店") }
    public var exportFormatSettingLabel: String { text("Format", "格式") }
    public var exportFileNameSettingLabel: String { text("Default name", "默认名称") }
    public var advancedRuntimeSettingsLabel: String { text("Advanced runtime settings", "高级运行时设置") }
    public var accessibilityVoiceOverLabel: String { text("VoiceOver", "旁白") }
    public var accessibilityVoiceOverDescription: String {
        text(
            "Controls expose labels, hints, values, and table summaries for VoiceOver navigation.",
            "控件提供标签、提示、取值和表格摘要，便于通过旁白导航。"
        )
    }
    public var accessibilityKeyboardLabel: String { text("Keyboard", "键盘") }
    public var accessibilityKeyboardDescription: String {
        text(
            "Search uses Return. Refresh uses Command-R. Cancel uses Command-Period.",
            "搜索使用回车。刷新使用 Command-R。取消使用 Command-句点。"
        )
    }
    public var accessibilityLanguageLabel: String { text("Language", "语言") }
    public var accessibilityLanguageDescription: String {
        text(
            "The app follows the preferred system language and falls back to English.",
            "应用跟随系统首选语言，并在不支持时回退到英文。"
        )
    }
    public var accountSettingsDescription: String {
        text(
            "Add or switch Apple accounts. Passwords are only used for the current login attempt.",
            "添加或切换 Apple 账户。密码仅用于本次登录。"
        )
    }
    public var accountListLabel: String { text("Account profiles", "账户档案") }
    public var addAccountButton: String { text("Add", "添加") }
    public var editButton: String { text("Edit", "编辑") }
    public var deleteAccountButton: String { text("Delete", "删除") }
    public var validateAccountButton: String { text("Validate Local Session", "验证本地会话") }
    public var noAccountSelected: String { text("No account profile selected", "未选择账户档案") }
    public var noSignedInAccountForQuery: String {
        text(
            "Add or validate an account before querying in signed-in account mode.",
            "按已登录账户模式查询前，请先添加或验证账户。"
        )
    }
    public var accountNamePlaceholder: String { text("Account name", "账户名称") }
    public var appleAccountPlaceholder: String { text("Apple ID email or note", "Apple ID 邮箱或备注") }
    public var storefrontIDPlaceholder: String { text("Storefront ID", "Storefront ID") }
    public var accountNameLabel: String { text("Account profile name", "账户档案名称") }
    public var appleAccountLabel: String { text("Apple account identifier", "Apple 账户标识") }
    public var accountCountryLabel: String { text("Account country or region", "账户国家或地区") }
    public var storefrontIDLabel: String { text("Storefront identifier", "Storefront 标识") }
    public var accountStatusLabel: String { text("Login status", "登录状态") }
    public var accountSessionFileLabel: String { text("Local session file", "本地会话文件") }
    public var accountSessionFlowLabel: String { text("Login flow", "登录流程") }
    public var accountSessionUnavailable: String { text("Enter an Apple account identifier to derive the session file.", "输入 Apple 账户标识后会自动生成会话文件名。") }
    public var accountPasswordLabel: String { text("Apple ID password", "Apple ID 密码") }
    public var accountPasswordPlaceholder: String { text("Used only for this login attempt", "仅用于本次登录") }
    public var accountTwoFactorLabel: String { text("Two-factor code", "双重验证码") }
    public var accountTwoFactorPlaceholder: String { text("Enter the 6-digit code after it arrives", "收到验证码后输入 6 位数字") }
    public var accountLoginRuntimeLabel: String { text("Node executable", "Node 可执行文件") }
    public var accountLoginRuntimePlaceholder: String { text("/path/to/node", "/path/to/node") }
    public var accountLoginScriptLabel: String { text("Pastapp helper main.js", "Pastapp helper main.js") }
    public var accountLoginScriptPlaceholder: String { text("/path/to/main.js", "/path/to/main.js") }
    public var accountLoginButton: String { text("Login and Get Code", "登录并获取验证码") }
    public var accountContinueTwoFactorButton: String { text("Continue Verification", "继续验证") }
    public var accountRuntimeStatusLabel: String { text("Runtime status", "运行时状态") }
    public var accountRuntimeReady: String { text("Runtime ready", "运行时已就绪") }
    public var accountRuntimeMissingNode: String {
        text(
            "Pastapp helper is bundled, but Node was not found. Install Node or choose a local node executable.",
            "Pastapp helper 已内置，但未找到 Node。请安装 Node 或选择本地 node 可执行文件。"
        )
    }
    public var accountRuntimeMissingHelper: String {
        text(
            "Pastapp helper was not found in the app resources. Rebuild the app package or choose helper main.js manually.",
            "应用资源中未找到 Pastapp helper。请重新构建应用包，或手动选择 helper main.js。"
        )
    }
    public var accountPastappFlowDescription: String {
        text(
            "Pastapp-compatible local session: GSA SRP, Anisette, 2FA, StoreServices token, and local cookie jar.",
            "Pastapp 兼容本地会话：GSA SRP、Anisette、双重验证、StoreServices 令牌和本地 Cookie Jar。"
        )
    }
    public var accountStorageNote: String {
        text(
            "Profiles are encrypted locally in Application Support. Passwords are not stored.",
            "档案会加密保存在本机 Application Support 中，不保存密码。"
        )
    }
    public func newAccountDefaultName(_ index: Int) -> String { text("Account \(index)", "账户 \(index)") }
    public func selectedAccountProfile(_ name: String, countryCode: String) -> String {
        text("Selected account \(name), storefront \(countryCode).", "已选择账户 \(name)，商店地区 \(countryCode)。")
    }
    public func accountAwaitingUserLogin(_ name: String) -> String {
        text("\(name) is awaiting a local login session.", "\(name) 正在等待本地登录会话。")
    }
    public func accountSessionValidated(_ name: String, storefrontID: String) -> String {
        text("\(name) local session is valid. Storefront \(storefrontID).", "\(name) 的本地会话有效。Storefront \(storefrontID)。")
    }
    public func accountSessionValidationFailed(_ message: String) -> String {
        text("Local session validation failed: \(message)", "本地会话验证失败：\(message)")
    }
    public var accountAppleIDRequired: String { text("Enter an Apple account identifier first.", "请先输入 Apple 账户标识。") }
    public var accountPasswordRequired: String { text("Enter the Apple ID password for this login attempt.", "请输入本次登录使用的 Apple ID 密码。") }
    public var accountLoginRuntimeRequired: String { text("Enter the local Node executable and Pastapp helper main.js paths.", "请输入本地 Node 可执行文件和 Pastapp helper main.js 路径。") }
    public func accountLoginStarted(_ name: String) -> String { text("Logging in \(name).", "正在登录 \(name)。") }
    public func accountNeedsTwoFactor(_ name: String) -> String {
        text(
            "A verification code was sent to \(name)'s trusted devices. Enter the code and continue verification.",
            "\(name) 的验证码已发送至受信任设备。请输入验证码后继续验证。"
        )
    }
    public func accountLoginFailed(_ message: String) -> String { text("Login failed: \(message)", "登录失败：\(message)") }
    public func accountSaveFailed(_ message: String) -> String { text("Account save failed: \(message)", "账户保存失败：\(message)") }
    public func accountSummary(name: String, countryCode: String, status: String) -> String {
        text("\(name), storefront \(countryCode), status \(status)", "\(name)，商店地区 \(countryCode)，状态 \(status)")
    }
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
    public var enterQueryBeforeSearch: String { text("Enter an app name, App Store URL, or App ID.", "请输入 App 名称、App Store 链接或 App ID。") }
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
        case .signedInAccount:
            return text("Signed-in Account", "已登录账户")
        case .appStoreConnect:
            return text("App Store Connect", "App Store Connect")
        }
    }

    public func displayName(for mode: QueryDataSourceMode) -> String {
        switch mode {
        case .publicStorefront:
            return publicDataSourceMenuItem
        case .signedInAccount:
            return signedInAccountDataSourceMenuItem
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

    public func displayName(for status: AccountLoginStatus) -> String {
        switch status {
        case .notConfigured:
            return text("Not Configured", "未配置")
        case .awaitingUserLogin:
            return text("Awaiting User Login", "等待用户登录")
        case .validated:
            return text("Validated", "已验证")
        case .failed:
            return text("Failed", "失败")
        }
    }
}
