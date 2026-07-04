import SwiftUI
import AppStoreIAPClientCore

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .accounts

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(title(for: section), systemImage: symbol(for: section))
                    .labelStyle(.titleAndIcon)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 170)
            .listStyle(.sidebar)
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
                        .lineLimit(2)
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
                sectionHeader(
                    title: viewModel.l10n.accountSettingsTitle,
                    text: viewModel.l10n.accountSettingsDescription
                )

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
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
                )

                HStack {
                    Button(viewModel.l10n.addAccountButton, action: viewModel.addAccountProfile)
                        .buttonStyle(.borderedProminent)
                    Button(viewModel.l10n.deleteAccountButton, action: viewModel.deleteSelectedAccount)
                        .buttonStyle(.bordered)
                        .disabled(viewModel.selectedAccount == nil)
                }
                .controlSize(.regular)
            }
            .frame(width: 290)
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
                emptyAccountState
            }
        }
    }

    private var connectSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: viewModel.l10n.connectTitle,
                text: viewModel.l10n.connectCredentialNote
            )
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
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: title, text: text)

            Spacer()
        }
        .padding()
    }

    private var emptyAccountState: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(viewModel.l10n.noAccountSelected)
                .font(.headline)
            Text(viewModel.l10n.accountSettingsDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Button(viewModel.l10n.addAccountButton, action: viewModel.addAccountProfile)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func sectionHeader(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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

    private func symbol(for section: SettingsSection) -> String {
        switch section {
        case .general:
            return "gearshape"
        case .query:
            return "magnifyingglass"
        case .accounts:
            return "person.2"
        case .countries:
            return "globe"
        case .dataSources:
            return "server.rack"
        case .appStoreConnect:
            return "key"
        case .cache:
            return "internaldrive"
        case .export:
            return "square.and.arrow.up"
        case .accessibility:
            return "accessibility"
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
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(account.displayName.isEmpty ? l10n.accountSettingsTitle : account.displayName)
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text(l10n.accountSummary(
                    name: account.displayName.isEmpty ? l10n.noAccountSelected : account.displayName,
                    countryCode: account.countryCode,
                    status: l10n.displayName(for: account.loginStatus)
                ))
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                    GridRow {
                        Text(l10n.accountNameLabel)
                            .foregroundStyle(.secondary)
                        TextField(l10n.accountNamePlaceholder, text: savingBinding(\.displayName))
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel(l10n.accountNameLabel)
                    }

                    GridRow {
                        Text(l10n.appleAccountLabel)
                            .foregroundStyle(.secondary)
                        TextField(l10n.appleAccountPlaceholder, text: savingBinding(\.appleAccount))
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel(l10n.appleAccountLabel)
                    }

                    GridRow {
                        Text(l10n.accountCountryLabel)
                            .foregroundStyle(.secondary)
                        Picker(l10n.accountCountryLabel, selection: savingBinding(\.countryCode)) {
                            ForEach(CountryStorefrontCatalog.all) { storefront in
                                Text("\(storefront.displayName) (\(storefront.countryCode))")
                                    .tag(storefront.countryCode)
                            }
                        }
                        .labelsHidden()
                        .accessibilityLabel(l10n.accountCountryLabel)
                    }

                    GridRow {
                        Text(l10n.storefrontIDLabel)
                            .foregroundStyle(.secondary)
                        TextField(l10n.storefrontIDPlaceholder, text: optionalSavingBinding(\.storefrontID))
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel(l10n.storefrontIDLabel)
                    }

                    GridRow {
                        Text(l10n.accountStatusLabel)
                            .foregroundStyle(.secondary)
                        Text(l10n.displayName(for: account.loginStatus))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
            .padding(16)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
            )

            Button(l10n.validateAccountButton, action: onMarkPending)
                .buttonStyle(.bordered)
                .accessibilityLabel(l10n.validateAccountButton)

            Spacer()
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
