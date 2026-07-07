import SwiftUI
import AppKit
import AppStoreIAPClientCore

@main
struct AppStoreIAPClientApp: App {
    @NSApplicationDelegateAdaptor(AppMenuDelegate.self) private var appDelegate
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 520, minHeight: 96)
        }
        .defaultSize(width: 560, height: 96)
        .windowResizability(.contentSize)
        .commands {
            AppStoreIAPClientCommands(viewModel: viewModel)
        }
    }
}

private final class AppMenuDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        pruneMenusSoon()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        pruneMenusSoon()
    }

    private func pruneMenusSoon() {
        DispatchQueue.main.async {
            Self.pruneMenus()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Self.pruneMenus()
        }
    }

    @MainActor
    private static func pruneMenus() {
        guard let mainMenu = NSApp.mainMenu else {
            return
        }
        let hiddenMenuTitles: Set<String> = [
            "File",
            "文件",
            "檔案",
            "Query",
            "查询",
            "查詢"
        ]

        for item in mainMenu.items where hiddenMenuTitles.contains(item.title) {
            mainMenu.removeItem(item)
        }
    }
}

private struct AppStoreIAPClientCommands: Commands {
    @ObservedObject var viewModel: AppViewModel

    var body: some Commands {
        CommandMenu(viewModel.accountMenuTitle) {
            Button(viewModel.l10n.accountManagementMenuItem) {
                viewModel.openAccountManagement()
            }

            Divider()

            Menu(viewModel.l10n.savedAccountsMenuTitle) {
                if viewModel.accountConfiguration.validatedAccounts.isEmpty {
                    Text(viewModel.l10n.noSignedInSavedAccounts)
                } else {
                    Picker(viewModel.l10n.savedAccountsMenuTitle, selection: Binding(
                        get: { viewModel.accountConfiguration.selectedAccountID },
                        set: { viewModel.selectAccount($0) }
                    )) {
                        ForEach(viewModel.accountConfiguration.validatedAccounts) { account in
                            Text("\(account.accountSwitchingTitle) - \(account.countryCode)")
                                .tag(Optional(account.id))
                        }
                    }
                    .pickerStyle(.inline)
                }
            }

            Divider()

            Menu(viewModel.l10n.dataSourceMenuTitle) {
                Picker(viewModel.l10n.dataSourceMenuTitle, selection: $viewModel.dataSourceMode) {
                    Text(viewModel.l10n.publicDataSourceMenuItem)
                        .tag(QueryDataSourceMode.publicStorefront)
                    Text(viewModel.l10n.signedInAccountDataSourceMenuItem)
                        .tag(QueryDataSourceMode.signedInAccount)
                }
                .pickerStyle(.inline)
            }
        }

        CommandMenu(viewModel.l10n.exportMenuTitle) {
            Button(viewModel.l10n.exportCSVButton) {
                saveExport(extensionName: "csv", action: viewModel.exportCSV)
            }
            .disabled(viewModel.resultRows.isEmpty)

            Button(viewModel.l10n.exportJSONButton) {
                saveExport(extensionName: "json", action: viewModel.exportJSON)
            }
            .disabled(viewModel.resultRows.isEmpty)
        }
    }

    private func saveExport(extensionName: String, action: @escaping (URL) -> Void) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = extensionName == "csv" ? [.commaSeparatedText] : [.json]
        panel.nameFieldStringValue = "\(viewModel.l10n.exportBaseFileName).\(extensionName)"
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            action(url)
        }
    }
}
