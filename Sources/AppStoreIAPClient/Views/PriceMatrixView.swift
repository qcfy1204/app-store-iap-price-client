import SwiftUI
import AppKit
import AppStoreIAPClientCore

struct PriceMatrixView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(viewModel.statusMessage)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityLabel(viewModel.l10n.queryStatusLabel)
                    .accessibilityValue(viewModel.statusMessage)

                Spacer()

                summaryStrip
            }

            Table(viewModel.resultRows) {
                TableColumn(viewModel.l10n.countryColumn) { row in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(row.countryName)
                            .lineLimit(1)
                        Text(row.countryCode)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 170, ideal: 220, max: 280)

                TableColumn(viewModel.l10n.currencyColumn) { row in
                    Text(row.currencyCode)
                        .monospaced()
                }
                .width(min: 70, ideal: 80, max: 90)

                TableColumn(viewModel.l10n.productColumn) { row in
                    Text(row.productName)
                        .lineLimit(1)
                }
                .width(min: 160, ideal: 220, max: 300)

                TableColumn(viewModel.l10n.periodColumn) { row in
                    Text(row.period ?? viewModel.l10n.unknown)
                        .foregroundStyle(row.period == nil ? .secondary : .primary)
                }
                .width(min: 80, ideal: 100, max: 130)

                TableColumn(viewModel.l10n.priceColumn) { row in
                    Text(priceText(row.price))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(row.price == nil ? .secondary : .primary)
                }
                .width(min: 90, ideal: 110, max: 140)

                TableColumn(viewModel.l10n.sourceColumn) { row in
                    Text(viewModel.l10n.displayName(for: row.source))
                        .lineLimit(1)
                }
                .width(min: 110, ideal: 130, max: 170)

                TableColumn(viewModel.l10n.statusColumn) { row in
                    Text(viewModel.l10n.displayName(for: row.status))
                        .lineLimit(1)
                }
                .width(min: 90, ideal: 110, max: 140)

                TableColumn(viewModel.l10n.messageColumn) { row in
                    Text(row.message)
                        .lineLimit(2)
                }
                .width(min: 260, ideal: 360)
            }
            .alternatingRowBackgrounds(.enabled)
            .frame(minHeight: 380)
            .accessibilityLabel(viewModel.l10n.resultTableLabel)
            .accessibilityValue(viewModel.querySummaryText)

            HStack(spacing: 12) {
                Text(viewModel.l10n.publicDataLimitation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .accessibilityLabel(viewModel.l10n.publicDataLimitationLabel)

                Spacer()

                Button(viewModel.l10n.exportCSVButton) {
                    saveExport(extensionName: "csv", action: viewModel.exportCSV)
                }
                .disabled(viewModel.resultRows.isEmpty)
                .accessibilityLabel(viewModel.l10n.exportCSVButton)
                .accessibilityHint(viewModel.l10n.exportCSVHint)

                Button(viewModel.l10n.exportJSONButton) {
                    saveExport(extensionName: "json", action: viewModel.exportJSON)
                }
                .disabled(viewModel.resultRows.isEmpty)
                .accessibilityLabel(viewModel.l10n.exportJSONButton)
                .accessibilityHint(viewModel.l10n.exportJSONHint)
            }
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            SummaryBadge(label: viewModel.l10n.completedSummaryLabel, value: "\(viewModel.summary.completedCountries)/\(viewModel.summary.totalCountries)", tint: .blue)
            SummaryBadge(label: viewModel.l10n.availableSummaryLabel, value: "\(viewModel.summary.availableRows)", tint: .green)
            SummaryBadge(label: viewModel.l10n.missingSummaryLabel, value: "\(viewModel.summary.missingRows)", tint: .orange)
            SummaryBadge(label: viewModel.l10n.failedSummaryLabel, value: "\(viewModel.summary.failedRows)", tint: .red)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.l10n.querySummaryLabel)
        .accessibilityValue(viewModel.querySummaryText)
    }

    private func priceText(_ price: Decimal?) -> String {
        price.map { NSDecimalNumber(decimal: $0).stringValue } ?? viewModel.l10n.notPublic
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

private struct SummaryBadge: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
