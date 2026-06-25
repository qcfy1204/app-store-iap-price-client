# Accessibility Checklist

Date: 2026-06-25

## Automated

- `swift run AppStoreIAPClientUnitTests`: passed. 13 custom unit tests covered App ID parsing, storefront catalog integrity, price normalization, Connect credential configuration, CSV/JSON export, and system-language localization fallback.
- `swift run AppStoreIAPClientSmoke ChatGPT`: passed. It selected ChatGPT by OpenAI OpCo, LLC, App ID 6448311069; United States, Japan, and United Kingdom lookup succeeded as public-not-detailed rows; China Mainland returned not available; zero request failures.
- `swift run AppStoreIAPClientSmoke Duolingo`: passed. It exposed a localized-name issue across storefronts; the app now keeps the originally selected app name in the Product column and records storefront-localized names in the Message column.
- `swift run AppStoreIAPClientSmoke 微信 CN`: passed. It selected 微信 from the China storefront and verified Chinese search plus cross-storefront lookup behavior.
- `swift run AppStoreIAPClientSmoke --url https://apps.apple.com/cn/app/id414478124`: passed. It verified direct App Store URL lookup now parses the storefront country from the URL and uses CN instead of hard-coding US.
- `swift build`: passed with no warnings after the final export/UI update.
- `swift build -c release`: passed and produced a release executable.
- `open outputs/AppStoreIAPClient.app`: returned success and launched the native macOS app bundle.

## Localization

- The app defaults to the macOS system preferred language.
- Supported languages in this build: English and Simplified Chinese.
- Unsupported languages fall back to English.
- Visible labels, status text, table headers, hints, and accessibility labels are routed through the localization layer.

## Implemented Accessibility Metadata

- UI structure: compact tool-window layout with header, top query bar, country scope bar, main result table, and bottom export actions.
- App name search field: accessibility label and hint.
- Search button: accessibility label and hint.
- Direct lookup field: accessibility label and hint.
- Direct lookup button: accessibility label and hint.
- Selected app summary: accessibility label and value.
- Search results list rows: combined label with app name, developer, and App ID.
- Country selection toggles: label includes country name, country code, and currency code.
- Query status: accessibility label and value.
- Query summary: accessibility label and value.
- Result table: accessibility label, with visible columns for country, currency, product, period, price, source, status, and message.
- Export CSV and JSON buttons: accessibility labels and hints.
- Settings fields: accessibility labels and hints for Issuer ID, Key ID, and private key path.

## Keyboard Workflow To Verify With VoiceOver

1. Open `outputs/AppStoreIAPClient.app`.
2. Use Tab and Shift-Tab to reach the app name search field, Search button, search results list, direct lookup field, Look Up button, country controls, Start Query button, Cancel button, result table, Export CSV button, Export JSON button, and Settings button.
3. Confirm each focused control announces a useful name and role.
4. Search by app name and select a result.
5. Paste an App Store URL or numeric App ID and confirm direct lookup selects an app.
6. Start a query with major countries selected and confirm query progress is readable as status text.
7. Cancel a query and confirm the status text changes to cancelled.
8. Export CSV or JSON after results appear and confirm the save panel is keyboard reachable.

## Notes

- Public App Store data does not reliably expose detailed IAP prices for arbitrary third-party apps in every country. The app marks those rows as `Not Public` rather than treating them as free.
- App Store Connect credentials are represented in settings and model code, but signed Connect price fetching is isolated for a later credential-backed implementation pass.
- The generated `.app` is a local unsigned development bundle.
