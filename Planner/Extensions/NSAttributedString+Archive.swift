import Foundation

extension NSAttributedString {
    func archived() -> Data? {
        try? NSKeyedArchiver.archivedData(
            withRootObject: self,
            requiringSecureCoding: false
        )
    }

    static func unarchived(from data: Data) -> NSAttributedString? {
        try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSAttributedString.self,
            from: data
        )
    }
}
