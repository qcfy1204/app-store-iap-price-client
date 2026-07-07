import SwiftUI
import AppKit
import AppStoreIAPClientCore

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .accounts
    @State private var accountMode: AccountManagementMode = .list

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(title(for: section), systemImage: symbol(for: section))
                    .labelStyle(.titleAndIcon)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 180, max: 180)
            .listStyle(.sidebar)
            .accessibilityLabel(viewModel.l10n.settingsLabel)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Divider()

                HStack(spacing: 12) {
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
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
        }
        .frame(idealWidth: 770, idealHeight: 660)
        .onChange(of: viewModel.accountLoginCompletion) {
            accountMode = .list
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .general:
            settingsPage(title: viewModel.l10n.generalSettingsTitle, description: viewModel.l10n.generalSettingsDescription) {
                settingsGrid {
                    SettingsRow(title: viewModel.l10n.selectedAppSettingLabel) {
                        Text(viewModel.selectedAppSummary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .accessibilityLabel(viewModel.l10n.selectedAppLabel)
                    }
                    SettingsRow(title: viewModel.l10n.currentAccountSettingLabel) {
                        Text(viewModel.selectedAccountSummary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                    SettingsRow(title: viewModel.l10n.statusSettingLabel) {
                        Text(viewModel.statusMessage)
                            .lineLimit(2)
                    }
                    SettingsRow(title: viewModel.l10n.runtimeSettingLabel) {
                        Text(viewModel.accountRuntimeStatus)
                            .lineLimit(3)
                    }
                }
            }
        case .accounts:
            accountsSection
        case .query:
            settingsPage(title: viewModel.l10n.querySettingsTitle, description: viewModel.l10n.querySettingsDescription) {
                settingsGrid {
                    SettingsRow(title: viewModel.l10n.dataSourceMenuTitle) {
                        Text(viewModel.l10n.displayName(for: viewModel.dataSourceMode))
                    }
                    SettingsRow(title: viewModel.l10n.selectedAppSettingLabel) {
                        Text(viewModel.selectedAppSummary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                }
            }
        case .dataSources:
            dataSourcesSection
        case .export:
            exportSection
        case .accessibility:
            accessibilitySection
        }
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: viewModel.l10n.accountSettingsTitle,
                text: viewModel.l10n.accountSettingsDescription
            )

            switch accountMode {
            case .list:
                compactAccountList
            case .editor:
                if let accountBinding {
                    AccountEditorView(
                        account: accountBinding,
                        password: $viewModel.accountPassword,
                        twoFactorCode: $viewModel.accountTwoFactorCode,
                        isLoggingIn: viewModel.isLoggingIn,
                        needsTwoFactor: viewModel.selectedAccountNeedsTwoFactor,
                        statusMessage: viewModel.statusMessage,
                        l10n: viewModel.l10n,
                        loginButtonTitle: viewModel.accountLoginButtonTitle,
                        onSave: viewModel.updateAccountProfile,
                        onLogin: viewModel.loginSelectedAccount
                    )
                } else {
                    emptyAccountState
                }
            }
        }
        .padding(18)
    }

    private var compactAccountList: some View {
        VStack(alignment: .leading, spacing: 12) {
            List(selection: Binding(
                get: { viewModel.accountConfiguration.selectedAccountID },
                set: { viewModel.selectAccount($0) }
            )) {
                ForEach(viewModel.accountConfiguration.accounts) { account in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.accountSwitchingTitle)
                            .lineLimit(1)
                        Text("\(account.countryCode) - \(viewModel.l10n.displayName(for: account.loginStatus))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(Optional(account.id))
                    .accessibilityLabel(viewModel.l10n.accountSummary(
                        name: account.accountSwitchingTitle,
                        countryCode: account.countryCode,
                        status: viewModel.l10n.displayName(for: account.loginStatus)
                    ))
                }
            }
            .frame(minHeight: 260)
            .accessibilityLabel(viewModel.l10n.accountListLabel)

            HStack(spacing: 8) {
                Button(viewModel.l10n.addAccountButton) {
                    viewModel.addAccountProfile()
                    accountMode = .editor
                }
                .buttonStyle(.borderedProminent)

                Button(viewModel.l10n.editButton) {
                    accountMode = .editor
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedAccount == nil)

                Button(viewModel.l10n.deleteAccountButton) {
                    viewModel.deleteSelectedAccount()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.selectedAccount == nil)
            }
        }
        .frame(maxWidth: 520, alignment: .leading)
    }

    private var dataSourcesSection: some View {
        settingsPage(title: viewModel.l10n.dataSourceSettingsTitle, description: viewModel.l10n.dataSourceSettingsDescription) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.l10n.publicStorefrontSettingLabel)
                        .foregroundStyle(.secondary)
                    Text(viewModel.l10n.publicDataLimitation)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(viewModel.l10n.publicDataLimitationLabel)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.l10n.connectTitle)
                        .foregroundStyle(.secondary)
                    Text(viewModel.l10n.connectCredentialNote)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(viewModel.l10n.connectCredentialNoteLabel)
                }

                LabeledField(
                    title: viewModel.l10n.issuerIDLabel,
                    placeholder: viewModel.l10n.issuerIDPlaceholder,
                    text: $viewModel.issuerID,
                    hint: viewModel.l10n.issuerIDHint
                )

                LabeledField(
                    title: viewModel.l10n.keyIDLabel,
                    placeholder: viewModel.l10n.keyIDPlaceholder,
                    text: $viewModel.keyID,
                    hint: viewModel.l10n.keyIDHint
                )

                LabeledField(
                    title: viewModel.l10n.privateKeyPathLabel,
                    placeholder: viewModel.l10n.privateKeyPathPlaceholder,
                    text: $viewModel.privateKeyPath,
                    hint: viewModel.l10n.privateKeyPathHint
                )
            }
            .frame(width: 520, alignment: .leading)
        }
    }

    private var exportSection: some View {
        settingsPage(title: viewModel.l10n.exportSettingsTitle, description: viewModel.l10n.exportSettingsDescription) {
            settingsGrid {
                SettingsRow(title: viewModel.l10n.exportFormatSettingLabel) {
                    HStack(spacing: 8) {
                        Button(viewModel.l10n.exportCSVButton) {
                            saveExport(extensionName: "csv", action: viewModel.exportCSV)
                        }
                        .disabled(viewModel.resultRows.isEmpty)
                        .accessibilityHint(viewModel.l10n.exportCSVHint)

                        Button(viewModel.l10n.exportJSONButton) {
                            saveExport(extensionName: "json", action: viewModel.exportJSON)
                        }
                        .disabled(viewModel.resultRows.isEmpty)
                        .accessibilityHint(viewModel.l10n.exportJSONHint)
                    }
                    .buttonStyle(.bordered)
                }
                SettingsRow(title: viewModel.l10n.resultTableLabel) {
                    Text(viewModel.querySummaryText)
                }
                SettingsRow(title: viewModel.l10n.exportFileNameSettingLabel) {
                    Text(viewModel.l10n.exportBaseFileName)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var accessibilitySection: some View {
        settingsPage(title: viewModel.l10n.accessibilitySettingsTitle, description: viewModel.l10n.accessibilitySettingsDescription) {
            settingsGrid {
                SettingsRow(title: viewModel.l10n.accessibilityVoiceOverLabel) {
                    Text(viewModel.l10n.accessibilityVoiceOverDescription)
                        .fixedSize(horizontal: false, vertical: true)
                }
                SettingsRow(title: viewModel.l10n.accessibilityKeyboardLabel) {
                    Text(viewModel.l10n.accessibilityKeyboardDescription)
                        .fixedSize(horizontal: false, vertical: true)
                }
                SettingsRow(title: viewModel.l10n.accessibilityLanguageLabel) {
                    Text(viewModel.l10n.accessibilityLanguageDescription)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var emptyAccountState: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(viewModel.l10n.noAccountSelected)
                .font(.headline)
            Text(viewModel.l10n.accountSettingsDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button(viewModel.l10n.addAccountButton, action: viewModel.addAccountProfile)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(18)
    }

    private func settingsPage<Content: View>(
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: title, text: description)
            content()
            Spacer(minLength: 0)
        }
        .frame(maxWidth: 560, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .padding(.top, 28)
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

    private func settingsGrid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
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
        case .accounts:
            return viewModel.l10n.accountSettingsTitle
        case .query:
            return viewModel.l10n.querySettingsTitle
        case .dataSources:
            return viewModel.l10n.dataSourceSettingsTitle
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
        case .accounts:
            return "person.2"
        case .query:
            return "magnifyingglass"
        case .dataSources:
            return "server.rack"
        case .export:
            return "square.and.arrow.up"
        case .accessibility:
            return "accessibility"
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

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case accounts
    case query
    case dataSources
    case export
    case accessibility

    var id: String { rawValue }
}

private enum AccountManagementMode {
    case list
    case editor
}

private struct SettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 148, alignment: .leading)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct LabeledField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let hint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 360)
                .accessibilityLabel(title)
                .accessibilityHint(hint)
        }
    }
}

private struct AccountEditorView: View {
    @Binding var account: AccountProfile
    @Binding var password: String
    @Binding var twoFactorCode: String
    let isLoggingIn: Bool
    let needsTwoFactor: Bool
    let statusMessage: String
    let l10n: L10n
    let loginButtonTitle: String
    let onSave: (AccountProfile) -> Void
    let onLogin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(account.accountSwitchingTitle)
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(alignment: .leading, spacing: 10) {
                SettingsRow(title: l10n.appleAccountLabel) {
                    TextField(l10n.appleAccountPlaceholder, text: savingBinding(\.appleAccount))
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(l10n.appleAccountLabel)
                }

                SettingsRow(title: l10n.accountPasswordLabel) {
                    SecureField(l10n.accountPasswordPlaceholder, text: $password)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(l10n.accountPasswordLabel)
                }

                if needsTwoFactor {
                    SettingsRow(title: l10n.accountTwoFactorLabel) {
                        TextField(l10n.accountTwoFactorPlaceholder, text: $twoFactorCode)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel(l10n.accountTwoFactorLabel)
                    }
                }
            }

            Button(loginButtonTitle, action: onLogin)
                .buttonStyle(.borderedProminent)
                .disabled(isLoggingIn)
                .accessibilityLabel(loginButtonTitle)

            Text(statusMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(l10n.statusSettingLabel)
                .accessibilityValue(statusMessage)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: 420, alignment: .leading)
    }

    private func savingBinding(_ keyPath: WritableKeyPath<AccountProfile, String>) -> Binding<String> {
        Binding(
            get: { account[keyPath: keyPath] },
            set: {
                account[keyPath: keyPath] = keyPath == \AccountProfile.countryCode ? $0.uppercased() : $0
                if keyPath == \AccountProfile.appleAccount,
                   account.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   account.displayName.hasPrefix(l10n.newAccountDefaultName(1).dropLast().description) {
                    account.displayName = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                onSave(account)
            }
        )
    }
}
