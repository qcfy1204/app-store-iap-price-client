import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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

            HStack {
                Spacer()
                Button(viewModel.l10n.doneButton) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel(viewModel.l10n.closeSettingsLabel)
            }
        }
        .padding()
        .accessibilityLabel(viewModel.l10n.settingsLabel)
    }
}
