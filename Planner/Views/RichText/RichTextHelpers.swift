import UIKit

enum RichTextHelpers {

    // MARK: - Bold

    static func toggleBold(in text: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }

        text.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            guard let font = value as? UIFont else { return }
            let descriptor = font.fontDescriptor

            let newDescriptor: UIFontDescriptor
            if descriptor.symbolicTraits.contains(.traitBold) {
                newDescriptor = descriptor.withSymbolicTraits(
                    descriptor.symbolicTraits.subtracting(.traitBold)
                ) ?? descriptor
            } else {
                newDescriptor = descriptor.withSymbolicTraits(
                    descriptor.symbolicTraits.union(.traitBold)
                ) ?? descriptor
            }

            let newFont = UIFont(descriptor: newDescriptor, size: font.pointSize)
            text.addAttribute(.font, value: newFont, range: subRange)
        }
    }

    // MARK: - Italic

    static func toggleItalic(in text: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }

        text.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            guard let font = value as? UIFont else { return }
            let descriptor = font.fontDescriptor

            let newDescriptor: UIFontDescriptor
            if descriptor.symbolicTraits.contains(.traitItalic) {
                newDescriptor = descriptor.withSymbolicTraits(
                    descriptor.symbolicTraits.subtracting(.traitItalic)
                ) ?? descriptor
            } else {
                newDescriptor = descriptor.withSymbolicTraits(
                    descriptor.symbolicTraits.union(.traitItalic)
                ) ?? descriptor
            }

            let newFont = UIFont(descriptor: newDescriptor, size: font.pointSize)
            text.addAttribute(.font, value: newFont, range: subRange)
        }
    }

    // MARK: - Heading

    static func applyHeading(in text: NSMutableAttributedString, range: NSRange) {
        let headingFont = UIFont.preferredFont(forTextStyle: .title2)
        text.addAttribute(.font, value: headingFont, range: range)
    }

    // MARK: - Checklist

    static let checklistKey = NSAttributedString.Key("checklistState")

    static func insertChecklist(in text: NSMutableAttributedString, at location: Int) {
        let unchecked = "☐ "
        let checklistString = NSMutableAttributedString(string: "\n\(unchecked)")

        checklistString.addAttribute(
            .font,
            value: UIFont.preferredFont(forTextStyle: .body),
            range: NSRange(location: 0, length: checklistString.length)
        )
        checklistString.addAttribute(
            Self.checklistKey,
            value: false,
            range: NSRange(location: 1, length: unchecked.count)
        )

        let insertLocation = min(location, text.length)
        text.insert(checklistString, at: insertLocation)
    }

    /// Toggles a checklist item between checked and unchecked states.
    static func toggleChecklistItem(in text: NSMutableAttributedString, at location: Int) {
        let fullRange = NSRange(location: 0, length: text.length)

        text.enumerateAttribute(checklistKey, in: fullRange, options: []) { value, range, stop in
            guard range.contains(location) || range.location == location else { return }
            guard let isChecked = value as? Bool else { return }

            let str = text.attributedSubstring(from: range).string
            let newStr: String
            if isChecked {
                newStr = str.replacingOccurrences(of: "☑ ", with: "☐ ")
            } else {
                newStr = str.replacingOccurrences(of: "☐ ", with: "☑ ")
            }

            text.replaceCharacters(in: range, with: newStr)
            text.addAttribute(checklistKey, value: !isChecked, range: NSRange(location: range.location, length: newStr.count))
            stop.pointee = true
        }
    }
}
