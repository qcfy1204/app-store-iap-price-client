# App Store IAP Price Client

A native macOS SwiftUI tool for checking App Store app availability and publicly visible in-app purchase price status across storefront countries and regions.

## Features

- Search by App Store app name.
- Look up by App Store URL or numeric App ID.
- Parse storefront country codes from App Store URLs such as `/cn/app/...`.
- Query selected storefront countries and regions.
- Distinguish public data gaps from unavailable storefronts and request failures.
- Export results as CSV or JSON.
- English and Simplified Chinese UI, following the macOS system language by default.
- VoiceOver-oriented labels, hints, values, focus order, and keyboard-accessible controls.

## Important Data Limitation

Apple's public App Store data does not reliably expose detailed in-app purchase prices for arbitrary third-party apps in every country or region. This app marks those rows as `Not Public` instead of treating missing data as free or unavailable.

The App Store Connect credential fields are present for future authorized workflows. This release does not upload credentials anywhere and does not implement signed App Store Connect price fetching yet.

## Requirements

- macOS 14 or newer
- Swift 6 compatible toolchain

## Build

```bash
swift build
```

## Run

```bash
swift run AppStoreIAPClient
```

## Tests

This environment did not provide XCTest, so the project includes a small Swift executable test runner:

```bash
swift run AppStoreIAPClientUnitTests
```

For real public App Store smoke tests:

```bash
swift run AppStoreIAPClientSmoke ChatGPT
swift run AppStoreIAPClientSmoke 微信 CN
swift run AppStoreIAPClientSmoke --url https://apps.apple.com/cn/app/id414478124
```

## Public Release Notes

Generated local app bundles and build artifacts are intentionally ignored. Commit source files, documentation, and verification notes only.

