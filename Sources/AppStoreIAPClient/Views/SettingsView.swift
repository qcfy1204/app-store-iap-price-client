import SwiftUI
import AppStoreIAPClientCore

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .accounts

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Text(title(for: section))
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 170)
            .accessibilityLabel(viewModel.l10n.settingsLabel)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Divider()

                HStack {
                    Text(viewModel.l10n.accountStorageNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(viewModel.l10n.doneButton) {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .accessibilityLabel(viewModel.l10n.closeSettingsLabel)
                }
                .padding()
            }
        }
        .accessibilityLabel(viewModel.l10n.settingsLabel)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .general:
            placeholderSection(title: viewModel.l10n.generalSettingsTitle, text: viewModel.l10n.appTitle)
        case .query:
            placeholderSection(title: viewModel.l10n.querySettingsTitle, text: viewModel.selectedAccountSummary)
        case .accounts:
            accountsSection
        case .countries:
            placeholderSection(title: viewModel.l10n.countrySettingsTitle, text: viewModel.l10n.selectedCountryCount(viewModel.selectedCountryCodes.count))
        case .dataSources:
            placeholderSection(title: viewModel.l10n.dataSourceSettingsTitle, text: viewModel.l10n.publicDataLimitation)
        case .appStoreConnect:
            connectSection
        case .cache:
            placeholderSection(title: viewModel.l10n.cacheSettingsTitle, text: viewModel.l10n.accountStorageNote)
        case .export:
            placeholderSection(title: viewModel.l10n.exportSettingsTitle, text: viewModel.l10n.exportBaseFileName)
        case .accessibility:
            placeholderSection(title: viewModel.l10n.accessibilitySettingsTitle, text: viewModel.l10n.appAccessibilityTitle)
        }
    }

    private var accountsSection: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.l10n.accountSettingsTitle)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.l10n.accountSettingsDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                List(selection: Binding(
                    get: { viewModel.accountConfiguration.selectedAccountID },
                    set: { viewModel.selectAccount($0) }
                )) {
                    ForEach(viewModel.accountConfiguration.accounts) { account in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.displayName)
                                .lineLimit(1)
                            Text("\(account.countryCode) - \(viewModel.l10n.displayName(for: account.loginStatus))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(Optional(account.id))
                        .accessibilityLabel(viewModel.l10n.accountSummary(
                            name: account.displayName,
                            countryCode: account.countryCode,
                            status: viewModel.l10n.displayName(for: account.loginStatus)
                        ))
                    }
                }
                .accessibilityLabel(viewModel.l10n.accountListLabel)

                HStack {
                    Button(viewModel.l10n.addAccountButton, action: viewModel.addAccountProfile)
                    Button(viewModel.l10n.deleteAccountButton, action: viewModel.deleteSelectedAccount)
                        .disabled(viewModel.selectedAccount == nil)
                }
            }
            .frame(width: 260)
            .padding()

            Divider()

            if let accountBinding {
                AccountEditorView(
                    account: accountBinding,
                    l10n: viewModel.l10n,
                    onSave: viewModel.updateAccountProfile,
                    onMarkPending: viewModel.markSelectedAccountAwaitingLogin
                )
                .padding()
            } else {
                placeholderSection(title: viewModel.l10n.accountSettingsTitle, text: viewModel.l10n.noAccountSelected)
            }
        }
    }

    private var connectSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.l10n.connectTitle)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text(viewModel.l10n.connectCredentialNote)
                .foregroundStyle(.secondary)
                .accessibilityLabel(viewModel.l10n.connectCredentialNoteLabel)

            Form {
                TextField(viewModel.l10n.issuerIDPlaceholder, text: $viewModel.issuerID)
                    .accessibilityLabel(viewModel.l10n.issuerIDLabel)
                    .accessibilityHint(viewModel.l10n.issuerIDHint)

                TextField(viewModel.l10n.keyIDPlaceholder, text: $viewModel.keyID)
                    .accessibilityLabel(viewModel.l10n.keyIDLabel)
                    .accessibilityHint(viewModel.l10n.keyIDHint)

                TextField(viewModel.l10n.privateKeyPathPlaceholder, text: $viewModel.privateKeyPath)
                    .accessibilityLabel(viewModel.l10n.privateKeyPathLabel)
                    .accessibilityHint(viewModel.l10n.privateKeyPathHint)
            }
        }
        .padding()
    }

    private func placeholderSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(text)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var accountBinding: Binding<AccountProfile>? {
        guard let id = viewModel.accountConfiguration.selectedAccountID else {
            return nil
        }
        return Binding(
            get: {
                viewModel.accountConfiguration.accounts.first { $0.id == id }
                    ?? AccountProfile(id: id, displayName: "", countryCode: "US")
            },
            set: { viewModel.updateAccountProfile($0) }
        )
    }

    private func title(for section: SettingsSection) -> String {
        switch section {
        case .general:
            return viewModel.l10n.generalSettingsTitle
        case .query:
            return viewModel.l10n.querySettingsTitle
        case .accounts:
            return viewModel.l10n.accountSettingsTitle
        case .countries:
            return viewModel.l10n.countrySettingsTitle
        case .dataSources:
            return viewModel.l10n.dataSourceSettingsTitle
        case .appStoreConnect:
            return viewModel.l10n.connectTitle
        case .cache:
            return viewModel.l10n.cacheSettingsTitle
        case .export:
            return viewModel.l10n.exportSettingsTitle
        case .accessibility:
            return viewModel.l10n.accessibilitySettingsTitle
        }
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case query
    case accounts
    case countries
    case dataSources
    case appStoreConnect
    case cache
    case export
    case accessibility

    var id: String { rawValue }
}

