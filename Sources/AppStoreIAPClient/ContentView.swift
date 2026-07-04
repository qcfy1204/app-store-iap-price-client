import SwiftUI
import AppKit
import AppStoreIAPClientCore

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var isShowingSettings = false
    @State private var isShowingCountryEditor = false

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 10) {
                queryBar
                searchResultsBar
                scopeBar
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            PriceMatrixView(viewModel: viewModel)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .frame(minWidth: 980, minHeight: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityLabel(viewModel.l10n.appAccessibilityTitle)
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(viewModel: viewModel)
                .frame(minWidth: 940, minHeight: 620)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.l10n.appTitle)
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.selectedAppSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .accessibilityLabel(viewModel.l10n.selectedAppLabel)
                    .accessibilityValue(viewModel.selectedAppSummary)

                Text(viewModel.selectedAccountSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .accessibilityLabel(viewModel.l10n.accountSettingsTitle)
                    .accessibilityValue(viewModel.selectedAccountSummary)
            }

            Spacer()

            Button(viewModel.l10n.settingsButton) {
                isShowingSettings = true
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .accessibilityLabel(viewModel.l10n.openSettingsLabel)
            .accessibilityHint(viewModel.l10n.openSettingsHint)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var queryBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField(viewModel.l10n.appNamePlaceholder, text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 180)
                    .accessibilityLabel(viewModel.l10n.appNameSearchFieldLabel)
                    .accessibilityHint(viewModel.l10n.appNameSearchFieldHint)

                Button(viewModel.l10n.searchButton, action: viewModel.searchApps)
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(viewModel.isSearching)
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(viewModel.l10n.searchAppsLabel)
                    .accessibilityHint(viewModel.l10n.searchAppsHint)

                TextField(viewModel.l10n.directLookupPlaceholder, text: $viewModel.directLookupText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 240)
                    .accessibilityLabel(viewModel.l10n.directLookupFieldLabel)
                    .accessibilityHint(viewModel.l10n.directLookupFieldHint)

                Button(viewModel.l10n.lookUpButton, action: viewModel.lookupDirectApp)
                    .disabled(viewModel.isSearching)
                    .accessibilityLabel(viewModel.l10n.lookUpLabel)
                    .accessibilityHint(viewModel.l10n.lookUpHint)

                Button(viewModel.l10n.startQueryButton, action: viewModel.startQuery)
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(viewModel.isQuerying)
                    .buttonStyle(.bordered)
                    .accessibilityLabel(viewModel.l10n.startQueryLabel)
                    .accessibilityHint(viewModel.l10n.startQueryHint)

                Button(viewModel.l10n.cancelButton, action: viewModel.cancelQuery)
                    .keyboardShortcut(".", modifiers: [.command])
                    .disabled(!viewModel.isQuerying)
                    .accessibilityLabel(viewModel.l10n.cancelQueryLabel)
            }
        }
    }

    @ViewBuilder
    private var searchResultsBar: some View {
        if !viewModel.searchResults.isEmpty {
            HStack(spacing: 10) {
                Text(viewModel.l10n.searchResultsTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker(
                    viewModel.l10n.appSearchResultsLabel,
                    selection: Binding(
                        get: { viewModel.selectedApp },
                        set: { viewModel.chooseSearchResult($0) }
                    )
                ) {
                    Text(viewModel.l10n.noAppSelected).tag(Optional<AppSearchResult>.none)
                    ForEach(viewModel.searchResults) { app in
                        Text("\(app.name) - \(app.developerName)").tag(Optional(app))
                    }
                }
                .labelsHidden()
                .accessibilityLabel(viewModel.l10n.appSearchResultsLabel)
                .accessibilityHint(viewModel.l10n.selectAppHint)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var scopeBar: some View {
        HStack(spacing: 8) {
            Text(viewModel.l10n.countriesTitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(viewModel.l10n.allButton, action: viewModel.selectAllCountries)
                .buttonStyle(.bordered)
                .accessibilityLabel(viewModel.l10n.selectAllCountriesLabel)

            Button(viewModel.l10n.majorButton, action: viewModel.selectMajorCountries)
                .buttonStyle(.bordered)
                .accessibilityLabel(viewModel.l10n.selectMajorCountriesLabel)
                .accessibilityHint(viewModel.l10n.selectMajorCountriesHint)

            Button(viewModel.l10n.clearButton, action: viewModel.clearCountries)
                .buttonStyle(.bordered)
                .accessibilityLabel(viewModel.l10n.clearSelectedCountriesLabel)

            Button(viewModel.l10n.customCountriesButton) {
                isShowingCountryEditor.toggle()
            }
            .buttonStyle(.bordered)
            .popover(isPresented: $isShowingCountryEditor, arrowEdge: .bottom) {
                countryEditor
                    .frame(width: 360, height: 420)
                    .padding()
            }
            .accessibilityLabel(viewModel.l10n.customCountriesLabel)
            .accessibilityHint(viewModel.l10n.customCountriesHint)

            Text(viewModel.l10n.selectedCountryCount(viewModel.selectedCountryCodes.count))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityLabel(viewModel.l10n.selectedCountryCountLabel)
                .accessibilityValue("\(viewModel.selectedCountryCodes.count)")

            Spacer()
        }
    }

    private var countryEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.l10n.countriesTitle)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(CountryStorefrontCatalog.all) { storefront in
                        Toggle(
                            isOn: Binding(
                                get: { viewModel.selectedCountryCodes.contains(storefront.countryCode) },
                                set: { viewModel.toggleCountry(storefront, isSelected: $0) }
                            )
                        ) {
                            Text("\(storefront.displayName) (\(storefront.countryCode), \(storefront.currencyCode))")
                        }
                        .accessibilityLabel(viewModel.l10n.countryToggleLabel(name: storefront.displayName, code: storefront.countryCode, currency: storefront.currencyCode))
                        .accessibilityHint(viewModel.l10n.countryToggleHint)
                    }
                }
            }
            .accessibilityLabel(viewModel.l10n.countrySelectionListLabel)
        }
    }
}
