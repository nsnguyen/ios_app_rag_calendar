import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var plainText: String
    var onTextChange: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.label
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.autocorrectionType = .yes
        textView.spellCheckingType = .yes

        // Set up formatting toolbar
        let toolbar = FormattingToolbar { action in
            context.coordinator.handleToolbarAction(action, textView: textView)
        }
        let hostingController = UIHostingController(rootView: toolbar)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        hostingController.view.backgroundColor = UIColor.secondarySystemBackground
        textView.inputAccessoryView = hostingController.view

        // Set initial content
        if attributedText.length > 0 {
            textView.attributedText = attributedText
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.attributedText != attributedText && !context.coordinator.isEditing {
            textView.attributedText = attributedText
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isEditing = false

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            isEditing = true
            parent.attributedText = textView.attributedText
            parent.plainText = textView.attributedText.extractedPlainText
            parent.onTextChange?()
            isEditing = false
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
        }

        func handleToolbarAction(_ action: FormattingAction, textView: UITextView) {
            let range = textView.selectedRange
            guard range.length > 0 || action == .checklist else { return }

            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)

            switch action {
            case .bold:
                RichTextHelpers.toggleBold(in: mutableText, range: range)
            case .italic:
                RichTextHelpers.toggleItalic(in: mutableText, range: range)
            case .heading:
                RichTextHelpers.applyHeading(in: mutableText, range: range)
            case .checklist:
                RichTextHelpers.insertChecklist(in: mutableText, at: range.location)
            }

            textView.attributedText = mutableText
            textView.selectedRange = range

            parent.attributedText = mutableText
            parent.plainText = mutableText.extractedPlainText
            parent.onTextChange?()
        }
    }
}

enum FormattingAction {
    case bold
    case italic
    case heading
    case checklist
}
