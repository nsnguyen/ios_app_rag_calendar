import Foundation
@testable import Planner

enum VectorTestHelpers {
    /// A known 512-dim unit vector pointing in a single direction.
    static var unitVector: [Double] {
        var v = [Double](repeating: 0, count: 512)
        v[0] = 1.0
        return v
    }

    /// A known 512-dim vector orthogonal to unitVector.
    static var orthogonalVector: [Double] {
        var v = [Double](repeating: 0, count: 512)
        v[1] = 1.0
        return v
    }

    /// A known 512-dim vector identical to unitVector (cosine similarity = 1.0).
    static var identicalVector: [Double] {
        unitVector
    }

    /// A known 512-dim vector that is the negation of unitVector (cosine similarity = -1.0).
    static var oppositeVector: [Double] {
        unitVector.map { -$0 }
    }

    /// A random 512-dim normalized vector.
    static func randomNormalizedVector(dimension: Int = 512) -> [Double] {
        var v = (0..<dimension).map { _ in Double.random(in: -1...1) }
        let norm = sqrt(v.reduce(0) { $0 + $1 * $1 })
        guard norm > 0 else { return v }
        v = v.map { $0 / norm }
        return v
    }

    /// Creates a vector with a known similarity to unitVector.
    static func vectorWithSimilarity(_ targetSimilarity: Double) -> [Double] {
        var v = [Double](repeating: 0, count: 512)
        v[0] = targetSimilarity
        let remaining = sqrt(1.0 - targetSimilarity * targetSimilarity)
        v[1] = remaining
        return v
    }
}
