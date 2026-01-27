---
name: permissions-privacy
description: Handle iOS privacy manifest, permission flows (calendar, Siri), data protection, and App Store privacy labels for the iOS 18+ planner app. This skill should be used when implementing permission requests, privacy manifests, data protection, or onboarding permission flows.
---

# Permissions & Privacy

## Overview

Manage all permission requests, privacy declarations, and data protection for the planner app. The app accesses calendars (EventKit), uses Siri (App Intents), and stores personal meeting data on-device. All data stays on-device — no cloud transmission.

## Privacy Manifest (PrivacyInfo.xcprivacy)

Required for App Store submission. Create at the project root:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyTracking</key>
    <false/>
</dict>
</plist>
```

Key notes:
- `NSPrivacyCollectedDataTypes` is empty because all data stays on-device.
- `NSPrivacyTracking` is false — no tracking or fingerprinting.
- Declare `UserDefaults` (CA92.1 — app functionality) and `FileTimestamp` (C617.1 — SwiftData uses file timestamps internally).

## Info.plist Privacy Keys

```xml
<key>NSCalendarsFullAccessUsageDescription</key>
<string>Access your calendar to show meetings and help you recall meeting context.</string>

<key>NSSiriUsageDescription</key>
<string>Ask Siri about your meetings and search your notes by voice.</string>
```

- Use `NSCalendarsFullAccessUsageDescription` (not the deprecated `NSCalendarsUsageDescription`)
- Strings must be specific and descriptive — generic text causes App Review rejection

## Progressive Permission Flow

Request permissions one at a time during onboarding, with explanation before each:

```swift
struct OnboardingPermissionView: View {
    @State private var step: PermissionStep = .welcome

    enum PermissionStep {
        case welcome, calendarExplain, calendarRequest, siriExplain, siriRequest, complete
    }

    var body: some View {
        switch step {
        case .welcome:
            WelcomeStepView(onContinue: { step = .calendarExplain })
        case .calendarExplain:
            PermissionExplainView(
                icon: "calendar",
                title: "Calendar Access",
                explanation: "To show your meetings and help you remember what was discussed, the app needs to read your calendar.",
                onContinue: { step = .calendarRequest }
            )
        case .calendarRequest:
            // Trigger actual system permission dialog
            Color.clear.task {
                let granted = try? await calendarService.requestAccess()
                step = .siriExplain
            }
        case .siriExplain:
            PermissionExplainView(
                icon: "mic",
                title: "Siri Access",
                explanation: "Ask Siri about your meetings hands-free. For example: \"What was my meeting with John about?\"",
                onContinue: { step = .siriRequest }
            )
        // ...
        }
    }
}
```

Pattern: **Explain → Request → Handle Result**. Never show the system permission dialog cold.

## Handling All Permission States

```swift
func handleCalendarPermission() {
    switch EKEventStore.authorizationStatus(for: .event) {
    case .notDetermined:
        // Show onboarding explanation, then request
        showCalendarExplanation = true
    case .fullAccess:
        // Good to go
        startCalendarSync()
    case .writeOnly:
        // User granted write-only in iOS 17+; need full access
        showUpgradePermissionAlert = true
    case .denied:
        // Show settings deep-link
        showSettingsAlert = true
    case .restricted:
        // Device policy restricts calendar access (MDM, parental controls)
        showRestrictedAlert = true
    @unknown default:
        break
    }
}
```

### Settings Deep-Link

```swift
Button("Open Settings") {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

## Data Protection

### SwiftData File Protection

```swift
let config = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    allowsSave: true
)
// The default SQLite store location inherits the app's data protection class.
// Set the entitlement for Complete Protection:
```

In the entitlements file:
```xml
<key>com.apple.developer.default-data-protection</key>
<string>NSFileProtectionComplete</string>
```

This ensures the SwiftData store is encrypted and inaccessible when the device is locked.

### No Data Leaves Device

The app architecture ensures privacy:
- RAG embeddings: generated on-device via `NLEmbedding`
- Summarization: runs on-device via Apple Foundation Models
- Calendar data: read from EventKit, stored locally
- Notes: stored in local SwiftData only
- No network requests for any user data

## App Store Privacy Labels

For the App Store Connect privacy questionnaire:

| Category | Collected? | Notes |
|---|---|---|
| Contact Info | No | Names/emails from calendar stay on-device |
| Calendar | No | Read from EventKit, stored locally only |
| User Content | No | Notes stay on-device |
| Search History | No | Queries stay on-device |
| Diagnostics | Optional | Only if crash reporting is added |

Select "Data Not Collected" for all categories — the app processes everything locally.

## Data Export & Deletion

Provide user controls even if not legally required:

```swift
func exportAllData(context: ModelContext) -> Data {
    let meetings = try? context.fetch(FetchDescriptor<MeetingRecord>())
    let notes = try? context.fetch(FetchDescriptor<Note>())
    // Serialize to JSON
    let export = AppDataExport(meetings: meetings ?? [], notes: notes ?? [])
    return try! JSONEncoder().encode(export)
}

func deleteAllData(context: ModelContext) {
    try? context.delete(model: EmbeddingRecord.self)
    try? context.delete(model: Note.self)
    try? context.delete(model: MeetingRecord.self)
    try? context.delete(model: Person.self)
    try? context.delete(model: Tag.self)
    // Also clear Spotlight index
    CSSearchableIndex.default().deleteAllSearchableItems()
}
```

Place these in Settings view with appropriate confirmation dialogs.
