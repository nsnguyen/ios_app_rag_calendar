---
name: rich-text-notes
description: Build a rich text note editor with formatting toolbar, checklists, and images in SwiftUI using UITextView bridging and NSAttributedString. This skill should be used when implementing the note editor, rich text formatting, text storage, or plain text extraction for the planner app.
---

# Rich Text Notes

## Overview

Implement a rich text note-taking editor in SwiftUI for the iOS 18+ planner app. The editor supports bold, italic, headings, bullet lists, checklists, and inline images. Rich text is stored as archived `NSAttributedString` data in SwiftData, with a parallel plain text extraction for RAG indexing.

## UITextView Bridge

SwiftUI's `TextEditor` does not support attributed strings. Bridge `UITextView` using `UIViewRepresentable`:

```swift
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var onTextChange: ((NSAttributedString) -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.attributedText = attributedText
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.allowsEditingTextAttributes = true
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.backgroundColor = .systemBackground
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.attributedText != attributedText {
            let selectedRange = textView.selectedRange
            textView.attributedText = attributedText
            textView.selectedRange = selectedRange
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $attributedText, onChange: onTextChange)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: NSAttributedString
        var onChange: ((NSAttributedString) -> Void)?

        init(text: Binding<NSAttributedString>, onChange: ((NSAttributedString) -> Void)?) {
            _text = text
            self.onChange = onChange
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.attributedText
            onChange?(textView.attributedText)
        }
    }
}
```

Critical details:
- Preserve `selectedRange` during `updateUIView` to avoid cursor jumping
- Set `allowsEditingTextAttributes = true` for paste support of formatted text
- Use `UIFont.preferredFont(forTextStyle:)` for Dynamic Type support

## Formatting Toolbar

Build a SwiftUI toolbar that modifies the selected text in the `UITextView`:

```swift
struct FormattingToolbar: View {
    let onBold: () -> Void
    let onItalic: () -> Void
    let onHeading: () -> Void
    let onBulletList: () -> Void
    let onChecklist: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBold) {
                Image(systemName: "bold")
            }
            Button(action: onItalic) {
                Image(systemName: "italic")
            }
            Button(action: onHeading) {
                Image(systemName: "textformat.size.larger")
            }
            Button(action: onBulletList) {
                Image(systemName: "list.bullet")
            }
            Button(action: onChecklist) {
                Image(systemName: "checklist")
            }
            Spacer()
            Button(action: { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }) {
                Image(systemName: "keyboard.chevron.compact.down")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
```

### Applying Formatting

To toggle bold/italic on selected text, modify the `NSAttributedString` at the selected range:

```swift
func toggleBold(in textView: UITextView) {
    guard let selectedRange = textView.selectedTextRange else { return }
    let nsRange = textView.nsRange(from: selectedRange)
    let mutable = NSMutableAttributedString(attributedString: textView.attributedText)

    mutable.enumerateAttribute(.font, in: nsRange) { value, range, _ in
        guard let font = value as? UIFont else { return }
        let descriptor = font.fontDescriptor
        let isBold = descriptor.symbolicTraits.contains(.traitBold)
        if isBold {
            let newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(.traitBold))!
            mutable.addAttribute(.font, value: UIFont(descriptor: newDescriptor, size: font.pointSize), range: range)
        } else {
            let newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitBold))!
            mutable.addAttribute(.font, value: UIFont(descriptor: newDescriptor, size: font.pointSize), range: range)
        }
    }

    textView.attributedText = mutable
    textView.selectedRange = nsRange
}
```

Gotcha: `UIFontDescriptor.withSymbolicTraits()` can return `nil` for some font combinations. Always use the nil-coalescing or guard pattern.

## Checklist Support

Use a custom `NSAttributedString` attribute key to mark checklist items:

```swift
extension NSAttributedString.Key {
    static let checklistState = NSAttributedString.Key("checklistState")
}

// Values: "unchecked" or "checked"
```

Render checklists by using `NSTextAttachment` with SF Symbol images:

```swift
func insertChecklistItem(in textView: UITextView, checked: Bool) {
    let symbolName = checked ? "checkmark.square.fill" : "square"
    let config = UIImage.SymbolConfiguration(textStyle: .body)
    let image = UIImage(systemName: symbolName, withConfiguration: config)!
    let attachment = NSTextAttachment(image: image)
    let attachmentString = NSAttributedString(attachment: attachment)

    let mutable = NSMutableAttributedString(attributedString: attachmentString)
    mutable.append(NSAttributedString(string: " "))
    mutable.addAttribute(.checklistState, value: checked ? "checked" : "unchecked",
                         range: NSRange(location: 0, length: mutable.length))

    textView.textStorage.insert(mutable, at: textView.selectedRange.location)
}
```

Implement tap-to-toggle by using `UITextViewDelegate` and hit-testing the attachment.

## Data Storage

### Archiving NSAttributedString to Data

```swift
extension NSAttributedString {
    func archivedData() throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }

    static func fromArchivedData(_ data: Data) throws -> NSAttributedString {
        guard let result = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSAttributedString.self, from: data
        ) else {
            throw NSError(domain: "RichText", code: 1, userInfo: nil)
        }
        return result
    }
}
```

Store `archivedData()` output in the `Note.richTextData` property (SwiftData `Data` type).

Gotcha: `requiringSecureCoding: false` is needed because `NSTextAttachment` (used for images/checklists) does not fully support secure coding by default.

## Plain Text Extraction

Extract plain text from rich content for RAG indexing:

```swift
extension NSAttributedString {
    func extractPlainTextForRAG() -> String {
        var result = ""
        enumerateAttributes(in: NSRange(location: 0, length: length)) { attrs, range, _ in
            if let checkState = attrs[.checklistState] as? String {
                let prefix = checkState == "checked" ? "[x] " : "[ ] "
                result += prefix
            }
            let substring = attributedSubstring(from: range).string
            result += substring
        }
        return result
    }
}
```

This preserves checklist state as markdown-style markers in the plain text, making checklist items searchable via RAG.

## Auto-Save

Implement debounced auto-save using Swift concurrency:

```swift
@Observable
final class NoteEditorViewModel {
    var note: Note
    private var saveTask: Task<Void, Never>?
    private let modelContext: ModelContext

    func textDidChange(_ attributedText: NSAttributedString) {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.save(attributedText)
        }
    }

    private func save(_ attributedText: NSAttributedString) {
        note.richTextData = try? attributedText.archivedData()
        note.plainText = attributedText.extractPlainTextForRAG()
        note.updatedAt = Date()
        try? modelContext.save()
        // Trigger re-indexing for RAG
    }
}
```

Debounce interval of 1.5 seconds balances responsiveness with avoiding excessive disk writes.

## Keyboard Management

Place the formatting toolbar above the keyboard using `.inputAccessoryView`:

```swift
func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    // ... other setup ...

    let toolbar = UIHostingController(rootView: FormattingToolbar(...))
    toolbar.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
    textView.inputAccessoryView = toolbar.view

    return textView
}
```

This ensures the toolbar floats above the keyboard and dismisses with it.
