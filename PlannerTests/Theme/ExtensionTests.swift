import Testing
import Foundation
@testable import Planner

@Suite("Extension Tests")
struct ExtensionTests {

    // MARK: - Color+Hex

    @Test("Color from 6-digit hex creates successfully")
    func colorFromHex() {
        // Should not crash
        _ = Color(hex: "5B4F3E")
        _ = Color(hex: "FFFFFF")
        _ = Color(hex: "000000")
    }

    @Test("Color from 3-digit hex creates successfully")
    func colorFromShortHex() {
        _ = Color(hex: "FFF")
        _ = Color(hex: "000")
    }

    // MARK: - Date+Helpers

    @Test("Start of day returns midnight")
    func startOfDay() {
        let date = Date()
        let start = date.startOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("End of day is last second")
    func endOfDay() {
        let date = Date()
        let end = date.endOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: end)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
    }

    @Test("isToday returns true for today")
    func isToday() {
        #expect(Date().isToday)
    }

    @Test("Date range generates correct number of dates")
    func dateRange() {
        let start = Date().startOfDay
        let end = Calendar.current.date(byAdding: .day, value: 4, to: start)!
        let range = Date.dateRange(from: start, to: end)
        #expect(range.count == 5)
    }

    @Test("Days from calculates correctly")
    func daysFrom() {
        let today = Date().startOfDay
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        #expect(today.daysFrom(threeDaysAgo) == 3)
    }

    // MARK: - Array+Data

    @Test("Double array roundtrips through Data")
    func arrayDataRoundtrip() {
        let original = [1.0, 2.0, 3.14159, -42.0, 0.0]
        let data = original.toData()
        let restored = [Double].fromData(data)

        #expect(original.count == restored.count)
        for (a, b) in zip(original, restored) {
            #expect(abs(a - b) < 1e-10)
        }
    }

    @Test("Empty array roundtrips correctly")
    func emptyArrayRoundtrip() {
        let original: [Double] = []
        let data = original.toData()
        let restored = [Double].fromData(data)
        #expect(restored.isEmpty)
    }

    @Test("Large vector roundtrips correctly")
    func largeVectorRoundtrip() {
        let original = VectorTestHelpers.randomNormalizedVector(dimension: 512)
        let data = original.toData()
        let restored = [Double].fromData(data)

        #expect(restored.count == 512)
        for (a, b) in zip(original, restored) {
            #expect(abs(a - b) < 1e-10)
        }
    }

    // MARK: - NSAttributedString+PlainText

    @Test("Plain text extraction normalizes whitespace")
    func plainTextExtraction() {
        let attr = NSAttributedString(string: "Hello   world\n\nfoo   bar")
        let plain = attr.extractedPlainText
        #expect(plain == "Hello world foo bar")
    }
}

import SwiftUI
