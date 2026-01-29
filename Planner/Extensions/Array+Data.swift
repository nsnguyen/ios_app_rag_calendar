import Foundation

extension Array where Element == Double {
    func toData() -> Data {
        withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }

    static func fromData(_ data: Data) -> [Double] {
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return [] }
            let count = rawBuffer.count / MemoryLayout<Double>.stride
            let buffer = baseAddress.assumingMemoryBound(to: Double.self)
            return Array(UnsafeBufferPointer(start: buffer, count: count))
        }
    }
}
