import SwiftUI
import AppKit
import AppStoreIAPClientCore

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isShowingAccounts = false

    var body: some View {
        VStack(spacing: 0) {
            querySurface

            if !viewModel.resultRows.isEmpty || viewModel.isQuerying {
                Divider()
                PriceMatrixView(viewModel: viewModel)
                    .padding(14)
            }
        }
        .frame(minWidth: 520, minHeight: viewModel.resultRows.isEmpty && !viewModel.isQuerying ? 96 : 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $isShowingAccounts) {
            SettingsView(viewModel: viewModel)
                .frame(minWidth: 770, minHeight: 660)
        }
        .onChange(of: viewModel.accountManagementRequest) {
            isShowingAccounts = true
        }
    }

    private var querySurface: some View {
        HStack(spacing: 8) {
            TextField(viewModel.l10n.queryInputPlaceholder, text: $viewModel.queryText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(viewModel.l10n.queryInputLabel)
                .accessibilityHint(viewModel.l10n.queryInputHint)
                .onSubmit(viewModel.submitQuery)

            Button(viewModel.l10n.queryButton, action: viewModel.submitQuery)
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmitQuery)
                .accessibilityLabel(viewModel.l10n.queryButtonLabel)
                .accessibilityHint(viewModel.l10n.queryButtonHint)
        }
        .controlSize(.regular)
        .padding(14)
    }
}