private struct AccountEditorView: View {
    @Binding var account: AccountProfile
    let l10n: L10n
    let onSave: (AccountProfile) -> Void
    let onMarkPending: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(account.displayName.isEmpty ? l10n.accountSettingsTitle : account.displayName)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Form {
                TextField(l10n.accountNamePlaceholder, text: savingBinding(\.displayName))
                    .accessibilityLabel(l10n.accountNameLabel)

                TextField(l10n.appleAccountPlaceholder, text: savingBinding(\.appleAccount))
                    .accessibilityLabel(l10n.appleAccountLabel)

                Picker(l10n.accountCountryLabel, selection: savingBinding(\.countryCode)) {
                    ForEach(CountryStorefrontCatalog.all) { storefront in
                        Text("\(storefront.displayName) (\(storefront.countryCode))")
                            .tag(storefront.countryCode)
                    }
                }
                .accessibilityLabel(l10n.accountCountryLabel)

                TextField(l10n.storefrontIDPlaceholder, text: optionalSavingBinding(\.storefrontID))
                    .accessibilityLabel(l10n.storefrontIDLabel)

                HStack {
                    Text(l10n.accountStatusLabel)
                    Spacer()
                    Text(l10n.displayName(for: account.loginStatus))
                        .foregroundStyle(.secondary)
                }
            }

            Button(l10n.validateAccountButton, action: onMarkPending)
                .accessibilityLabel(l10n.validateAccountButton)
        }
    }

    private func savingBinding(_ keyPath: WritableKeyPath<AccountProfile, String>) -> Binding<String> {
        Binding(
            get: { account[keyPath: keyPath] },
            set: {
                account[keyPath: keyPath] = keyPath == \AccountProfile.countryCode ? $0.uppercased() : $0
                onSave(account)
            }
        )
    }

    private func optionalSavingBinding(_ keyPath: WritableKeyPath<AccountProfile, String?>) -> Binding<String> {
        Binding(
            get: { account[keyPath: keyPath] ?? "" },
            set: {
                account[keyPath: keyPath] = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0
                onSave(account)
            }
        )
    }
}
