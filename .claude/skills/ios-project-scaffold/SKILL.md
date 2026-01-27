---
name: ios-project-scaffold
description: Scaffold a new SwiftUI iOS 18+ Xcode project with SwiftData persistence, EventKit calendar integration, on-device RAG via NaturalLanguage and Core ML, and Apple Intelligence features (App Intents, Siri, Foundation models). This skill should be used when the user asks to create, initialize, bootstrap, or set up a new iOS app project from scratch.
---

# iOS Project Scaffold

## Overview

Generate a complete Xcode-ready iOS project directory structure for a SwiftUI planner app targeting iOS 18+. The scaffold wires up SwiftData, EventKit/EventKitUI, on-device RAG (NaturalLanguage framework), and Apple Intelligence (App Intents, Siri, Foundation Models). All UI follows Apple Human Interface Guidelines.

## Step 1: Determine App Identity

Before generating files, resolve the app name. If not specified, ask. Derive:

- **ProjectName**: PascalCase, no spaces (e.g., `MeetingMind`)
- **BundleIdentifier**: reverse-DNS, e.g., `com.developer.MeetingMind`
- **DisplayName**: human-readable name for the app icon

## Step 2: Create Directory Structure

```
{{APP_NAME}}/
  {{APP_NAME}}/
    Sources/
      App/
        {{APP_NAME}}App.swift
      Models/
        MeetingRecord.swift
        Note.swift
        Person.swift
        EmbeddingRecord.swift
        Tag.swift
      Views/
        ContentView.swift
        Timeline/
          TimelineView.swift
          MeetingCardView.swift
        Meetings/
          MeetingDetailView.swift
        Notes/
          NotesListView.swift
          NoteEditorView.swift
        Search/
          SearchView.swift
          SearchResultRow.swift
        People/
          PeopleView.swift
          PersonDetailView.swift
        Settings/
          SettingsView.swift
        Components/
          TagChipView.swift
          PersonAvatarView.swift
          EmptyStateView.swift
      Services/
        CalendarService.swift
        EmbeddingService.swift
        RAGService.swift
        MeetingContextService.swift
        SummarizationService.swift
      Intents/
        AppShortcuts.swift
        QueryMeetingIntent.swift
        SearchNotesIntent.swift
        CreateNoteIntent.swift
      Extensions/
        Date+Helpers.swift
    Resources/
      Assets.xcassets/
      Preview Content/
    Info.plist
    {{APP_NAME}}.entitlements
    PrivacyInfo.xcprivacy
  {{APP_NAME}}Tests/
  {{APP_NAME}}UITests/
  .gitignore
```

Do NOT generate `.xcodeproj` or `project.pbxproj`. Instruct the user to create the Xcode project via `File > New Project > App` (SwiftUI, Swift) then replace generated source files with scaffold output.

## Step 3: App Entry Point

Configure `ModelContainer` in `init()`, not as a property wrapper, to handle errors explicitly:

```swift
import SwiftUI
import SwiftData

@main
struct {{APP_NAME}}App: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                MeetingRecord.self, Note.self, Person.self,
                EmbeddingRecord.self, Tag.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

List every `@Model` type in the `Schema`. Missing a type causes silent data loss on migration.

## Step 4: Info.plist Required Keys

```xml
<key>NSCalendarsFullAccessUsageDescription</key>
<string>Access your calendar to track meetings and provide context about your schedule.</string>
<key>NSSiriUsageDescription</key>
<string>Ask Siri about your meetings and notes.</string>
```

iOS 17+ replaced `NSCalendarsUsageDescription` with `NSCalendarsFullAccessUsageDescription`. The old key silently fails on iOS 18. Generic privacy strings trigger App Review rejection.

## Step 5: Entitlements

Include `com.apple.developer.siri = true`. Without this, App Intents compile but Siri never surfaces them. Also enable Siri in Xcode Signing & Capabilities.

## Step 6: Build Settings

1. `IPHONEOS_DEPLOYMENT_TARGET` = `18.0`
2. `SWIFT_VERSION` = `6.0`
3. `SWIFT_STRICT_CONCURRENCY` = `complete`
4. Ensure `Other Swift Flags` excludes `-disable-reflection-metadata` (breaks App Intents)

## Step 7: Starter Service Stubs

### CalendarService

Use `requestFullAccessToEvents()` (iOS 17+ API). The old `requestAccess(to:completion:)` silently returns `false` on iOS 17+ even when user grants access.

### EmbeddingService

`NLEmbedding.sentenceEmbedding(for: .english)` returns `nil` if the model is not on-device. Vectors are 512-dimensional for English.

### AppShortcutsProvider

Must be top-level struct. Phrases must include `\(.applicationName)` at least once. Limit 10 shortcuts total.

## Apple HIG Rules

- Semantic colors only (`Color.primary`, `.secondary`, `.background`)
- SF Symbols with `.hierarchical` or `.palette` rendering
- `.navigationTitle()` + `.toolbar {}` — never custom nav headers
- `List`, `Form`, `Section` over custom scroll layouts
- `.searchable()` — never custom search bars
- Dynamic Type via `.font(.body)`, `.headline`, etc.
- Support light + dark mode — never `Color.white`/`.black`

## Post-Scaffold Checklist

1. Create Xcode project (File > New > App, SwiftUI + Swift)
2. Replace auto-generated sources with scaffold files
3. Add Siri capability in Signing & Capabilities
4. Set deployment target iOS 18.0, Swift 6.0
5. Build (Cmd+B) to verify ModelContainer initializes
6. Run on physical device for EventKit testing
7. Test Siri in Settings > Siri > App Shortcuts
